GABELLA TB
==========

This is not a functional verification testbench. Just a wrapper to simulate
top level design without any external drive except main clock to see does it has
any unconnected / x-state stuff, see some warnings we might overlook in
synthesis reports. Maybe monitor initializing process but no real audio
processing because it takes ~3 min to simulate only one second on my work laptop.
Thus verifying audio processing modules should be performed individually for
each module. It's not a problem since they're mutually independet in general

LICENSE
=======

MIT

AUTHORS
=======

 -- Dmitry Nekrasov <bluebag@yandex.ru>  Sat, 09 Mar 2024 15:55:13 +0300
