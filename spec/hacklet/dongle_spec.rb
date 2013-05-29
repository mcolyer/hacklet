require 'spec_helper'

describe Hacklet::Dongle do
  subject do
    Hacklet::Dongle.new(Logger.new("/dev/null"))
  end

  it 'can open a new session' do
    serial_port = mock("SerialPort")

    # Boot
    serial_port.should_receive(:write).with([0x02, 0x40, 0x04, 0x00, 0x44].pack('c'*5))
    serial_port.should_receive(:read).and_return([0x02, 0x40, 0x84, 0x16, 0x01,
      0x00, 0x00, 0x87, 0x03, 0x00, 0x30, 0x00, 0x33, 0x83, 0x69, 0x9A, 0x0B,
      0x2F, 0x00, 0x00, 0x00, 0x58, 0x4F, 0x80, 0x0A, 0x1C, 0x81].pack('c'*27))

    # Boot Confirmation
    serial_port.should_receive(:write).with([0x02, 0x40, 0x00, 0x00, 0x40].pack('c'*5))
    serial_port.should_receive(:read).and_return([0x02, 0x40, 0x80, 0x01, 0x10, 0xd1].pack('c'*6))

    serial_port.should_receive(:close)
    subject.should_receive(:open_serial_port).and_return(serial_port)
    subject.open_session do
      # noop
    end
  end

  it 'can find a new device' do
    serial_port = mock("SerialPort")

    # Unlock Network
    serial_port.should_receive(:write).with([0x02, 0xA2, 0x36, 0x04, 0xFC, 0xFF, 0x90, 0x01, 0x02].pack('c'*9))
    serial_port.should_receive(:read).and_return([0x02, 0xA0, 0xF9, 0x01, 0x00, 0x58].pack('c'*6))

    # Listening for a response
    serial_port.should_receive(:read).and_return([0x02, 0x99, 0xd1, 0x23].pack('c'*4))
    serial_port.should_receive(:read).and_return([0x01, 0xcc, 0x1f, 0x10, 0x00,
      0x00, 0x58, 0x4f, 0x80, 0x00, 0x77, 0x2a, 0x8a, 0x33, 0xa7, 0xf4, 0xf6,
      0x80, 0xd0, 0x9c, 0x5d, 0x3c, 0x84, 0xf5, 0x2b, 0x43, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcb].pack('c'*36))
    serial_port.should_receive(:read).and_raise(Timeout::Error)

    # Lock Network
    serial_port.should_receive(:write).with([0x02, 0xA2, 0x36, 0x04, 0xFC, 0xFF, 0x00, 0x01, 0x92].pack('c'*9))
    serial_port.should_receive(:read).and_return([0x02, 0xA0, 0xF9, 0x01, 0x00, 0x58].pack('c'*6))

    serial_port.should_receive(:close)
    serial_port.stub!(:closed?).and_return(false)
    subject.should_receive(:open_serial_port).and_return(serial_port)
    subject.should_receive(:boot)
    subject.should_receive(:boot_confirm)

    subject.open_session do |session|
      session.commission
    end
  end

  it 'can request a sample' do
    serial_port = mock("SerialPort")

    # Selecting the network
    serial_port.should_receive(:write).with([0x02, 0x40, 0x03, 0x04, 0xA7, 0xB4, 0x05, 0x00, 0x51].pack('c'*9))
    serial_port.should_receive(:read).and_return([0x02, 0x40, 0x03, 0x01, 0x00, 0x42].pack('c'*6))

    # Requesting the sample
    serial_port.should_receive(:write).with([0x02, 0x40, 0x24, 0x06, 0xA7, 0xB4,
      0x00, 0x01, 0x0A, 0x00, 0x7a].pack('c'*11))
    serial_port.should_receive(:read).and_return([0x02, 0x40, 0x24, 0x01, 0x00, 0x65].pack('c'*6))
    serial_port.should_receive(:read).and_return([0x02, 0x40, 0xA4, 0x12].pack('c'*4))
    serial_port.should_receive(:read).and_return([0xA7, 0xB4, 0x00, 0x01, 0x0A,
      0x00, 0x69, 0x8D, 0x44, 0x51, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x1d].pack('c'*19))

    serial_port.should_receive(:close)
    serial_port.stub!(:closed?).and_return(false)
    subject.should_receive(:open_serial_port).and_return(serial_port)
    subject.should_receive(:boot)
    subject.should_receive(:boot_confirm)
    subject.should_receive(:lock_network)

    subject.open_session do |session|
      session.lock_network
      session.select_network(0xA7B4)
      session.request_samples(0xA7B4, 0x0001)
    end
  end

  it 'can enable a socket' do
    serial_port = mock("SerialPort")

    # Selecting the network
    serial_port.should_receive(:write).with([0x02, 0x40, 0x03, 0x04, 0xA7, 0xB4, 0x05, 0x00, 0x51].pack('c'*9))
    serial_port.should_receive(:read).and_return([0x02, 0x40, 0x03, 0x01, 0x00, 0x42].pack('c'*6))

    # Switching
    request = [0xff]*56
    request[5] = 0xA5
    request = [0x02, 0x40, 0x23, 0x3B, 0xA7, 0xB4, 0x00] + request + [0x11]
    serial_port.should_receive(:write).with(request.pack('c'*request.length))
    serial_port.should_receive(:read).and_return([0x02, 0x40, 0x23, 0x01, 0x00, 0x62].pack('c'*6))

    serial_port.should_receive(:close)
    serial_port.stub!(:closed?).and_return(false)
    subject.should_receive(:open_serial_port).and_return(serial_port)
    subject.should_receive(:boot)
    subject.should_receive(:boot_confirm)
    subject.should_receive(:lock_network)

    subject.open_session do |session|
      session.lock_network
      session.select_network(0xA7B4)
      session.switch(0xA7B4, 0x0000, true)
    end
  end
end
