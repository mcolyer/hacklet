# Hacklet

A daemon, written in ruby, for controlling the [Modlet] (smart) outlet.

If you haven't heard of the modlet before, it's a smart outlet cover
which allows you to convert any outlet into your house into a smart
outlet. This means that you can control whether a plug is on or off and
you can also determine how much energy it's using.

There are alot of other similar products but this is the first one that
I've see that costs $50 and includes control as well as monitoring of
the independent sockets.

## Why

So why write another client?

Unfortuantely the client software included with the device isn't
available on all platforms (Linux) and it's pretty heavyweight for what
it does.

The goal of this project is provide all the same functionality of the
bundled client but do it in a lightweight manner, to provide total
control and availability of the data.

## Status

Currently it only supports reading data from configured clients. So
you'll need to setup the modlets using the bundled software but once
configured into a network you can use hacklet to monitor their data and
analyze it as you choose.

## TODO
* Implement reading data from modlets
* Research/implement pairing process for new modlets
* Research/implement controlling outlets

[Modlet]: http://themodlet.com
