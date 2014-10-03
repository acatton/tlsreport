#!/usr/bin/env ruby
# encoding: UTF-8
# (C) 2014, Antoine Catton <devel@antoine.catton.fr> (See license file)

require 'openssl'
require 'socket'

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

# XXX-Antoine: OpenSSL::Cipher.ciphers doesn't give all of them.
# Don't ask me why...
ctx = OpenSSL::SSL::SSLContext.new
ctx.ciphers = 'ALL'
ciphers_list = ctx.ciphers.map do |cipher|
        cipher[0] # [name, version, bits, algo]
    end
ciphers = []

loop do

    begin
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ciphers = ciphers_list

        sock = TCPSocket.new host, port

        ssock = OpenSSL::SSL::SSLSocket.new sock, ctx
        ssock.connect

        cipher_name = ssock.cipher[0] # [name, version, bits, algo]
        ciphers.push cipher_name
        ciphers_list.delete cipher_name
    rescue OpenSSL::SSL::SSLError
        break
    ensure
        sock.close
    end

end

ciphers.each do |name|
    puts name
end
