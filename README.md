# Hacklet [![Build Status](https://travis-ci.org/mcolyer/hacklet.png)](https://travis-ci.org/mcolyer/hacklet)

A library, written in Ruby, for controlling the [Modlet][modlet] (smart) outlet.

If you haven't heard of the Modlet before, it's a smart outlet cover
which allows you to convert any outlet in your house into a smart
outlet. This means that you can control whether a plug is on or off and
you can also determine how much energy it's using with a sampling
frequency of 10 seconds.

There are alot of other similar products but this is the first one that
I've seen that [costs $50][amazon] and includes control as well as
monitoring of the independent sockets.

## Why

So why write another client?

Unfortunately the client software included with the device isn't
available on all platforms (Linux) and it's pretty heavyweight for what
it does.

The goal of this project is provide all the same functionality of the
bundled client but do it in a lightweight manner, to provide total
control and availability of the data.

## Getting Started

```shell
gem install hacklet

# Load the USB-to-serial kernel driver, this only works with Linux currently
sudo modprobe ftdi_sio vendor=0x0403 product=0x8c81

# Add the device to the network, keep a copy of the network ids (ie 0xDEED)
hacklet commission

# Get the samples from the top socket on the device registered as 0xDEED
hacklet read -n 0xDEED -s 0

# Turn the top socket off
hacklet off -n 0xDEED -s 0

# And back on again
hacklet on -n 0xDEED -s 0
```

## Status

* [X] Reading Data
* [X] Controlling Sockets
* [X] Multiple Modlet Support
* [X] Commissioning New Devices
* [X] Useful utility
* [ ] Documentation

[modlet]: http://themodlet.com
[amazon]: http://www.amazon.com/ThinkEco-TE1010-Modlet-Starter-White/dp/B00AAT43OA/