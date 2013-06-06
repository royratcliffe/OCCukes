source 'https://rubygems.org'

# Include a Gemfile for the sake of Bundler. You might want to run a specific
# version of Cucumber, or run Cucumber within some IDE tool (e.g. RubyMine) that
# automatically wraps the Gem execution environment using Bundler, a good thing.
#
# Cucumber wire support now needs an explicit to_json implementation. Require
# the implementation from ActiveSupport. Without this, Ruby-side wire support
# throws an exception.
gem 'cucumber'
gem 'activesupport'

# Cucumber syntax highlighting.
gem 'syntax'

# Add RSpec to the bundle. Without this specific inclusion, you cannot
# run Cucumber from TextMate without error. TextMate looks for the
# Gemfile and runs Cucumber and RSpec within the bundled environment.
gem 'rspec'

# If your Ruby gems include "dnssd" then the AfterConfiguration
# environment support block in env.rb will automatically synchronise
# with the Cucumber wire runtime using Bonjour. See
# http://dnssd.rubyforge.org for details.
gem 'dnssd'

# Appledoc and Doxygen documentation.
gem 'rake'
gem 'XcodePages'
gem 'nokogiri'
