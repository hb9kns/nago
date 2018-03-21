# nago.sh : nano-gopher client

`nago.sh` is a small shell script working as a command-line [Gopher][] client.

It makes use of command line tools part of standard Unix systems,
and is a somewhat ugly hack I wrote as a personal exercise.  However,
so far I have not yet encountered a Gopher server where it did not
work. If it fails somewhere, please report server and selector!

## usage

run `nago.sh` without arguments to get a short help:

    usage: nago [-l <logfile>] [-f <file>|-h|<server>] [<directory> <port>]
    where <server> is a server in gopherspace, <directory> a subdir on it,
     and <port> the port to connect to (default 70)
     e.g: /home/yargo/bin/nago sdf.lonestar.org /users/yargo
    -l <logfile> uses <logfile> for saving/displaying addresses (bookmarks)
      (default .gophermap, can be defined by GOPHER_MAP)
    -f <file> interprets <file> as gophermap for starting point
      (of logfile if empty)
    -h uses environment variable GOPHER_HOME as starting point
      (currently sdf.org/users/yargo),
      or if that is empty, sdf.lonestar.org/
      (only default port 70 is supported, and must be a directory)
     Note: will not work for retrieving a file directly! (undefined behaviour)
    (nago.sh // 2010,2017-10-11 Yargo Bonetti // github.com/hb9kns/nago)

To read a local gophermap file, specify it after the `-f` option;
`-f` alone will start with the logfile.
You may use this in the sense of a bookmarks file.

`-l` allows to specify a logfile. If an empty name is given,
`$HOME/.gophermap` or the value of `GOPHER_MAP` will be used.

If you want to set the '-h' starting point, you should set `GOPHER_HOME` to
a value like `gopher.floodgap.com/world` -- please note this "home" does not
permit any other port than 70.

If `-h` or server+directory are given, the script will fetch that page,
display it (with the use of `more` or `less`) and wait for commands.

If the page is a document, the script will permit to locally save it,
then return to the directory above it. If the page is a directory, the
script will offer the following command possibilities:

- enter line number: select the corresponding document (either for
  display and download in case of file, or further selection in case
  of directory); 0 or b (for back) return to the previous directory
- prepend a line number with `s` : show gopher URL for that line
- prepend a line number with `a` : add that line to the gophermap
- open other selector (server, port, directory)
- open gophermap
- exit script

Entering an empty command is the same as entering 0 or b, i.e back;
if there is no previous directory in the history, the script will quit.

## configuration

At the beginning of the script, handlers for various selector types must
be defined, as well as the program to fetch gopher data.

The contents of environment variable NETCAT will be used as netcat
if set, otherwise the script searches for `netcat, nc, socat.` If
all fail, it will assume `snarf` is available, and if that does
not work, the script will fail in a not very glorious way.

*If you implement another fetcher, I would love to hear about your solution!*

The script uses `TMPDIR` for temporary files, `/tmp` otherwise.

---

_(2010,2018-March, Y.Bonetti)_

[Gopher]: https://en.wikipedia.org/wiki/Gopher_(protocol) "Gopher protocol"
