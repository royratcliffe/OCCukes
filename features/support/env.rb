AfterConfiguration do |config|
  # First, daemonise this Cucumber process. This assumes that Xcode
  # launches Cucumber as a pre-action for the test scheme. If you use
  # RVM, the pre-action script might look something like this:
  #
  #   PATH=$PATH:$HOME/.rvm/bin
  #   rvm 1.9.3 do cucumber "$SRCROOT/features" --format html --out features.html
  #
  Process.daemon(true, true)

  # Navigate to the wire language configuration. Cucumber supports
  # multiple languages, even during the same run. The wire language is
  # just one of many. No straightforward way exists for accessing the
  # current language, or even the current runtime from within Cucumber
  # at this point during the AfterConfiguration block. Instead
  # therefore, replicate Cucumber's way of finding and loading the
  # wire configuration.
  feature_dirs = ['features'].map { |f| File.directory?(f) ? f : File.dirname(f) }.uniq
  wire_files = feature_dirs.map do |path|
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
