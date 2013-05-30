require 'spec_helper'

describe Hacklet::Command do
  subject do
    Hacklet::Command
  end

  let(:dongle) { Hacklet::Dongle.new(Logger.new("/dev/null")) }

  it 'can turn on a socket' do
    serial_port = mock('serial_port')
    serial_port.should_receive(:close)

    dongle.should_receive(:open_serial_port).and_return(serial_port)
    dongle.should_receive(:boot)
    dongle.should_receive(:boot_confirm)
    dongle.should_receive(:lock_network)
    dongle.should_receive(:select_network).with(16)
    dongle.should_receive(:switch).with(16, 1, true)

    subject.run(dongle, ['on', '-n', '0x0010', '-s', '1'])
  end

  it 'can turn off a socket' do
    serial_port = mock('serial_port')
    serial_port.should_receive(:close)

    dongle.should_receive(:open_serial_port).and_return(serial_port)
    dongle.should_receive(:boot)
    dongle.should_receive(:boot_confirm)
    dongle.should_receive(:lock_network)
    dongle.should_receive(:select_network).with(16)
    dongle.should_receive(:switch).with(16, 0, false)

    subject.run(dongle, ['off', '-n', '0x0010', '-s', '0'])
  end

  it 'can read a socket' do
    serial_port = mock('serial_port')
    serial_port.stub(:closed?).and_return(false)
    serial_port.should_receive(:close)

    dongle.should_receive(:open_serial_port).and_return(serial_port)
    dongle.should_receive(:boot)
    dongle.should_receive(:boot_confirm)
    dongle.should_receive(:lock_network)
    dongle.should_receive(:select_network).with(16)
    dongle.should_receive(:request_samples).with(16, 1)

    subject.run(dongle, ['read', '-n', '0x0010', '-s', '1'])
  end

  it 'can commission a device' do
    serial_port = mock('serial_port')
    serial_port.stub(:closed?).and_return(false)
    serial_port.should_receive(:close)

    dongle.should_receive(:open_serial_port).and_return(serial_port)
    dongle.should_receive(:boot)
    dongle.should_receive(:boot_confirm)
    dongle.should_receive(:commission)

    subject.run(dongle, ['commission'])
  end
end
