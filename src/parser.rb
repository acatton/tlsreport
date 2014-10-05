# encoding: UTF-8
# (C) 2014, Antoine Catton <devel@antoine.catton.fr> (See license file)

require 'optparse'
require 'ostruct'

require_relative 'logger'

module TLSReport
    class OptionParser
        def self.parse(argv)
            options = ::OpenStruct.new
            options.delay = 0
            options.host = nil
            options.port = "https"

            options_parser = ::OptionParser.new do |opts|
                opts.banner = "Usage: #{$0} [--delay N] host [port]"

                opts.separator ""
                opts.separator "Options:"

                opts.on "--delay N", Float, "Pause N seconds between connnections tries." do |n|
                    options.delay = n
                end

                opts.separator ""
                opts.separator "Common options:"

                opts.on_tail "-h", "--help", "Show this message" do
                    puts opts
                    exit
                end

                opts.on_tail "-V", "--version", "Show version" do
                    puts "Version: 1.0a (development stage)" # FIXME: Don't hardcode this shit
                    exit
                end

            end

            arguments = options_parser.parse argv

            if arguments.length < 1
                TLSReport::Logger.instance.error "Please specify a host"
                puts options_parser
                exit 2
            end

            options.host = arguments[0]
            options.port = arguments[1] unless arguments.length < 2

            return options
        end
    end
end
