
0.6.0 / 2013-06-18
==================

 * Add Cross-platform support by switching to libftdi-ruby from serialport.
 * API Change: Hacklet::Dongle.open is now used to create a session
   instead of #open_session.
 * Refactor dongle communication functions into SerialConnection for
   clarity.

0.5.1 / 2013-06-02
==================

 * Bugfix: Properly sets the time on the device after commissioning.

0.5.0 / 2013-05-30
==================

 * Can commission new modlets, read data from them and control them
   through a simple utility program. This is the minimal required in
   order to be useful.
