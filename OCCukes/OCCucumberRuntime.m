// OCCukes OCCucumberRuntime.m
//
// Copyright © 2012, The OCCukes Organisation. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "OCCucumberRuntime.h"
#import "OCCucumberRuntime+WireProtocol.h"
#import "OCCucumberLanguage.h"

@interface OCCucumberRuntime()

// The wire socket accepts connections on a prescribed host and port, typically
// local host, port 54321. Wire pairs represent a set of Core Foundation stream
// pairs for individual connections to remote wire clients, typically Ruby
// interpreters running Cucumber. Wire pairs appear when the wire socket accepts
// a new connection and disappear when the remote Cucumber client closes the
// connection.
@property(strong, NS_NONATOMIC_IOSONLY) CFSocket *wireSocket;
@property(strong, NS_NONATOMIC_IOSONLY) NSMutableSet *wirePairs;

@end

@implementation OCCucumberRuntime

@synthesize language = _language;
@synthesize connectTimeout = _connectTimeout;
@synthesize disconnectTimeout = _disconnectTimeout;

@synthesize expiresDate = _expiresDate;

@synthesize wireSocket = _wireSocket;
@synthesize wirePairs = _wirePairs;

- (void)setLanguage:(OCCucumberLanguage *)language
{
	_language = language;
}

- (OCCucumberLanguage *)language
{
	// You can override the runtime instance's language. By default, if language
	// equals nil, the runtime picks up the shared language.
	return _language ? _language : [OCCucumberLanguage sharedLanguage];
}

- (NSSet *)allConnections
{
	return [[self wirePairs] copy];
}

- (id)init
{
	if ((self = [super init]))
	{
		[self setConnectTimeout:10.0];
		[self setDisconnectTimeout:1.0];
	}
	return self;
}

- (void)setUp
{
	CFSocket *socket = [[CFSocket alloc] initForTCPv6];
	[socket setDelegate:self];
	[socket setReuseAddressOption:YES];
	[socket setAddress:CFSocketAddressDataFromAnyIPv6WithPort(54321) error:NULL];
	[socket addToCurrentRunLoopForCommonModes];
	[self setWireSocket:socket];
	[self setWirePairs:[NSMutableSet set]];
	[self setExpiresDate:[NSDate dateWithTimeIntervalSinceNow:[self connectTimeout]]];
}

- (void)tearDown
{
	// Removing all connections automatically closes the connections because the
	// request-response stream pair closes on deallocation. Therefore, no need
	// to explicitly close every pair, as follows. Releasing the socket shuts
	// down the socket. Releasing the pair set releases and shuts down all the
	// wire connections.
	//
	//	for (CFStreamPair *wirePair in [self wirePairs])
	//	{
	//		[wirePair close];
	//	}
	//
	[self setWireSocket:nil];
	[self setWirePairs:nil];
	[self setExpiresDate:nil];
}

- (void)run
{
	do
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	}
	while ([self isRunning]);
}

- (BOOL)isRunning
{
	NSDate *expiresDate = [self expiresDate];
	return expiresDate && [expiresDate compare:[NSDate date]] == NSOrderedDescending;
}

- (void)socket:(CFSocket *)socket acceptStreamPair:(CFStreamPair *)streamPair
{
	// Accepts new connections. Attaches a stream-pair to each incoming
	// connection. Retains, delegates and opens the new wire pair.
	// The wire server opens one "wire" for each connection, each Cucumber
	// client. The wire connection's stream-pair encapsulates client-server
	// interactions. It decodes wire packets from the request stream and encodes
	// wire packets to the response stream.
	if ([[self wirePairs] count] == 0)
	{
		[self setExpiresDate:[NSDate distantFuture]];
	}
	[[self wirePairs] addObject:streamPair];
	[streamPair setDelegate:self];
	[streamPair open];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:streamPair forKey:OCCucumberRuntimeWirePairKey];
	NSNotification *notification = [NSNotification notificationWithName:OCCucumberRuntimeConnectNotification object:self userInfo:userInfo];
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
}

- (void)streamPair:(CFStreamPair *)streamPair hasBytesAvailable:(NSUInteger)bytesAvailable
{
	// The wire protocol begins by quantising the request messages by line
	// terminator. One line equates to one message, or wire packet. The request
	// is a JSON array. The first element specifies the message, one of:
	// step_matches, invoke, begin_scenario, end_scenario, or snippet_text. The
	// second array element specifies the parameters, a hash or array depending
	// on the message. Demultiplex the JSON request and invoke the corresponding
	// handler.
	NSString *line = [streamPair receiveLineUsingEncoding:NSUTF8StringEncoding];
	if (line)
	{
		NSError *__autoreleasing error = nil;
		id object = [NSJSONSerialization JSONObjectWithData:[line dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
		if (object)
		{
			id result = [self handleWirePacketWithObject:object];
			// Always answer with something whenever the request decodes valid
			// JSON. Send valid JSON back because at the other end of the
			// connection likely sits a Cucumber instance. Send a Cucumber
			// wire-protocol failure packet.
			if (result == nil)
			{
				result = [NSArray arrayWithObject:@"fail"];
			}
			NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:&error];
			if (data)
			{
				[streamPair sendBytes:data];
				[streamPair sendBytes:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
			}
		}
	}
}

- (void)streamPair:(CFStreamPair *)streamPair handleRequestEvent:(NSStreamEvent)eventCode
{
	switch (eventCode)
	{
		case NSStreamEventEndEncountered:
		{
			// Enqueue the disconnect notification. It does not post
			// immediately. By the time the notification arrives at its
			// destination, or destinations, the stream pair no longer appears
			// as a wire pair; and if it was the very last wire pair, the
			// expires date reflects the disconnect timeout since now.
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:streamPair forKey:OCCucumberRuntimeWirePairKey];
			NSNotification *notification = [NSNotification notificationWithName:OCCucumberRuntimeDisconnectNotification object:self userInfo:userInfo];
			[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
			[[self wirePairs] removeObject:streamPair];
			if ([[self wirePairs] count] == 0)
			{
				[self setExpiresDate:[NSDate dateWithTimeIntervalSinceNow:[self disconnectTimeout]]];
			}
			break;
		}
		default:
			;
	}
}

+ (OCCucumberRuntime *)sharedRuntime
{
	static OCCucumberRuntime *__strong sharedRuntime;
	if (sharedRuntime == nil)
	{
		sharedRuntime = [[OCCucumberRuntime alloc] init];
	}
	return sharedRuntime;
}

@end

NSString *const OCCucumberRuntimeConnectNotification = @"OCCucumberRuntimeConnect";
NSString *const OCCucumberRuntimeDisconnectNotification = @"OCCucumberRuntimeDisconnect";
NSString *const OCCucumberRuntimeWirePairKey = @"OCCucumberRuntimeWirePair";
