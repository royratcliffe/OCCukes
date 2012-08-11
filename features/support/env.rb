require 'cucumber/wire_support/configuration'

begin
  require 'dnssd'
rescue LoadError
end

require 'timeout'

# Extends Cucumber's wire support configuration class.
#
# Replaces the #initialize, #host and #port methods. The new method
# implementations allow for DNS service discovery, or synchronisation
# when using explicit host address and port number.  The configuration
# will pick up the address and port number obtained via Bonjour or
# pick up the defaults instead. Hence, the wire configuration does not
# require a host or port value. If the host specifies a service type
# of the form "_service-type._tcp." then the replacement initialiser
# attempts a service discovery using DNS-SD.
module Cucumber
  module WireSupport
    class Configuration
      alias_method :original_initialize, :initialize
      alias_method :original_host, :host
      alias_method :original_port, :port

      # Cucumber supports multiple languages, even during the same
      # run. The wire language is just one of many.
      def initialize(wire_file)
        original_initialize(wire_file)
        if net_service_discovery?
          discover_net_service
        else
          sync
        end
      end

      def host
        @net_service_host || original_host || 'localhost'
      end

      def port
        @net_service_port || original_port || 54321
      end

      # Answers non-nil if the host configuration conforms to DNS
      # Service Discovery type expectations. Answers nil if not.
      def net_service_discovery?
        original_host =~ /_[-a-z0-9]+._[-a-z0-9]+./
      end

      # If Ruby can find the "dnssd" gem, try to resolve the host and
      # port dynamically using DNS-SD, DNS-based service discovery,
      # also known as Bonjour. If discovery succeeds, no need to probe
      # for the open socket. Instead, assume the open socket
      # exists. Otherwise why would the server publish the service?
      # Allow thirty seconds for service discovery to browse and
      # resolve the service, and then look up the address
      # information. The underlying Ruby socket implementation wants
      # an IP address, a string in dotted decimal.
      def discover_net_service
        begin
          Timeout::timeout(30) do
            DNSSD.browse!(original_host || '_occukes-runtime._tcp.') do |browse|
              DNSSD.resolve!(browse) do |resolve|
                DNSSD::Service.new.getaddrinfo(resolve.target) do |addr_info|
                  @net_service_host, @net_service_port = addr_info.address, resolve.port
                  STDERR.puts "Cucumber wire connecting to #{resolve.name}, address #{@net_service_host}, port #{@net_service_port}"
                  raise Timeout::Error
                end
              end
            end
          end
        rescue Timeout::Error
        end
      end

      # Wait for the wire socket to open. Try a connection once a
      # second for thirty seconds. Give Xcode thirty seconds to set up
      # the test host. This could involve launching the iOS
      # simulator. So it might take a little while at first. Continue
      # when the connection does not refuse. This adds a short
      # latency: the distance in time between the wire server
      # accepting connections and the socket probe finding a
      # non-refusal. The latency is always less than one second.
      #
      # No need to send an exit message. The wire server automatically
      # exits when all the connections close.
      def sync
        Timeout::timeout(30) do
          loop do
            begin
              TCPSocket.open(original_host, original_port).close
              break
            rescue Errno::ECONNREFUSED
              sleep 1
            end
          end
        end
      end
    end
  end
end

# Daemonise this Cucumber process. This assumes that Xcode launches
# Cucumber as a pre-action for the test scheme. If you use RVM, the
# pre-action script might look something like this:
#
#   PATH=$PATH:$HOME/.rvm/bin
#   rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out "$OBJROOT/features.html"
#
# Please be aware: from this point forward, the Cucumber process forks
# away from the parent process and becomes a background process. The
# parent process, Xcode, continues. However, the fork interferes if
# you want to debug the Cucumber client. Breakpoints will never break
# if set beyond the fork.
#
# Therefore, work out if the current process runs from Xcode or
# not. Only fork if it does. Avoid the fork if running
# independently. This helps when debugging. Use XCODE_VERSION_ACTUAL
# to determine if launching from Xcode. Xcode sets up that environment
# variable, assuming you provide build settings from your test
# target. For Xcode 4.4, the actual version equals 0440. Actual value
# does not matter; only presence matters.
Process.daemon(true, true) if ENV['XCODE_VERSION_ACTUAL']
