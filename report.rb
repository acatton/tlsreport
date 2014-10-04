#!/usr/bin/env ruby
# encoding: UTF-8
# (C) 2014, Antoine Catton <devel@antoine.catton.fr> (See license file)

require 'openssl'
require 'socket'
require 'set'

methods_list = [:SSLv2, :SSLv3, :TLSv1, :TLSv1_1, :TLSv1_2]
all_methods = Set.new methods_list
methods_names = {
    :SSLv2   => "SSL version 2",
    :SSLv3   => "SSL version 3",
    :TLSv1   => "TLS version 1",
    :TLSv1_1 => "TLS version 1.1",
    :TLSv1_2 => "TLS version 1.2",
}

def usage(error)
    STDERR.puts "Error: #{error}"
    STDERR.puts "Usage: #{$0} hostname port"
    exit 127
end

if ARGV.length < 2
    usage "Specify a hostname and a port"
end

host = ARGV[0]
port = ARGV[1]

def get_all_ciphers(method)
    # XXX-Antoine: OpenSSL::Cipher.ciphers doesn't give all of them.
    # Don't ask me why...
    ctx = OpenSSL::SSL::SSLContext.new method
    ctx.ciphers = 'ALL'
    return ctx.ciphers.map do |cipher|
            cipher[0] # [name, version, bits, algo]
    end
end

def get_ciphers(method, host, port)
    ciphers_list = get_all_ciphers method
    ciphers = []

    loop do

        begin
            ctx = OpenSSL::SSL::SSLContext.new method
            ctx.ciphers = ciphers_list

            sock = TCPSocket.new host, port

            ssock = OpenSSL::SSL::SSLSocket.new sock, ctx
            ssock.connect

            cipher_name = ssock.cipher[0] # [name, version, bits, algo]
            ciphers.push cipher_name
            ciphers_list.delete cipher_name
        rescue OpenSSL::SSL::SSLError
            return ciphers
        ensure
            sock.close
        end

    end

end

available_methods = Set.new OpenSSL::SSL::SSLContext::METHODS
methods = available_methods & all_methods

if methods < all_methods
    STDERR.puts "Warning: Your OpenSSL version and/or your ruby version doesn't support all TLS versions"
    unsupported_methods = all_methods - methods
    unsupported_methods.each do |item|
        STDERR.puts "Warning: #{methods_names[item]} not supported."
    end
end

results = Hash.new
methods.each do |method|
    results[method] = get_ciphers method, host, port
end

methods_list.each do |method|
    if results.has_key? method
        ciphers = results[method]
        if method != methods_list.first
            puts ""
        end
        full_name = methods_names[method]
        puts full_name
        puts "=" * full_name.length
        if ciphers.empty?
            puts "No support"
        else
            ciphers.each do |cipher|
                puts cipher
            end
        end
    end
end
