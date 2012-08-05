// OCCukes OCCucumberRuntime.h
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

#import <Foundation/Foundation.h>

#import <CFSockets/CFSockets.h>

@class OCCucumberLanguage;

/*!
 * @brief Ties everything together, the meaty part.
 */
@interface OCCucumberRuntime : NSObject<CFSocketDelegate, CFStreamPairDelegate>

@property(strong, NS_NONATOMIC_IOSONLY) OCCucumberLanguage *language;
@property(assign, NS_NONATOMIC_IOSONLY) NSTimeInterval connectTimeout;
@property(assign, NS_NONATOMIC_IOSONLY) NSTimeInterval disconnectTimeout;

/*!
 * @brief Date when the runtime expires.
 * @details Expiring date describes when the runtime should stop running. While
 * connections exist, the runtime never expires, or expires in the distant
 * future to be more precise. The runtime expires after the disconnect timeout
 * after all connections disconnect. It also expires after the connect timeout
 * after setting up the runtime.
 */
@property(strong, NS_NONATOMIC_IOSONLY) NSDate *expiresDate;

/*!
 * @brief Answers all the current connections as a set.
 * @details Connections change dynamically as remote Cucumber clients connect to
 * and disconnect from the wire server.
 */
- (NSSet *)allConnections;

- (void)setUp;
- (void)tearDown;

/*!
 * @brief Cucumber runtime runs, naturally.
 * @details When running the wire server, there are two timing
 * requirements. First, wait at least for a nominal 10 seconds before giving up
 * on taking a connection. Call this the "connect timeout" period; it defines
 * the maximum delay in-between setting up the server and making the first
 * wire-client connection. There must be at least one incoming Cucumber
 * connection to disable this timeout. When a connection activates, the timeout
 * becomes infinite. Provided at least one connection remains, the server
 * continues running indefinitely. When the last connection closes, the wire
 * server sustains the server socket for one more second before exiting. This
 * allows for execution of Cucumber commands over multiple socket connections in
 * rapid sequence. Call this the disconnect timeout. You can adjust the connect
 * and disconnect timeouts accordingly.
 */
- (void)run;

/*!
 * @brief Answers YES if the runtime wants to continue running.
 * @details The runtime continues running while connections exist, or the
 * current time lies within connection and disconnection timeout
 * periods. Outside these conditions, the runtime will continue to accept new
 * connections if you ignore the running status. In such event, the is-running
 * status will revert to YES when incoming new connections establish.
 */
- (BOOL)isRunning;

+ (OCCucumberRuntime *)sharedRuntime;

@end

extern NSString *const OCCucumberRuntimeConnectNotification;
extern NSString *const OCCucumberRuntimeDisconnectNotification;
extern NSString *const OCCucumberRuntimeStreamPairKey;
