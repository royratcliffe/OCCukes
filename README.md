# Objective-C Cucumber Wire Protocol

It allows Cucumber to touch your application in _intimate places_. Goals include and exclude:

* Implement the Cucumber wire protocol.

  This is the most direct way to connect Cucumber to non-Ruby environments.

* Not to link against the C++ standard library.

  Just pure Objective-C based on Apple's Foundation framework.

Why the OC name-space prefix? OC stands for Objective-C. It emphasises the underlying dependency as well as the multiplatform capability. OCCukes supports Objective-C on all Apple platforms: iOS and OS X.

The project does _not_ include an expectation framework. It only runs Objective-C step definitions. Your step definitions must assert appropriate expectations, possibly by running other step definitions.

## Advantages

Why use OCCukes?

### Test bundle injection

Takes advantage of Apple's test bundle injection mechanism. In other words, you do not need to link your target against some other library. Your target needs nothing extra. This obviates any need for maintaining multiple targets, one for the application proper, then another one for Cucumber testing. Xcode takes care of the injection of the wire protocol server along with all other tests and dependencies at testing time.

This prevents a proliferation of targets, making project maintenance easier. You do not need to have a Cucumber'ified target which duplicates your target proper but adds additional dependencies. Bundle injection handles all that for you. One application, one target.

### No additional Ruby

The OCCukes approach obviates any additional Ruby-side client gem needed for bridging work between Cucumber and iOS or OS X. Cucumber is the direct client end-point. It already contains the necessary equipment for talking to OCCukes. No need for another adapter. OCCukes talks _native_ Cucumber.

This also means that you do not need to build and maintain a skeletal structure within your features just for adapting and connecting to a remote test system. Cuts out the [cruft](http://foldoc.org/cruft).

## When and how to launch Cucumber?

Running Cucumber with Mac or iOS software requires two synchronised processes: a Cucumber client in Ruby, and an Objective-C wire server running within an application test bundle. The server needs to run first in order to open a wire server socket. The socket may be local or on another device. Actual iOS devices do not share the same local host. Hence the Cucumber client cannot assume `localhost`.

Wire server and client need to synchronise their execution. When Cucumber runs, it expects to connect to the wire server when it finds a wire configuration. Hence the Test scheme needs to launch the server beforehand. Best way to launch Cucumber from Xcode: use a pre-action within the Test scheme. Cucumber therefore needs to do three things at launch time:

1. fork itself into the background so that Xcode testing can proceed, that is, daemonise;
2. wait for the wire server to set itself up;
3. close down the wire server when Cucumber finishes running its features and invoking the remote-wire step definitions. This can happen automatically when it server sees no wire connection after a given period of time, say a second.

Step 2 raises issues when Cucumber tests actual iOS devices where the server does not open a port on `localhost`. Waiting for the wire server to initialise (step 2) requires that the Cucumber run-time environment establishes the wire server's address and port information. Without it, the Cucumber run will fail. The environment needs to wait an acceptable time for the server to appear on the prescribed port. Moreover, the client-side environment needs to attempt and reattempt to connect. The initial attempts will likely fail with a "refuse to connect" exception, simply because the server has not yet opened the socket. Steps 2 and 3 together imply a setting up and tearing down at the Cucumber client side.

## MIT Licensing

Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom

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
