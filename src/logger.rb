require 'logger'
require 'singleton'

module TLSReport
    class Logger < ::Logger
        include ::Singleton

        def initialize()
            super STDERR
        end
    end
end
