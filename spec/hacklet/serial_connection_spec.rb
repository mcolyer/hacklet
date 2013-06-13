require 'spec_helper'

describe Hacklet::SerialConnection do
  subject { Hacklet::SerialConnection.new(Logger.new('/dev/null')) }

  describe 'initialization' do
    it 'creates a serial port with no flow control' do
      serial_port = double('Context')
      serial_port.stub(:usb_open).with(0x0403, 0x8c81)
      serial_port.stub(:set_bitmode).with(0x00, Ftdi::BitbangMode[:reset])
      serial_port.stub(:baudrate=).with(115200)
      serial_port.stub(:flowctrl=).with(Ftdi::SIO_DISABLE_FLOW_CTRL)
      serial_port.stub(:dtr=).with(1)

      Ftdi::Context.should_receive(:new).and_return(serial_port)
      subject
    end
  end

  describe 'transmitting' do
    subject { Hacklet::SerialConnection.new(Logger.new('/dev/null')) }

    it 'is successful' do
      serial_port = double('Context').as_null_object
      serial_port.should_receive(:write_data).with([0x02, 0x40, 0x04, 0x00, 0x44].pack('c*'))

      Ftdi::Context.should_receive(:new).and_return(serial_port)
      subject.transmit(Hacklet::BootRequest.new)
    end
  end

  describe 'receiving' do
    subject { Hacklet::SerialConnection.new(Logger.new('/dev/null')) }

    it 'is successful' do
      serial_port = double('Context').as_null_object
      serial_port.should_receive(:read_data).and_return("\x02")

      Ftdi::Context.should_receive(:new).and_return(serial_port)
      subject.receive(1).should eq("\x02")
    end
  end
end
