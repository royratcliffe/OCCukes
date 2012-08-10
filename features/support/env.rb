require 'cucumber/wire_support/configuration'

# This is a hacking way to interact with the wire configuration. It
# redefines the instance host and port attribute readers and defines a
# new pair of matching class-singleton accessors. If the configuration
# cannot access the instance host and post attributes, it looks for
# these within the singleton class. This way, our AfterConfiguration
# block can provide default host and port for the wire configuration
# for when it has no host and port. The configuration will pick up the
# address and port number obtained via Bonjour or pick up the defaults
# instead. Hence, the wire configuration does not require a host or
# port value.
module Cucumber
  module WireSupport
    class Configuration
      class << self
        attr_accessor :host
        attr_accessor :port
      end
      def host
        @host || self.class.host
      end
      def port
        @port || self.class.port
      end
    end
  end
end

AfterConfiguration do |config|
  # First, daemonise this Cucumber process. This assumes that Xcode
  # launches Cucumber as a pre-action for the test scheme. If you use
  # RVM, the pre-action script might look something like this:
  #
  #   PATH=$PATH:$HOME/.rvm/bin
  #   rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out "$OBJROOT/features.html"
  #
  # Please be aware: from this point forward, the Cucumber process
  # forks away from the parent process and becomes a background
  # process. The parent process, typically Xcode, continues. However,
  # the fork interferes if you want to debug the Cucumber
  # client. Breakpoints will never break if set beyond the
  # fork. Better to comment out the following line when debugging.
  #
  # Work out if the current process runs from Xcode or not. Only fork
  # if it does. Avoid the fork if running independently. This will
  # help when debugging. Use XCODE_VERSION_ACTUAL to determine if
  # launching from Xcode. Xcode sets up that environment variable,
  # assuming you provide build settings from your test target. For
  # Xcode 4.4, the actual version equals 0440.
  Process.daemon(true, true) if ENV['XCODE_VERSION_ACTUAL']

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

  # If the wire configuration does not specify the host then try
  # Bonjour else fall back to local host. The port defaults to 54321.
  #
  # If Ruby can find the "dnssd" gem, try to resolve the host and port
  # dynamically using DNSSD, DNS-based service discovery, also known
  # as Bonjour. If discovery succeeds, no need to probe for the open
  # socket. Instead, assume the open socket exists. Otherwise why
  # would the server publish the service? Allow thirty seconds for
  # service discovery to browse and resolve the service, and then look
  # up the address information. The underlying Ruby socket
  # implementation wants an IP address, a string in dotted decimal.
  host = params['host']
  port = params['port']
  begin
    require 'dnssd'
    require 'timeout'
    begin
      Timeout::timeout(30) do
        dnssd_params = params['dnssd'] || {}
        DNSSD.browse!(dnssd_params['type'] || '_oc-cucumber-runtime._tcp.') do |browse|
          DNSSD.resolve!(browse) do |resolve|
            DNSSD::Service.new.getaddrinfo(resolve.target) do |addr_info|
              host = addr_info.address
              port = resolve.port
              STDERR.puts "Cucumber wire connecting to #{resolve.name}, address #{host}, port #{port}"
              raise Timeout::Error
            end
          end
        end
      end
    rescue Timeout::Error
    end
  rescue LoadError
  end if !host
  sync_with_host = !host
  host ||= 'localhost'
  port ||= 54321
  Cucumber::WireSupport::Configuration.host = host
  Cucumber::WireSupport::Configuration.port = port

  # Finally, wait for the wire socket to open. Try a connection once a
  # second for thirty seconds. Give Xcode thirty seconds to set up the
  # test host. This could involve launching the iOS simulator. So it
  # might take a little while at first. Continue when the connection
  # does not refuse. This adds a short latency: the distance in time
  # between the wire server accepting connections and the socket probe
  # finding a non-refusal. The latency is always less than one second.
  #
  # No need to send an exit message. The wire server automatically exits
  # when all the connections close.
  Timeout::timeout(30) do
    loop do
      begin
        TCPSocket.open(host, port).close
        break
      rescue Errno::ECONNREFUSED
        sleep 1
      end
    end
  end if sync_with_host
end
