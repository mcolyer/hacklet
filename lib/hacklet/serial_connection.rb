require 'ftdi'

module Hacklet
  class SerialConnection
    def initialize(logger, port='/dev/ttyUSB0')
      @logger = logger
      @connection = Ftdi::Context.new
      @connection.usb_open(0x0403, 0x8c81)
      @connection.set_bitmode(0x00, Ftdi::BitbangMode[:reset])
      @connection.baudrate = 115200
      @connection.flowctrl = Ftdi::SIO_DISABLE_FLOW_CTRL
      @connection.dtr = 1
      @connection.rts = 1
      @receive_buffer = ""
    end

    # Public: Closes the connection
    #
    # Returns nothing.
    def close
      @connection.usb_close
    end

    # Public: Transmits the packet to the dongle.
    #
    # command - The binary string to send.
    #
    # Returns the number of bytes written.
    def transmit(command)
      @logger.debug("TX: #{unpack(command.to_binary_s).inspect}")
      @connection.write_data(command.to_binary_s)
    end

    # Public: Waits and receives the specified number of packets from the
    # dongle.
    #
    # bytes - The number of bytes to read.
    #
    # Returns a binary string containing the response.
    def receive(bytes)
      response = ""
      loop do
        if bytes <= @receive_buffer.bytesize
          array = @receive_buffer.bytes.to_a
          response = array[0..(bytes - 1)].pack('c*')
          @receive_buffer = array[(bytes)..-1].pack('c*')
          break
        end

        chunk = @connection.read_data
        if chunk.bytesize > 0
          @receive_buffer += chunk
        else
          sleep(0.1)
        end
      end
      @logger.debug("RX: #{unpack(response).inspect}")

      response
    end

  private
    # Private: Prints a binary string a concise hexidecimal form for debugging
    #
    # message - The message to parse.
    #
    # Returns a string of hexidecimal representing equivalent to the message.
    def unpack(message)
      message.unpack('H2'*message.size)
    end
  end
end
