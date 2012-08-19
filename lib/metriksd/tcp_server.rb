require 'metriksd/registry'
require 'msgpack'
require 'celluloid'
require 'celluloid/io'

module Metriksd
  class TcpServer
    include Celluloid::IO

    attr_reader :logger, :port, :host, :registry

    def initialize(registry, options = {})
      missing_keys = %w(port) - options.keys.map(&:to_s)
      unless missing_keys.empty?
        raise ArgumentError, "Missing required options: #{missing_keys * ', '}"
      end

      @registry = registry
      @port     = options[:port]
      @host     = options[:host]    || '0.0.0.0'
      @logger   = options[:logger]  || ::Logger.new(STDERR)

      @unpacker = MessagePack::Unpacker.new
    end
    
    def start
      @server ||= TCPServer.new(@host, @port)
      run!
    end

    def stop
      @server.close if @server
    end

    def finalize
      stop
    end

    def run
      loop do
        begin
          handle_connection! @server.accept
        rescue IOError
          logger.warn "Server died with an error."
        end
      end
    end

    def handle_connection(connection)
      loop do
        data = connection.readpartial(512)
        unmarshal(data)
      end
    end

    def unmarshal(data)
      @unpacker.feed_each(data) do |payload|
        @registry << Data.new(payload)
      end
    end
  end
end
