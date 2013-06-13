require 'serialport'

module Hacklet
  class SerialConnection
    def initialize(logger, port='/dev/ttyUSB0')
      @logger = logger
      @connection = SerialPort.new(port, 115200, 8, 1, SerialPort::NONE)
      @connection.flow_control = SerialPort::NONE
    end

    # Public: Closes the connection
    #
    # Returns nothing.
    def close
      @connection.close
    end

    # Public: Transmits the packet to the dongle.
    #
    # command - The binary string to send.
    #
    # Returns the number of bytes written.
    def transmit(command)
      @logger.debug("TX: #{unpack(command.to_binary_s).inspect}")
      @connection.write(command.to_binary_s)
    end

    # Public: Waits and receives the specified number of packets from the
    # dongle.
    #
    # bytes - The number of bytes to read.
    #
    # Returns a binary string containing the response.
    def receive(bytes)
      response = @connection.read(bytes)
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
      message.unpack('H2*')
    end
  end
end
