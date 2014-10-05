# encoding: UTF-8
# (C) 2014, Antoine Catton <devel@antoine.catton.fr> (See license file)

require 'openssl'
require 'socket'
require 'set'

require_relative 'logger'

module TLSReport
    module TLS
        class Method
            METHODS = [:SSLv2, :SSLv3, :TLSv1, :TLSv1_1, :TLSv1_2]
            METHODS_NAMES = {
                :SSLv2   => "SSL version 2",
                :SSLv3   => "SSL version 3",
                :TLSv1   => "TLS version 1",
                :TLSv1_1 => "TLS version 1.1",
                :TLSv1_2 => "TLS version 1.2",
            }

            def initialize(method)
                @method = method
            end

            def name()
                return METHODS_NAMES[@method]
            end

            def ciphers()
                # XXX-Antoine: OpenSSL::Cipher.ciphers doesn't give all of them.
                # Don't ask me why...
                ctx = OpenSSL::SSL::SSLContext.new @method
                ctx.ciphers = 'ALL'
                return ctx.ciphers.map do |cipher|
                        cipher[0] # [name, version, bits, algo]
                end
            end

            def detect_ciphers(host, port, delay)
                ciphers_list = ciphers
                ciphers = []

                loop do

                    begin
                        ctx = OpenSSL::SSL::SSLContext.new @method
                        ctx.ciphers = ciphers_list

                        sock = TCPSocket.new host, port

                        ssock = OpenSSL::SSL::SSLSocket.new sock, ctx
                        ssock.connect

                        cipher_name = ssock.cipher[0] # [name, version, bits, algo]
                        ciphers << cipher_name
                        ciphers_list.delete cipher_name
                    rescue OpenSSL::SSL::SSLError, Errno::ECONNRESET
                        return ciphers
                    ensure
                        sock.close
                    end

                    sleep delay

                end

            end

            def self.available_methods()
                openssl_methods = Set.new OpenSSL::SSL::SSLContext::METHODS
                tlsreport_methods = Set.new METHODS

                available_methods = openssl_methods & tlsreport_methods

                if available_methods < tlsreport_methods
                    TLSReport::TLS::Logger.instance.warn "Your OpenSSL version and/or your ruby version doesn't support all TLS versions"
                    unsupported_methods = all_methods - methods
                    unsupported_methods.each do |item|
                        TLSReport::TLS::Logger.warn "#{methods_names[item]} not supported."
                    end
                end

                return available_methods
            end
        end

        class Report
            def initialize(options)
                @options = options
            end

            def results()
                results = Hash.new
                methods = Method.available_methods.to_a.map do |name|
                    Method.new name
                end

                host = @options.host
                port = @options.port
                delay = @options.delay

                methods.each do |method|
                    results[method.name] = method.detect_ciphers host, port, delay
                end

                return results

            end

            def to_s()
                return results.to_a.map do |(method, ciphers)|
                    lines = []
                    lines << method
                    lines << '=' * method.length

                    if ciphers.empty?
                        lines << "No support"
                    else
                        lines += ciphers
                    end

                    lines.join "\n"
                end.join "\n\n"
            end
        end
    end
end
