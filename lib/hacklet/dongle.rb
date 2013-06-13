require 'logger'
require 'timeout'

module Hacklet
  class Dongle
    attr_reader :logger

    # Public: Initializes a dongle instance and yields it.
    #
    # logger - The Logger instance to log to, defaults to STDOUT.
    #
    # Returns nothing.
    def self.open(logger=Logger.new(STDOUT))
      serial = SerialConnection.new(logger)
      dongle = Dongle.new(serial, logger)
      begin
        dongle.send(:boot)
        dongle.send(:boot_confirm)
        yield dongle
      ensure
        serial.close
      end
    end

    # serial - Serial connection to use with the dongle.
    # logger - The Logger instance to log to.
    def initialize(serial, logger)
      @serial = serial
      @logger = logger
    end

    # Public: Listens for new devices on the network.
    #
    # This must be executed within an open session.
    #
    # Returns nothing.
    def commission
      response = nil
      begin
        unlock_network
        Timeout.timeout(30) do
          @logger.info("Listening for devices ...")
          loop do
            buffer = @serial.receive(4)
            buffer += @serial.receive(buffer.bytes.to_a[3]+1)
            if buffer.bytes.to_a[1] == 0xa0
              response = BroadcastResponse.read(buffer)
              @logger.info("Found device 0x%x on network 0x%x" % [response.device_id, response.network_id])
              break
            end
          end
        end
      rescue Timeout::Error
      ensure
        lock_network
      end

      update_time(response.network_id) if response
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
      @serial.transmit(HandshakeRequest.new(:network_id => network_id))
      HandshakeResponse.read(@serial.receive(6))
    end

    # Public: Request stored samples.
    #
    # network_id - 2 byte identified for the network.
    # channel_id - 2 byte identified for the channel.
    #
    # TODO: This needs to return a more usable set of data.
    # Returns the SamplesResponse.
    def request_samples(network_id, channel_id)
      @logger.info("Requesting samples")
      @serial.transmit(SamplesRequest.new(:network_id => network_id, :channel_id => channel_id))
      AckResponse.read(@serial.receive(6))
      buffer = @serial.receive(4)
      remaining_bytes = buffer.bytes.to_a[3] + 1
      buffer += @serial.receive(remaining_bytes)
      response = SamplesResponse.read(buffer)

      response.converted_samples.each do |time, wattage|
        @logger.info("#{wattage}w at #{time}")
      end
      @logger.info("#{response.sample_count} returned, #{response.stored_sample_count} remaining")

      response
    end

    # Public: Used to controls whether a socket is on or off.
    #
    # network_id - 2 byte identified for the network.
    # channel_id - 1 byte identified for the channel.
    # enabled    - true enables the socket and false disables it.
    #
    # Returns the SwitchResponse.
    def switch(network_id, channel_id, state)
      request = ScheduleRequest.new(:network_id => network_id, :channel_id => channel_id)
      if state
        request.always_on!
        @logger.info("Turning on channel #{channel_id} on network 0x#{network_id.to_s(16)}")
      else
        request.always_off!
        @logger.info("Turning off channel #{channel_id} on network 0x#{network_id.to_s(16)}")
      end
      @serial.transmit(request)
      ScheduleResponse.read(@serial.receive(6))
    end

    # Public: Unlocks the network, to add a new device.
    #
    # Returns the BootConfirmResponse
    def unlock_network
      @logger.info("Unlocking network")
      @serial.transmit(UnlockRequest.new)
      LockResponse.read(@serial.receive(6))
      @logger.info("Unlocking complete")
    end

    # Public: Locks the network, prevents adding new devices.
    #
    # Returns the BootConfirmResponse
    def lock_network
      @logger.info("Locking network")
      @serial.transmit(LockRequest.new)
      LockResponse.read(@serial.receive(6))
      @logger.info("Locking complete")
    end

  private
    # Private: Initializes the dongle for communication
    #
    # Returns the BootResponse
    def boot
      @logger.info("Booting")
      @serial.transmit(BootRequest.new)
      BootResponse.read(@serial.receive(27))
    end

    # Private: Confirms that booting was successful?
    #
    # Not sure about this.
    #
    # Returns the BootConfirmResponse
    def boot_confirm
      @serial.transmit(BootConfirmRequest.new)
      BootConfirmResponse.read(@serial.receive(6))
      @logger.info("Booting complete")
    end

    # Private: Updates the time of a device.
    #
    # This must be executed within an open session. I'm guessing it selects the
    # network.
    #
    # network_id - 2 byte identified for the network.
    #
    # Returns nothing.
    def update_time(network_id)
      @serial.transmit(UpdateTimeRequest.new(:network_id => network_id))
      UpdateTimeAckResponse.read(@serial.receive(6))
      UpdateTimeResponse.read(@serial.receive(8))
    end
  end
end
