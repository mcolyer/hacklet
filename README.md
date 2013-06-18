# Hacklet [![Build Status](https://travis-ci.org/mcolyer/hacklet.png)](https://travis-ci.org/mcolyer/hacklet)

A library, written in Ruby, for controlling the [Modlet][modlet] (smart) outlet.

If you haven't heard of the Modlet before, it's an outlet cover which
allows you to convert any standard US outlet into a smart outlet. This
means that you can control whether each socket is on or off as well as
determine how much energy it's using with a sampling frequency of 10
seconds.

There are alot of other similar products but this is the first one that
I've seen that [costs $50][amazon] and includes control as well as
monitoring of both sockets independently.

Checkout the companion project [hacklet-remote] if you're interested in
controlling your modlet with [IFTTT].

## Why

So why write another client?

Unfortunately the client software included with the device isn't
available on all platforms (Linux) and it's pretty heavyweight for what
it does.

The goal of this project is provide all the same functionality of the
bundled client but in a lightweight manner without dependencies on
external services.

## Installation

### Mac

```shell
brew install libftdi
gem install hacklet
```

### Linux (Ubuntu/Debian)

```shell
apt-get install libftdi1
gem install hacklet
echo 'ATTRS{idVendor}=="0403", ATTRS{idProduct}=="8c81", SUBSYSTEMS=="usb", ACTION=="add", MODE="0660", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/99-thinkeco.rules
```

### Windows

**Note**: These directions haven't been confirmed. If you can confirm
them or improve them, please create an [issue][issues] or send a pull request.

1. Install [7zip] in order to extract Zadiag.
1. Download Zadig for [XP][zadiag-xp] or [later][zadiag-later].
1. Extract Zadig and run it.
1. Click `Options` -> `List all Devices` to populate the device list.
1. Open the device dropdown and look for the "Thinkeco" device and select it.
1. Select the libusbK driver and press the `Replace Driver` button.
1. Download and unzip [libftdi][libftdi-win]
1. Run `gem install hacklet`

If something isn't clear here, take a look at [libFTDI under Windows][libftdi-win-post] as this was summarized from there.

## Getting Started

```shell
# Add the device to the network, keep a copy of the network ids (ie 0xDEED)
hacklet commission

# Get the samples from the top socket on the device registered as 0xDEED
hacklet read -n 0xDEED -s 0

# Turn the top socket off
hacklet off -n 0xDEED -s 0

# And back on again
hacklet on -n 0xDEED -s 0
```

## Contributing

All contributions are welcome (bug reports, bug fixes, documentation or
new features)! All discussion happens using [issues] so if you are
interested in contributing:

* Search to make sure an issue doesn't already exist.
* If it doesn't, create a new issue and describe your proposal.

If you're interested in following the status of the project, simply
"watch" the repository on Github and you'll receive notices about all of
the new issues.

If your curious about how the hardware works or the specifics of the
protocol checkout out the [developer wiki].

### Contribution Workflow

* Fork the repository
* Install dependencies `bundle install`
* Create a feature branch `git checkout -b short-descriptive-name`
* Run tests `bundle exec rake`
* Write your feature (and tests)
* Run tests `bundle exec rake`
* Create a pull request

[modlet]: http://themodlet.com
[amazon]: http://www.amazon.com/gp/product/B00AAT43OA/ref=as_li_qf_sp_asin_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B00AAT43OA&linkCode=as2&tag=matcol-20
[issues]: https://github.com/mcolyer/hacklet/issues
[developer wiki]: https://github.com/mcolyer/hacklet/wiki
[hacklet-remote]: https://github.com/mcolyer/hacklet-remote/
[IFTTT]: http://ifttt.com
[7zip]: http://www.7-zip.org/
[libftdi-win]: http://code.google.com/p/picusb/downloads/detail?name=libftdi1-1.0_devkit_mingw32_17Feb2013.zip
[zadiag-xp]: http://sourceforge.net/projects/libwdi/files/zadig/zadig_xp_v2.0.1.160.7z/download
[zadiag-later]: http://sourceforge.net/projects/libwdi/files/zadig/zadig_v2.0.1.160.7z/download
[libftdi-win-post]: http://embedded-funk.blogspot.com/2013/03/libftdi-under-windows.html
