# Copyright 2011 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'core/streams'
require 'core/ssl_support'
require 'core/global_handlers'

module Vertx

  # Mixin module that provides all the common TCP params that can be set.
  #
  # @author {http://tfox.org Tim Fox}
  module TCPSupport

    # Set the TCP send buffer size.
    # @param [FixNum] val. The size in bytes.
    # @return [] A reference to self so invocations can be chained
    def send_buffer_size=(val)
      @j_del.setSendBufferSize(val)
      self
    end

    # Set the TCP receive buffer size.
    # @param [FixNum] val. The size in bytes.
    # @return [] A reference to self so invocations can be chained
    def receive_buffer_size=(val)
      @j_del.setReceiveBufferSize(val)
      self
    end

    # Set the TCP keep alive setting.
    # @param [Boolean] val. If true, then TCP keep alive will be enabled.
    # @return [] A reference to self so invocations can be chained
    def tcp_keep_alive=(val)
      @j_del.setTCPKeepAlive(val)
    end

    # Set the TCP reuse address setting.
    # @param [Boolean] val. If true, then TCP reuse address will be enabled.
    # @return [] A reference to self so invocations can be chained
    def reuse_address=(val)
      @j_del.setReuseAddress(val)
    end

    # Set the TCP so linger setting.
    # @param [Boolean] val. If true, then TCP so linger will be enabled.
    # @return [] A reference to self so invocations can be chained
    def so_linger=(val)
      @j_del.setSoLinger(val)
    end

    # Set the TCP traffic class setting.
    # @param [FixNum] val. The TCP traffic class setting.
    # @return [] A reference to self so invocations can be chained
    def traffic_class=(val)
      @j_del.setTrafficClass(val)
    end

  end

  # Encapsulates a server that understands TCP or SSL.
  #
  # Instances of this class can only be used from the event loop that created it. When connections are accepted by the server
  # they are supplied to the user in the form of a {NetSocket} instance that is passed via the handler
  # set using {#connect_handler}.
  #
  # @author {http://tfox.org Tim Fox}
  class NetServer

    include SSLSupport, TCPSupport

    # Create a new NetServer
    def initialize
      @j_del = org.vertx.java.core.net.NetServer.new
    end

    # Client authentication is an extra level of security in SSL, and requires clients to provide client certificates.
    # Those certificates must be added to the server trust store.
    # @param [Boolean] val. If true then the server will request client authentication from any connecting clients, if they
    # do not authenticate then they will not make a connection.

    def client_auth_required=(val)
      @j_del.setClientAuthRequired(val)
      self
    end

    # Supply a connect handler for this server. The server can only have at most one connect handler at any one time.
    # As the server accepts TCP or SSL connections it creates an instance of {NetSocket} and passes it to the
    # connect handler.
    # @param [Proc] proc A proc to be used as the handler
    # @param [Block] hndlr A block to be used as the handler
    # @return [NetServer] A reference to self so invocations can be chained
    def connect_handler(proc = nil, &hndlr)
      hndlr = proc if proc
      @j_del.connectHandler{ |j_socket| hndlr.call(NetSocket.new(j_socket)) }
      self
    end

    # Instruct the server to listen for incoming connections.
    # @param [FixNum] port. The port to listen on.
    # @param [FixNum] host. The host name or ip address to listen on.
    # @return [NetServer] A reference to self so invocations can be chained
    def listen(port, host = "0.0.0.0")
      @j_del.listen(port, host)
      self
    end

    # Close the server. The handler will be called when the close is complete.
    def close(&hndlr)
      @j_del.close(hndlr)
    end

  end

  # NetClient is an asynchronous factory for TCP or SSL connections.
  #
  # Multiple connections to different servers can be made using the same instance. Instances of this class can be shareddata by different
  # event loops.
  #
  # @author {http://tfox.org Tim Fox}
  class NetClient

    include SSLSupport, TCPSupport

    # Create a new NetClient
    def initialize
      @j_del = org.vertx.java.core.net.NetClient.new
    end

    # Should the client trust ALL server certificates?
    # @param [Boolean] val. If val is set to true then the client will trust ALL server certificates and will not attempt to authenticate them
    # against it's local client trust store. The default value is false.
    # Use this method with caution!
    # @return [NetClient] A reference to self so invocations can be chained
    def trust_all=(val)
      @j_del.setTrustAll(val)
      self
    end

    # Attempt to open a connection to a server. The connection is opened asynchronously and the result returned in the
    # handler.
    # @param [FixNum] port. The port to connect to.
    # @param [String] host. The host or ip address to connect to.
    # @param [Proc] proc A proc to be used as the handler
    # @param [Block] hndlr A block to be used as the handler
    # @return [NetClient] A reference to self so invocations can be chained
    def connect(port, host = "localhost", proc = nil, &hndlr)
      hndlr = proc if proc
      @j_del.connect(port, host) { |j_socket| hndlr.call(NetSocket.new(j_socket)) }
      self
    end

    # Close the NetClient. Any open connections will be closed.
    def close
      @j_del.close
    end

  end


  # @author {http://tfox.org Tim Fox}
  class NetSocket

    include ReadStream, WriteStream

    # @private
    def initialize(j_socket)
      @j_del = j_socket
      @write_handler_id = Vertx::register_handler { |buffer|
        write_buffer(buffer)
      }
      @j_del.closedHandler(Proc.new {
        Vertx::unregister_handler(@write_handler_id)
        @closed_handler.call if @closed_handler
      })
    end

    # Write a {Buffer} to the socket. The handler will be called when the buffer has actually been written to the wire.
    # @param [Buffer] buff. The buffer to write.
    # @param [Block] compl. The handler to call on completion.
    def write_buffer(buff, &compl)
      j_buff = buff._to_java_buffer
      if compl == nil
        @j_del.write(j_buff)
      else
        @j_del.write(j_buff, compl)
      end
    end

    # Write a String to the socket. The handler will be called when the string has actually been written to the wire.
    # @param [String] str. The string to write.
    # @param [String] enc. The encoding to use.
    # @param [Block] compl. The handler to call on completion.
    def write_str(str, enc = "UTF-8", &compl)
      if (compl == nil)
        @j_del.writeString(str, enc)
      else
        @j_del.writeString(str, enc, compl)
      end
    end

    # Set a closed handler on the socket.
    # @param [Proc] proc A proc to be used as the handler
    # @param [Block] hndlr A block to be used as the handler
    def closed_handler(proc = nil, &hndlr)
      hndlr = proc if proc
      @closed_handler = hndlr;
    end

    #  Tell the kernel to stream a file directly from disk to the outgoing connection, bypassing userspace altogether
    # (where supported by the underlying operating system. This is a very efficient way to stream files.
    # @param [String] file_path. Path to file to send.
    def send_file(file_path)
      @j_del.sendFile(file_path)
    end

    # Close the socket
    def close
      @j_del.close
    end

    #  When a NetSocket is created it automatically registers a global event handler with the system. The ID of that
    # handler is given by {#write_handler_id}.
    # Given this ID, a different event loop can send a buffer to that event handler using {send_to_handler} and
    # that buffer will be received by this instance in its own event loop and writing to the underlying connection. This
    # allows you to write data to other connections which are owned by different event loops.
    def write_handler_id
      @write_handler_id
    end

  end
end

