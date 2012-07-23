# ![Cucumber Roll](http://files.softicons.com/download/object-icons/richs-misc-icons-by-rich-d/png/24/Cucumber%20Roll.png) Objective-C Cucumber Wire Protocol

It allows Cucumber to touch your application in _intimate places_. Goals include and exclude:

* Implement the Cucumber wire protocol.

  This is the most direct way to connect Cucumber to non-Ruby environments.

* Not to link against the C++ standard library.

  Just pure Automatic Reference Counting (ARC) Objective-C based on Apple's Foundation framework.

Why the OC name-space prefix? OC stands for Objective-C. It emphasises the underlying dependency as well as the multiplatform capability. OCCukes supports Objective-C on all Apple platforms: iOS and OS X.

The project does _not_ include an expectation framework. It only runs Objective-C coded step definitions. Your step definitions must assert appropriate expectations, possibly by running other step definitions. Since you write your Cucumber step definitions in Objective-C, you can use any kind of assertion framework, or even write your own. Exceptions thrown by the step become Cucumber step failures. See [OCExpectations](https://github.com/OCCukes/OCExpectations) for an expectations library.

OCCukes and its companion OCExpectations sails as close to Cucumber and RSpec shores as is possible. If you are familiar with Cucumber and RSpec, you should find these projects refreshingly familiar; despite the differing implementation languages. Interfaces and implementations mirror their Ruby counterparts.

## Usage

OCCukes integrates with Xcode. You launch a Cucumber-based test suite as you would any other Xcode project test suite: just press Command+U. To set up the pre- and post-actions for your test target, just install Cucumber using RVM.

### Test scheme pre-action

Make this your pre-action for the Test scheme:

	PATH=$PATH:$HOME/.rvm/bin
	rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out "$OBJROOT/features.html"

This assumes you have already installed Cucumber in the Ruby 1.9.3 RVM; adjust according to your local environment and personal preferences.

### Test scheme post-action

Then make this your post-action:

	open "$OBJROOT/features.html"

### Wire protocol configuration

Add a wire configuration to your `features/step_definitions` folder, a YAML file with a `.wire` extension. Contents as follows.

	host: localhost
	port: 54321

	# The default three-second time-out might not help a debugging
	# effort. Instead, lengthen the timeouts for specific wire protocol
	# messages.
	timeout:
	  step_matches: 120

Host and port describe where to find the wire socket service. The Cucumber wire service accepts connections at port 54321 on _any_ interface. So you can connect to non-local hosts as well.

### Environment Support

Set up your `features/support/env.rb`; contents as follows. The Ruby code below defines a Cucumber `AfterConfiguration` block for daemonising the Cucumber process and waiting for the wire server to begin accepting socket connections. This block runs after Cucumber configuration. You can copy this code from [`features/support/env.rb`](https://github.com/royratcliffe/OCCukes/blob/master/features/support/env.rb).

```ruby
AfterConfiguration do |config|
  # First, daemonise this Cucumber process. This assumes that Xcode
  # launches Cucumber as a pre-action for the test scheme. If you use
  # RVM, the pre-action script might look something like this:
  #
  #   PATH=$PATH:$HOME/.rvm/bin
  #   rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out "$OBJROOT/features.html"
  #
  Process.daemon(true, true)

  # Navigate to the wire language configuration. Cucumber supports
  # multiple languages, even during the same run. The wire language is
  # just one of many. No straightforward way exists for accessing the
  # current language, or even the current runtime from within Cucumber
  # at this point during the AfterConfiguration block. Instead
  # therefore, replicate Cucumber's way of finding and loading the
  # wire configuration.
  wire_files = config.feature_dirs.map do |path|
    path = path.gsub(/\/$/, '')
    File.directory?(path) ? Dir["#{path}/**/*"] : path
  end.flatten.uniq
  wire_files.reject! { |f| !File.file?(f) }
  wire_files.reject! { |f| File.extname(f) != '.wire' }
  params = YAML.load(ERB.new(File.read(wire_files[0])).result)

  # Finally, wait for the wire socket to open. Try a connection once a
  # second for ten seconds. Continue when the connection does not
  # refuse. This adds a short latency: the distance in time between
  # the wire server accepting connections and the socket probe finding
  # a non-refusal. The latency is always less than one second.
  #
  # No need to send an exit message. The wire server automatically exits
  # when all the connections close.
  Timeout.timeout(10) do
    loop do
      begin
        TCPSocket.open(params['host'], params['port']).close
        break
      rescue Errno::ECONNREFUSED
        sleep 1
      end
    end
  end
end
```

### Add test case

Finally, integrate Cucumber tests with your standard unit test cases by adding a special `SenTestCase` sub-class.

Header file for test case, `CucumberTests.h`:
```objc
#import <SenTestingKit/SenTestingKit.h>

@interface CucumberTests : SenTestCase

@end
```

Source file for test case, `CucumberTests.m`:
```objective-c
#import "CucumberTests.h"

#import <OCCukes/OCCukes.h>

@implementation CucumberTests

- (void)setUp
{
	[OCCucumber given:@"^context$" step:^(NSArray *arguments) {
		// express the regular expression above with the code you wish you had
		[OCCucumber pending:@"TODO"];
	} file:__FILE__ line:__LINE__];
	
	[OCCucumber when:@"^event$" step:^(NSArray *arguments) {
		// express the regular expression above with the code you wish you had
		[OCCucumber pending:@"TODO"];
	} file:__FILE__ line:__LINE__];
	
	[OCCucumber then:@"^outcome$" step:^(NSArray *arguments) {
		// express the regular expression above with the code you wish you had
		[OCCucumber pending:@"TODO"];
	} file:__FILE__ line:__LINE__];
	
	[[OCCucumberRuntime sharedRuntime] setUp];
}

- (void)tearDown
{
	[[OCCucumberRuntime sharedRuntime] tearDown];
}

- (void)testCucumber
{
	[[OCCucumberRuntime sharedRuntime] run];
}

@end
```

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

### Sponsors

- Levide Capital Limited, Blenheim, New Zealand

### Contributors

- Roy Ratcliffe, Pioneering Software, United Kingdom
- Bennett Smith, Focal Shift LLC, United States
- Terry Tucker, Focal Shift LLC, United States
