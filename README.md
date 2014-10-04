# TLS Report

Give a list of ciphers supported by a server.

(Basically doing what ssllabs.com do, but locally)

## How to use

This is the pattern:

    $ ./report.rb hostname port [delay]

The delay is in seconds.


For example:

    $ ./report.rb example.com 443 2
    $ ./report.rb localhost https

## License

This is licensed under the European Union Public License

## FAQ

### As a pythonista, why did you choose ruby?

First of all, I always wanted to to learn ruby. I don't understand why people
oppose those two worlds.

But, I mainly chose ruby because I was impressed by its OpenSSL binding. It's
extensive, well integrated into the language, well documented.
