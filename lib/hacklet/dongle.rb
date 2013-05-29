require 'serialport'
require 'logger'
require 'timeout'

module Hacklet
  class Dongle
    # logger - Optionally takes a Logger instance, the default is to log to
    #          STDOUT
    def initialize(logger=Logger.new(STDOUT))
      @logger = logger
    end

    # Public: Initializes a session so the client can request data.
    #
    # port - Optional string for configuring the serial port device.
    #
    # Returns nothing.
    def open_session(port='/dev/ttyUSB0')
      @serial = open_serial_port(port)
      begin
        @logger.info("Booting")
        boot
        boot_confirm
        @logger.info("Booting complete")
        yield self
      ensure
        @serial.close
      end
    end

    # Public: Listens for new devices on the network.
    #
    # This must be executed within an open session.
    #
    # Returns nothing.
    def commission
      require_session

      begin
        unlock_network
        Timeout.timeout(30) do
          loop do
            @logger.info("Listening for devices ...")
            buffer = @serial.read(4)
            @logger.info("RX(pre): #{unpack(buffer).inspect}")
            buffer += @serial.read(buffer.bytes.to_a[3]+1)
            @logger.debug("RX(full): #{unpack(buffer).inspect}")
          end
        end
      rescue Timeout::Error
      ensure
        lock_network
      end
    end

    # Public: Selects the network.
    #
    # This must be executed within an open session. I'm guessing it selects the
    # network.
    #
    # network_id - 2 byte identified for the network.
    #
    # Returns nothing.
    def select_network(network_id)
      require_session

      transmit(HandshakeRequest.new(:network_id => network_id))
      HandshakeResponse.read(receive(6))
    end

    # Public: Request stored samples.
    #
    # network_id - 2 byte identified for the network.
    # channel_id - 2 byte identified for the channel.
    #
    # TODO: This needs to return a more usable set of data.
    # Returns the SamplesResponse.
    def request_samples(network_id, channel_id)
      require_session

      transmit(SamplesRequest.new(:network_id => network_id, :channel_id => channel_id))
      AckResponse.read(receive(6))
      buffer = receive(4)
      remaining_bytes = buffer.bytes.to_a[3] + 1
      buffer += receive(remaining_bytes)
      SamplesResponse.read(buffer)
    end

    # Public: Used to controls whether a socket is on or off.
    #
    # network_id - 2 byte identified for the network.
    # channel_id - 1 byte identified for the channel.
    # enabled    - true enables the socket and false disables it.
    #
    # Returns the SwitchResponse.
    def switch(network_id, channel_id, state)
      require_session

      request = ScheduleRequest.new(:network_id => network_id, :channel_id => channel_id)
      if state
        request.always_on!
      else
        request.always_off!
      end
      transmit(request)
      ScheduleResponse.read(receive(6))
    end

    # Public: Unlocks the network, to add a new device.
    #
    # Returns the BootConfirmResponse
    def unlock_network
      @logger.info("Unlocking network")
      transmit(UnlockRequest.new)
      LockResponse.read(receive(6))
      @logger.info("Unlocking complete")
    end

    # Public: Locks the network, prevents adding new devices.
    #
    # Returns the BootConfirmResponse
    def lock_network
      @logger.info("Locking network")
      transmit(LockRequest.new)
      LockResponse.read(receive(6))
      @logger.info("Locking complete")
    end

  private
    # Private: Initializes the dongle for communication
    #
    # Returns the BootResponse
    def boot
      transmit(BootRequest.new)
      BootResponse.read(receive(27))
    end

    # Private: Confirms that booting was successful?
    #
    # Not sure about this.
    #
    # Returns the BootConfirmResponse
    def boot_confirm
      transmit(BootConfirmRequest.new)
      BootConfirmResponse.read(receive(6))
    end

    # Private: Initializes the serial port
    #
    # port - the String to the device to open as a serial port.
    #
    # Returns a SerialPort object.
    def open_serial_port(port)
      SerialPort.new(port, 115200, 8, 1, SerialPort::NONE)
    end

    # Private: Transmits the packet to the dongle.
    #
    # command - The binary string to send.
    #
    # Returns the number of bytes written.
    def transmit(command)
      @logger.debug("TX: #{unpack(command.to_binary_s).inspect}")
      @serial.write(command.to_binary_s) if @serial
    end

    # Private: Waits and receives the specified number of packets from the
    # dongle.
    #
    # bytes - The number of bytes to read.
    #
    # Returns a binary string containing the response.
    def receive(bytes)
      if @serial
        response = @serial.read(bytes)
      else
        response = "\x0\x0\x0\x0"
      end
      @logger.debug("RX: #{unpack(response).inspect}")

      response
    end

    # Private: Prints a binary string a concise hexidecimal form for debugging
    #
    # message - The message to parse.
    #
    # Returns a string of hexidecimal representing equivalent to the message.
    def unpack(message)
      message.unpack('H2'*message.size)
    end

    # Private: A helper to ensure that the serial port is active.
    #
    # Returns nothing.
    # Raises RuntimeError if the serial port is not active.
    def require_session
      raise RuntimeError.new("Must be executed within an open session") unless @serial && !@serial.closed?
    end
  end
end
