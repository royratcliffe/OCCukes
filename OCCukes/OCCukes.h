// OCCukes OCCukes.h
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

#import <OCCukes/OCCucumber.h>
#import <OCCukes/OCCucumberRuntime.h>
#import <OCCukes/OCCucumberLanguage.h>
#import <OCCukes/OCCucumberWorld.h>
#import <OCCukes/OCCucumberStepDefinition.h>
#import <OCCukes/OCCucumberExceptions.h>
#import <OCCukes/Versioning.h>

/*!
 * @mainpage OCCukes
 *
 * OCCukes allows Cucumber to touch your application in _intimate places_. Goals
 * include and exclude:
 *
 * * Implement the Cucumber wire protocol.
 *
 *   This is the most direct way to connect Cucumber to non-Ruby environments.
 *
 * * Not to link against the C++ standard library.
 *
 *   Just pure Automatic Reference Counting (ARC) Objective-C based on Apple's
 *   Foundation framework.
 *
 * Why the OC name-space prefix? OC stands for Objective-C. It emphasises the
 * underlying dependency as well as the multiplatform capability. OCCukes
 * supports Objective-C on all Apple platforms: iOS and OS X.
 *
 * The project does _not_ include an expectation framework. It only runs
 * Objective-C coded step definitions. Your step definitions must assert
 * appropriate expectations, possibly by running other step definitions. Since
 * you write your Cucumber step definitions in Objective-C, you can use any kind
 * of assertion framework, or even write your own. Exceptions thrown by the step
 * become Cucumber step failures. See
 * [OCExpectations](https://github.com/OCCukes/OCExpectations) for an
 * expectations library.
 *
 * OCCukes and its companion OCExpectations sails as close to Cucumber and RSpec
 * shores as is possible. If you are familiar with Cucumber and RSpec, you
 * should find these projects refreshingly familiar; despite the differing
 * implementation languages. Interfaces and implementations mirror their Ruby
 * counterparts.
 *
 * To use OCCukes, you need Xcode 4.4 or above, Ruby as well as Apple's Command
 * Line Tools package. Install them on your Mac first. See
 * [Prerequisites](https://github.com/OCCukes/OCCukes/wiki/Prerequisites) for
 * details.
 *
 * @section usage Usage
 *
 * OCCukes integrates with Xcode. You launch a Cucumber-based test suite as you
 * would any other Xcode project test suite: just press Command+U. To set up the
 * pre- and post-actions for your test target, just install Cucumber using RVM.
 *
 * @subsection test_scheme_pre_action Test scheme pre-action
 *
 * Make this your pre-action for the Test scheme:
 *
 * @code
 *	PATH=$PATH:$HOME/.rvm/bin
 *	rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out "$OBJROOT/features.html"
 * @endcode
 *
 * This assumes you have already installed Cucumber in the Ruby 1.9.3 RVM;
 * adjust according to your local environment and personal preferences.
 *
 * @subsection test_scheme_post_action Test scheme post-action
 *
 * Then make this your post-action:
 *
 * @code
 *	open "$OBJROOT/features.html"
 * @endcode
 *
 * @subsection wire_protocol_configuration Wire protocol configuration
 *
 * Add a wire configuration to your `features/step_definitions` folder, a YAML
 * file with a `.wire` extension. Contents as follows.
 *
 * @code
 *	host: localhost
 *	port: 54321
 *
 *	# The default three-second time-out might not help a debugging
 *	# effort. Instead, lengthen the timeouts for specific wire protocol
 *	# messages.
 *	timeout:
 *	  step_matches: 120
 * @endcode
 *
 * Host and port describe where to find the wire socket service. The Cucumber
 * wire service accepts connections at port 54321 on _any_ interface. So you can
 * connect to non-local hosts as well.
 *
 * @subsection environment_support Environment Support
 *
 * Set up your <code>features/support/env.rb</code>; contents as follows. The
 * Ruby code below defines a Cucumber `AfterConfiguration` block for daemonising
 * the Cucumber process and waiting for the wire server to begin accepting
 * socket connections. This block runs after Cucumber configuration. You can
 * copy this code from
 * [features/support/env.rb](https://github.com/OCCukes/OCCukes/blob/master/features/support/env.rb).
 *
 * @code
 * require 'cucumber/wire_support/configuration'
 *
 * begin
 *   require 'dnssd'
 * rescue LoadError
 * end
 *
 * require 'timeout'
 *
 * # Extends Cucumber's wire support configuration class.
 * #
 * # Replaces the #initialize, #host and #port methods. The new method
 * # implementations allow for DNS service discovery, or synchronisation
 * # when using explicit host address and port number.  The configuration
 * # will pick up the address and port number obtained via Bonjour or
 * # pick up the defaults instead. Hence, the wire configuration does not
 * # require a host or port value. If the host specifies a service type
 * # of the form "_service-type._tcp." then the replacement initialiser
 * # attempts a service discovery using DNS-SD.
 * module Cucumber
 *   module WireSupport
 *     class Configuration
 *       alias_method :original_initialize, :initialize
 *       alias_method :original_host, :host
 *       alias_method :original_port, :port
 *
 *       # Cucumber supports multiple languages, even during the same
 *       # run. The wire language is just one of many.
 *       def initialize(wire_file)
 *         original_initialize(wire_file)
 *         if net_service_discovery?
 *           discover_net_service
 *         else
 *           sync
 *         end
 *       end
 *
 *       def host
 *         @net_service_host || original_host || 'localhost'
 *       end
 *
 *       def port
 *         @net_service_port || original_port || 54321
 *       end
 *
 *       # Answers non-nil if the host configuration conforms to DNS
 *       # Service Discovery type expectations. Answers nil if not.
 *       def net_service_discovery?
 *         original_host =~ /_[-a-z0-9]+._[-a-z0-9]+./
 *       end
 *
 *       # If Ruby can find the "dnssd" gem, try to resolve the host and
 *       # port dynamically using DNS-SD, DNS-based service discovery,
 *       # also known as Bonjour. If discovery succeeds, no need to probe
 *       # for the open socket. Instead, assume the open socket
 *       # exists. Otherwise why would the server publish the service?
 *       # Allow thirty seconds for service discovery to browse and
 *       # resolve the service, and then look up the address
 *       # information. The underlying Ruby socket implementation wants
 *       # an IP address, a string in dotted decimal.
 *       def discover_net_service
 *         begin
 *           Timeout::timeout(30) do
 *             DNSSD.browse!(original_host || '_occukes-runtime._tcp.') do |browse|
 *               DNSSD.resolve!(browse) do |resolve|
 *                 DNSSD::Service.new.getaddrinfo(resolve.target) do |addr_info|
 *                   @net_service_host, @net_service_port = addr_info.address, resolve.port
 *                   STDERR.puts "Cucumber wire connecting to #{resolve.name}, address #{@net_service_host}, port #{@net_service_port}"
 *                   raise Timeout::Error
 *                 end
 *               end
 *             end
 *           end
 *         rescue Timeout::Error
 *         end
 *       end
 *
 *       # Wait for the wire socket to open. Try a connection once a
 *       # second for thirty seconds. Give Xcode thirty seconds to set up
 *       # the test host. This could involve launching the iOS
 *       # simulator. So it might take a little while at first. Continue
 *       # when the connection does not refuse. This adds a short
 *       # latency: the distance in time between the wire server
 *       # accepting connections and the socket probe finding a
 *       # non-refusal. The latency is always less than one second.
 *       #
 *       # No need to send an exit message. The wire server automatically
 *       # exits when all the connections close.
 *       def sync
 *         Timeout::timeout(30) do
 *           loop do
 *             begin
 *               TCPSocket.open(original_host, original_port).close
 *               break
 *             rescue Errno::ECONNREFUSED
 *               sleep 1
 *             end
 *           end
 *         end
 *       end
 *     end
 *   end
 * end
 *
 * # Daemonise this Cucumber process. This assumes that Xcode launches
 * # Cucumber as a pre-action for the test scheme. If you use RVM, the
 * # pre-action script might look something like this:
 * #
 * #   PATH=$PATH:$HOME/.rvm/bin
 * #   rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out "$OBJROOT/features.html"
 * #
 * # Please be aware: from this point forward, the Cucumber process forks
 * # away from the parent process and becomes a background process. The
 * # parent process, Xcode, continues. However, the fork interferes if
 * # you want to debug the Cucumber client. Breakpoints will never break
 * # if set beyond the fork.
 * #
 * # Therefore, work out if the current process runs from Xcode or
 * # not. Only fork if it does. Avoid the fork if running
 * # independently. This helps when debugging. Use XCODE_VERSION_ACTUAL
 * # to determine if launching from Xcode. Xcode sets up that environment
 * # variable, assuming you provide build settings from your test
 * # target. For Xcode 4.4, the actual version equals 0440. Actual value
 * # does not matter; only presence matters.
 * Process.daemon(true, true) if ENV['XCODE_VERSION_ACTUAL']
 * @endcode
 */
