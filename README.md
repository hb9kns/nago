# nago.sh : nano-gopher client

`nago.sh` is a small shell script working as a command-line [Gopher][] client.

It makes use of command line tools part of standard Unix systems,
and is a somewhat ugly hack I wrote as a personal exercise.  However,
so far I have not yet encountered a Gopher server where it did not
work! If it fails somewhere, please report server and selector!

## usage

run `nago.sh` without arguments to get a short help

## configuration

At the beginning of the script, handlers for various selector types must
be defined, as well as the program to fetch gopher data (netcat/socat/snarf
for example).

Several versions are available, all but one commented out; please uncomment
a tool available on your system, and comment/remove the others.
In the netcat version, the environment variable NETCAT will be used if set.
*If you implement another type, I would love to hear about your solution!*

---

_(2010,2017 Y.Bonetti)_

[Gopher]: https://en.wikipedia.org/wiki/Gopher_(protocol) "Gopher protocol"
