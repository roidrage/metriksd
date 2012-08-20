require 'test_helper'

class TcpServerTest < Test::Unit::TestCase
  def setup
    @registry = Metriksd::Registry.new
    @port = 30000 + rand(1000)
    @server = Metriksd::TcpServer.new(@registry, :port => @port)
    @server.start
  end

  def teardown
    @server.stop
    @server.join
  end

  def test_data
    data = {:client_id => "client1", :name => "metric", :time => Time.now.to_i, :something => "value"}.to_msgpack
    socket = TCPSocket.new('localhost', @port)
    socket.write(data)
    sleep 0.1

    assert @server.registry.dirty?
  end
end
