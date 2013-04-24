// OCCukes OCCucumberSenTestProbe.m
//
// Copyright © 2012, 2013, The OCCukes Organisation. All rights reserved.
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

#import "OCCucumberSenTestProbe.h"
#import "OCCucumberRuntime.h"

#import <objc/runtime.h>

@interface OCCucumberSenTestProbe()

+ (void)exit;

@end

static id RunTests(id self, SEL _cmd, ...)
{
	@autoreleasepool {
		[[NSBundle allFrameworks] makeObjectsPerformSelector:@selector(principalClass)];
		NSClassFromString(@"SenTestObserver");
		[[self performSelector:@selector(specifiedTestSuite)] performSelector:@selector(run)];

		// Various routes exist for launching tests. If outside an application
		// bundle, tests launch directly by sending +runTests:ignored to
		// SenTestProbe. There is no run loop. However, if within an application
		// test host, the same message executes but from within the
		// application's run loop. The Cucumber wire server always requires a
		// run-loop. If a run-loop is not already running therefore, OCCukes
		// needs to start one. It also needs to stop the run-loop when tests and
		// Cucumber feature testing completes.
		//
		// Send +isLoadedFromApplication to the SenTestProbe class. It answers
		// YES if the test suite loads from an application. If this is the case,
		// execute the Cucumber wire server in parallel with the application, by
		// utilising the application's run loop. Catch the connection and
		// disconnection notifications. Disconnection starts a delayed exit;
		// delayed by the remaining disconnect timeout interval. Connections
		// cancel any previous delayed exits.
		//
		// You can override the Cucumber runtime connect and disconnect timeouts
		// at the command line. For example, use
		//
		//	defaults write org.OCCukes OCCucumberRuntimeDisconnectTimeout -float 120.0
		//
		// to reconfigure the disconnect timeout to two minutes. Express
		// timeouts in units of seconds. Display the current configuration using
		//
		//	defaults read org.OCCukes
		//
		OCCucumberRuntime *runtime = [OCCucumberRuntime sharedRuntime];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addSuiteNamed:@"org.OCCukes"];
		NSTimeInterval connectTimeout = [defaults doubleForKey:@"OCCucumberRuntimeConnectTimeout"];
		NSTimeInterval disconnectTimeout = [defaults doubleForKey:@"OCCucumberRuntimeDisconnectTimeout"];
		if (connectTimeout > DBL_EPSILON)
		{
			[runtime setConnectTimeout:connectTimeout];
		}
		if (disconnectTimeout > DBL_EPSILON)
		{
			[runtime setDisconnectTimeout:disconnectTimeout];
		}
		[runtime setUp];
		if ([self performSelector:@selector(isLoadedFromApplication)])
		{
			NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
			[center addObserverForName:OCCucumberRuntimeDisconnectNotification
								object:nil
								 queue:nil
							usingBlock:^(NSNotification *note) {
								OCCucumberRuntime *runtime = [note object];
								if ([[runtime allConnections] count] == 0)
								{
									[OCCucumberSenTestProbe performSelector:@selector(exit)
																 withObject:nil
																 afterDelay:[[runtime expiresDate] timeIntervalSinceNow]];
								}
							}];
			[center addObserverForName:OCCucumberRuntimeConnectNotification
								object:nil
								 queue:nil
							usingBlock:^(NSNotification *note) {
								OCCucumberRuntime *runtime = [note object];
								if ([[runtime allConnections] count])
								{
									[NSObject cancelPreviousPerformRequestsWithTarget:[OCCucumberSenTestProbe class]
																			 selector:@selector(exit)
																			   object:nil];
								}
							}];
		}
		else
		{
			[runtime run];
			[runtime tearDown];
		}
	}
	return nil;
}

@implementation OCCucumberSenTestProbe

+ (void)load
{
	Class senTestProbeClass = NSClassFromString(@"SenTestProbe");
	if (senTestProbeClass)
	{
		Method runTestsClassMethod = class_getClassMethod(senTestProbeClass, @selector(runTests:));
		method_setImplementation(runTestsClassMethod, RunTests);
	}
}

+ (void)exit
{
	Class senTestProbeClass = NSClassFromString(@"SenTestProbe");
	if (senTestProbeClass)
	{
		id senTestSuite = [senTestProbeClass performSelector:@selector(specifiedTestSuite)];
		id senTestSuiteRun = [senTestSuite performSelector:@selector(run)];
		BOOL hasFailed = [senTestSuiteRun performSelector:@selector(hasSucceeded)] == nil;
		exit(hasFailed);
	}
}

@end
