# [![Cucumber Roll](http://files.softicons.com/download/object-icons/richs-misc-icons-by-rich-d/png/24/Cucumber%20Roll.png)](https://github.com/OCCukes/OCCukes) Objective-C Cucumber Wire Protocol

[![Build Status](https://travis-ci.org/royratcliffe/OCCukes.png?branch=master)](https://travis-ci.org/royratcliffe/OCCukes)

It allows Cucumber to touch your application in _intimate places_ (to quote Cucumber's [wire protocol feature description][wire-protocol]). Goals
include and exclude:

[wire-protocol]:https://github.com/cucumber/cucumber/blob/master/legacy_features/wire_protocol_erb.feature

* Implement the Cucumber wire protocol.

  This is the most direct way to connect Cucumber to non-Ruby environments.

* Not to link against the C++ standard library.

  Just pure Automatic Reference Counting (ARC) Objective-C based on Apple's
  Foundation framework.

Why the OC name-space prefix? OC stands for Objective-C. It emphasises the
underlying dependency as well as the multiplatform capability. OCCukes supports
Objective-C on all Apple platforms: iOS and OS X.

The project does _not_ include an expectation framework. It only runs
Objective-C coded step definitions. Your step definitions must assert
appropriate expectations, possibly by running _other_ step definitions. Since
you write your Cucumber step definitions in Objective-C, you can use any kind
of assertion framework, or even write your own. Exceptions thrown by the step
become Cucumber step failures. See
[OCExpectations](https://github.com/OCCukes/OCExpectations) for an expectations
library.

OCCukes and its companion OCExpectations sails as close to Cucumber and RSpec
shores as is possible. If you are familiar with Cucumber and RSpec, you should
find these projects refreshingly familiar; despite the differing implementation
languages. Interfaces and implementations mirror their Ruby counterparts.

To use OCCukes, you need Xcode 4.4 or above, Ruby as well as Apple's Command
Line Tools package. Install them on your Mac first. See
[Prerequisites](https://github.com/OCCukes/OCCukes/wiki/Prerequisites) for
details.

## Usage

OCCukes integrates with Xcode. You launch a Cucumber-based test suite along with any other Xcode project test suite: just press Command+U. Cucumber piggy-backs on the standard SenTestKit (OCUnit) tests.

To make this work, you need to launch Cucumber in the background while your test suite runs. Xcode's pre-actions let you do this. To set up the pre- and post-actions for your test target, just install Cucumber using RVM.

### Test scheme pre-action

Make this your pre-action for the Test scheme:

	PATH=$PATH:$HOME/.rvm/bin
	rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out "$OBJROOT/features.html"

It sets up the PATH variable so that the shell can find RVM; Xcode resets the
PATH when shelling out. It then launches Cucumber using RVM with Ruby 1.9.3;
this looks for the latest 1.9.3-version of Ruby installed, but quietly fails if
the latest version is __not__ installed. Success assumes you have already
installed Cucumber in the Ruby 1.9.3 RVM; adjust according to your local
environment and personal preferences. Use `gem install cucumber dnssd` within
the selected Ruby version to install Cucumber and its dependencies.

### Test scheme post-action

Then make this your post-action:

	open "$OBJROOT/features.html"

### Wire protocol configuration

Add a wire configuration to your `features/step_definitions` folder, a YAML file with a `.wire` extension. Contents as follows.

	host: _occukes-runtime._tcp.

	# The default three-second time-out might not help a debugging
	# effort. Instead, lengthen the timeouts for specific wire protocol
	# messages.
	timeout:
	  step_matches: 120

Host and port describe where to find the wire socket service. If you want to use Bonjour (DNS Service Discovery, DNSSD) to resolve the host address and the port number, specify a DNS service name as the host. This triggers Bonjour discovery. The Cucumber wire service accepts connections at port 54321 on _any_ interface. So you can connect to non-local hosts as well.

You can override the Cucumber runtime connect and disconnect timeouts
at the command line. For example, use

	defaults write org.OCCukes OCCucumberRuntimeDisconnectTimeout -float 120.0

to reconfigure the disconnect timeout to two minutes. Express
timeouts in units of seconds. Display the current configuration using

	defaults read org.OCCukes

### Environment Support

Set up your `features/support/env.rb`. You can copy this code from [`features/support/env.rb`](https://github.com/OCCukes/OCCukes/blob/master/features/support/env.rb). The Ruby code defines a Cucumber `AfterConfiguration` block for daemonising the Cucumber process and waiting for the wire server to begin accepting socket connections. This block runs after Cucumber configuration.

### Add test case

Finally, integrate Cucumber tests with your standard unit test cases by adding steps.

Basic template for some step definitions, `MySteps.m`:
```objc
#import <OCCukes/OCCukes.h>

__attribute__((constructor))
static void StepDefinitions()
{
	
}
```

Make as many such step definition modules as required. Organise the steps around related features.

Register your step definitions before executing the Objective-C Cucumber runtime by sending `-run`. As you see above, definitions manifest themselves in Objective-C as C blocks. These blocks assert the step's expectations, throwing an exception if any expectations fail. Steps therefore succeed when they encounter no exceptions.

The runtime accepts connections until all connections disappear. By default, it offers an initial 10-second connection window; giving up if Cucumber fails to connect for 10 seconds. The runtime also offers a 1-second disconnection window before shutting down the socket. This allows all connections to disappear temporarily. You can adjust these connect and disconnect timeouts if necessary.

Link your test target against the `OCCukes.framework` for OS X platforms; or against the `libOCCukes.a` static library for iOS test targets. For iOS targets, you also need `OTHER_LDFLAGS` equal to `-all_load`; the linker does not automatically load Objective-C categories when they appear in a static library but this flag forces it to.

## Advantages

Why use OCCukes?

### Test bundle injection

Takes advantage of Apple's test bundle injection mechanism. In other words, you do not need to link your target against some other library. Your target needs nothing extra. This obviates any need for maintaining multiple targets, one for the application proper, then another one for Cucumber testing. Xcode takes care of the injection of the wire protocol server along with all other tests and dependencies at testing time.

This prevents a proliferation of targets, making project maintenance easier. You do not need to have a Cucumber'ified target which duplicates your target proper but adds additional dependencies. Bundle injection handles all that for you. One application, one target.

### No additional Ruby

The OCCukes approach obviates any additional Ruby-side client gem needed for bridging work between Cucumber and iOS or OS X. Cucumber is the direct client end-point. It already contains the necessary equipment for talking to OCCukes. No need for another adapter. OCCukes talks _native_ Cucumber.

This also means that you do not need to build and maintain a skeletal structure within your features just for adapting and connecting to a remote test system. Cuts out the [cruft](http://foldoc.org/cruft).

### No private dependencies

The software only makes use of public APIs. This makes it far less brittle. Private frameworks can and do change without notice. Projects relying on them can easily become redundant especially as Apple's operating systems advance rapidly.

### Multiple subprojects

The OCCukes organisation publishes [various Cucumber-related subprojects](https://github.com/OCCukes/OCCukes/wiki/Repos). Although the OCCukes project lies at the core, complementary projects OCExpectations and a slew of iOS-specific spinoffs exist: UICukes, UIExpectations and UIAutomation. The structure helps to avoid an all-or-nothing mindset. Take whatever best suits your needs. The projects aim at various kinds of development projects: iOS application, Mac application, iOS library, or Mac framework.

OCCukes sub-projects prefixed by `OC` have Objective-C and Foundation framework dependencies. That means they work on iOS _and_ OS X platforms. They are cross-platform projects and incorporate iOS library targets as well as OS X framework targets.

Projects prefixed by `UI` have iOS UIKit dependencies. They aim at iOS projects only. Their Xcode projects contain a single iOS static library target. [UICukes](https://github.com/OCCukes/UICukes) acts as an umbrella project for iOS dependencies. It pulls in all other sub-projects needed for Cucumber on iOS. iOS developers will therefore normally clone out the UICukes submodule by itself. Doing so pulls in all other dependencies as sub-submodules.

## Troubleshooting

### Cucumber launches but invokes no steps

You press Cmd+U in Xcode to run your tests. There is a brief pause then you see the Cucumber output. Cucumber has executed and parsed the features and scenarios. Trouble is, Cucumber stops at the first scenario's first step. No steps execute. When you set a breakpoint within your step definitions, sure enough, they never run.

#### Solution

Make sure that you are not running a Cucumber instance in some other process. For example, you might be running it as part of an IDE for some other project, or some other components of the same project. Terminate the other Cucumbers and re-test.

## When and how to launch Cucumber?

Running Cucumber with Mac or iOS software requires two synchronised processes: a Cucumber client in Ruby, and an Objective-C wire server running within an application test bundle. The server needs to run first in order to open a wire server socket. The socket may be local or on another device. Actual iOS devices do not share the same local host. Hence the Cucumber client cannot assume `localhost`.

Wire server and client need to synchronise their execution. When Cucumber runs, it expects to connect to the wire server when it finds a wire configuration. Hence the Test scheme needs to launch the server beforehand. Best way to launch Cucumber from Xcode: use a pre-action within the Test scheme. Cucumber therefore needs to do three things at launch time:

1. fork itself into the background so that Xcode testing can proceed, that is, daemonise;
2. wait for the wire server to set itself up;
3. close down the wire server when Cucumber finishes running its features and invoking the remote-wire step definitions. This can happen automatically when it server sees no wire connection after a given period of time, say a second.

Step 2 raises issues when Cucumber tests actual iOS devices where the server does not open a port on `localhost`. Waiting for the wire server to initialise (step 2) requires that the Cucumber run-time environment establishes the wire server's address and port information. Without it, the Cucumber run will fail. The environment needs to wait an acceptable time for the server to appear on the prescribed port. Moreover, the client-side environment needs to attempt and reattempt to connect. The initial attempts will likely fail with a "refuse to connect" exception, simply because the server has not yet opened the socket. Steps 2 and 3 together imply a setting up and tearing down at the Cucumber client side.

## MIT Licensing

Copyright © 2012, The OCCukes Organisation. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

## Sponsors

- Levide Capital Limited, Blenheim, New Zealand

## Contributors

- Roy Ratcliffe, Pioneering Software, United Kingdom
- Bennett Smith, Focal Shift LLC, United States
- Terry Tucker, Focal Shift LLC, United States
