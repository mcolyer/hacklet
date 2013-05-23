require 'bindata'

module Hacklet
  class Message < BinData::Record
    def calculate_checksum
      checksum_fields = @field_names - [:header, :checksum]
      buffer = StringIO.new
      io = BinData::IO.new(buffer)
      checksum_fields.each do |field|
        puts field
        send(field).do_write(io)
      end
      buffer.rewind

      a = buffer.read.bytes.inject(0) { |s,x| s^x }
      puts a.to_s(16)
      a
    end
  end

  class BootResponse < Message
    endian :big

    uint8  :header, :check_value => lambda { value == 0x02 }
    uint16 :command, :check_value => lambda { value == 0x4084 }
    uint8  :payload_length, :check_value => lambda { value == 22 }

    # TODO: Determine what's in here
    string :data, :length => 12

    uint64 :network_id
    uint16 :device_id

    uint8 :checksum, :check_value => lambda { calculate_checksum == checksum }
  end

  class BootConfirmResponse < Message
    endian :big

    uint8  :header, :check_value => lambda { value == 0x02 }
    uint16 :command, :check_value => lambda { value == 0x4080 }
    uint8  :payload_length, :check_value => lambda { value == 1 }

    uint8  :data, :check_value => lambda { value == 0x10 }

    uint8 :checksum, :check_value => lambda { calculate_checksum == checksum }
  end

  class LockResponse < Message
    endian :big

    uint8  :header, :check_value => lambda { value == 0x02 }
    uint16 :command, :check_value => lambda { value == 0xA0F9 }
    uint8  :payload_length, :check_value => lambda { value == 1 }

    uint8be :data, :check_value => lambda { value == 0x00 }

    uint8 :checksum, :check_value => lambda { calculate_checksum == checksum }
  end

  class HandshakeResponse < Message
    endian :big

    uint8  :header, :check_value => lambda { value == 0x02 }
    uint16 :command, :check_value => lambda { value == 0x4003 }
    uint8  :payload_length, :check_value => lambda { value == 1 }

    uint8be :data, :check_value => lambda { value == 0x00 }

    uint8 :checksum, :check_value => lambda { calculate_checksum == checksum }
  end

  class AckResponse < Message
    endian :big

    uint8  :header, :check_value => lambda { value == 0x02 }
    uint16 :command, :check_value => lambda { value == 0x4024 }
    uint8  :payload_length, :check_value => lambda { value == 1 }

    uint8be :data, :check_value => lambda { value == 0x00 }

    uint8 :checksum, :check_value => lambda { calculate_checksum == checksum }
  end

  class SampleResponse < Message
    endian :big

    uint8  :header, :check_value => lambda { value == 0x02 }
    uint16 :command, :check_value => lambda { value == 0x40A4 }
    uint8  :payload_length

    uint16   :network_id
    uint16   :channel_id
    # TODO: Confirm this is actually the device id
    uint16   :device_id
    uint32le :time
    uint16le :sample_count
    uint16le :stored_sample_count
    array    :samples, :type => [:uint16le], :initial_length => :sample_count

    uint8 :checksum, :check_value => lambda { calculate_checksum == checksum }
  end

  class ScheduleResponse < Message
    endian :big

    uint8  :header, :check_value => lambda { value == 0x02 }
    uint16 :command, :check_value => lambda { value == 0x4023 }
    uint8  :payload_length, :check_value => lambda { value == 1 }

    uint8be :data, :check_value => lambda { value == 0x00 }

    uint8 :checksum, :check_value => lambda { calculate_checksum == checksum }
  end

  class BootRequest < Message
    endian :big

    uint8  :header, :initial_value => 0x02
    uint16 :command, :initial_value => 0x4004
    uint8  :payload_length

    uint8 :checksum, :value => :calculate_checksum
  end

  class BootConfirmRequest < Message
    endian :big

    uint8  :header, :initial_value => 0x02
    uint16 :command, :initial_value => 0x4000
    uint8  :payload_length

    uint8 :checksum, :value => :calculate_checksum
  end

  class LockRequest < Message
    endian :big

    uint8  :header, :initial_value => 0x02
    uint16 :command, :initial_value => 0xA236
    uint8  :payload_length, :initial_value => 4

    # TODO: What is this?
    uint32 :data, :initial_value => 0xFCFF0001

    uint8 :checksum, :value => :calculate_checksum
  end

  class HandshakeRequest < Message
    endian :big

    uint8  :header, :initial_value => 0x02
    uint16 :command, :initial_value => 0x4003
    uint8  :payload_length, :initial_value => 4

    uint16 :network_id
    # TODO: What is this?
    uint16 :data, :initial_value => 0x0500

    uint8 :checksum, :value => :calculate_checksum
  end

  class SamplesRequest < Message
    endian :big

    uint8  :header, :initial_value => 0x02
    uint16 :command, :initial_value => 0x4024
    uint8  :payload_length, :initial_value => 6

    uint16 :network_id
    uint16 :channel_id
    # TODO: What is this?
    uint16 :data, :initial_value => 0x0A00

    uint8 :checksum, :value => :calculate_checksum
  end

  class ScheduleRequest < Message
    endian :big

    uint8  :header, :initial_value => 0x02
    uint16 :command, :initial_value => 0x4023
    uint8  :payload_length, :initial_value => 59

    uint16 :network_id
    uint8  :channel_id
    array  :schedule, :type => [:uint8], :initial_length => 56

    uint8 :checksum, :value => :calculate_checksum

    def always_on!
      bitmap = [0x7f]*56
      bitmap[5] = 0x25
      schedule.assign(bitmap)
    end

    def always_off!
      bitmap = [0xff]*56
      bitmap[5] = 0xa5
      schedule.assign(bitmap)
    end
  end
end
