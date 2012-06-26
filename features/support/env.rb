# Navigate to the wire language configuration. Cucumber supports
# multiple languages, even during the same run. The wire language is
# just one of many. No straightforward way exists for accessing the
# current language, or even the current runtime from within Cucumber
# step definition Ruby blocks.
#
# No need to send an exit message. The wire server automatically exits
# when all the connections close.
AfterConfiguration do |config|
  Process.daemon(true, true)
  feature_dirs = ['features'].map { |f| File.directory?(f) ? f : File.dirname(f) }.uniq
  wire_files = feature_dirs.map do |path|
    path = path.gsub(/\/$/, '')
    File.directory?(path) ? Dir["#{path}/**/*"] : path
  end.flatten.uniq
  wire_files.reject! { |f| !File.file?(f) }
  wire_files.reject! { |f| File.extname(f) != '.wire' }
  params = YAML.load(ERB.new(File.read(wire_files[0])).result)
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
