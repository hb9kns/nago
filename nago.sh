#!/bin/sh
VERID='nago.sh // 2010,2017-11-13 Yargo Bonetti // github.com/hb9kns/nago'

# external programs
## text pager
pager=${PAGER:-more}
pager=more
## html browser
browser=${BROWSER:-lynx -force_html}
## telnet client
telnet=${TELNET:-telnet}
## image handler
#imgviewer=display
imgviewer=echo # dumb handler: only print image name

# netcat/socat/snarf fetcher -- this *must* work, or nago is dead!
mync () {
# if port<1 (i.e, local file) or missing, then 'cat `cat`'
 if test ${2:-0} -lt 1
 then cat `cat`
 else
# uncomment one one of the following and comment the others,
# depending on what's available on your system
  ${NETCAT:-/usr/pkg/bin/netcat} "$@" || socat -t9 tcp4:$1:$2 -
#  read gf ; snarf "gopher://$1:$2/$gf" '-'
 fi
}

gopherport=70
## default home (-h option)
STDHOME=sdf.org/
## or use environment value, if defined
gopherhome=${GOPHER_HOME:-$STDHOME}
## default logfile (-l option)
gophermap="${GOPHER_MAP:-$HOME/.gophermap}"

# **modify further down only if you understand the code!**

# temporary files
tmpbase=${TEMP:-/tmp}
tmpprefix=`basename $0`tmp
dirtmp=$tmpbase/$tmpprefix.$$.dir
ftmp=$tmpbase/$tmpprefix.$$.tmp
stack=$tmpbase/$tmpprefix.$$.stack

if [ "$1" = "" ] ; then
 cat <<EOH
 usage: $0 [-l <logfile>] [-f [<file>]|-h|<server>] [<directory> <port>]
 where <server> is a server in gopherspace, <directory> a subdir on it,
  and <port> the port to connect to (default $gopherport)
  e.g: $0 sdf.lonestar.org /users/yargo
 -l <logfile> uses <logfile> for saving/displaying addresses (bookmarks)
   (default $gophermap, can be defined by GOPHER_MAP)
 -f <file> interprets <file> as gophermap for starting point
   (or logfile if empty)
 -h uses environment variable GOPHER_HOME as starting point
   (currently $GOPHER_HOME),
   or if that is empty, $STDHOME
   (only default port $gopherport is supported, and must be a directory)
  Note: will not work for retrieving a file directly! (undefined behaviour)
 ($VERID)
EOH
exit 1
fi


rmexit () { rm -f $dirtmp $ftmp $stack ; exit $1 ; }

# make sure temporary files are writable
rm -f $dirtmp $ftmp $stack
if ! echo test > $dirtmp ; then
 echo "** cannot write into temporary file $dirtmp - giving up!"
 rmexit 9
fi
if ! echo test > $ftmp ; then
 echo "** cannot write into temporary file $ftmp - giving up!"
 rmexit 9
fi
if ! echo test > $stack ; then
 echo "** cannot write into stack file $stack - giving up!"
 rmexit 9
fi

# default selector type: directory
s_typ=1

while test "$1" != ""
do case $1 in
-h)
# remove / and everything after
 s_ser=${gopherhome%%/*}
# remove first / and everything before, and prepend / again
 s_dir=/${gopherhome#*/}
 s_por=$gopherport
 ;;
-l) gophermap="${2:-$gophermap}" ; shift ;;
-f)
# use port=0 as flag for local file
 s_por=0
# and load file as directory (gophermap if empty)
 s_dir="${2:-$gophermap}"
 shift
 ;;
*)
 s_ser=$1
 s_dir=/$2
 s_por=${3:-$gopherport}
 if test "$1" != "" ; then shift ; fi
 if test "$1" != "" ; then shift ; fi
 ;;
esac
if test "$1" != "" ; then shift ; fi
done

echo "** starting at $s_ser:$s_por$s_dir"

# get a directory $s_dir from server $s_ser , port $s_por,
# preprocess it, and store it
getdir () {
# get directory
 if echo "$s_dir" | mync "$s_ser" "$s_por" | sed -e 's///g;/^.$/d' >$ftmp
 then
# line number counter
  ln=1
# add title = server directory, will also represent selectable line number
  echo "  0	1(HERE)	$s_dir	$s_ser	$s_por" >$dirtmp
# now process every line in turn
  cat $ftmp | { IFS='	'
   while read ft rest ; do
# if only filetype set, then no TAB is present, i.e comment line
   if test "$rest" = ""
# save comment for display, and set flag
   then ft="i$ft"
   fi
# test filetype=1st character
   case $ft in
# note: there are TABs in the following strings!
# i=fake, don't generate a number, but remove leading 'i' from type
   i*) echo ".	$ft	$rest" >>$dirtmp ;;
# otherwise it is an entry which may be selected: prepend number, increment
   *) echo "  $ln	$ft	$rest" >>$dirtmp ; ln=`expr $ln + 1` ;;
   esac
  done
  }
 else
# cannot get directory, error
  return 1
 fi
}

# definitions for actions:
ACT_quit=0
ACT_back=1
ACT_select=2
ACT_other=3
ACT_show=4
ACT_add=5
ACT_log=6

# show directory (in $dirtmp), and return selection type, dir, server, port
# and action in variables s_typ, s_dir, s_ser, s_por, s_act
selectdir () {
# take field 1&2 only, remove 1 char after first tab (filetype), store
# (note TABs in sed argument)
 cat $dirtmp | cut -f 1-2 |
  sed -e 's/	\(.\)\(.*\)/	\2 \/\1/;s/ \/[.i1]$//' >$ftmp
 ln=X
 act=$ACT_select
# repeat until legal linenumber given (note: 0 is legal!)
 while ! grep "^  $ln	" $dirtmp >/dev/null ; do
# show directory
  $pager $ftmp
  echo "** (s/a)N (show/addlog) selection, o.ther, l.og, x.it, q.uit"
  read inp
  case $inp in
# set action flag
  q*|x*) ln=0 ; act=$ACT_quit ;;
  o*) ln=0 ; act=$ACT_other
      echo "** other server? (empty=same)"
      read inp
      s_ser=${inp:-$s_ser}
      echo "** port? (empty=$gopherport)"
      read inp
      s_por=${inp:-$gopherport}
      echo "** directory? (may be empty)"
      read s_dir ;;
  b*) ln=0 ; act=$ACT_back ;;
  s*) ln=${inp#?} ; act=$ACT_show ;;
  a*) ln=${inp#?} ; act=$ACT_add ;;
  l*) ln=0 ; act=$ACT_log ;;
  *) ln=${inp:-0}
     if [ $ln = 0 ] ; then act=$ACT_back
     else act=$ACT_select
     fi ;;
  esac
 done
 s_act=$act
 case $s_act in
 $ACT_back|$ACT_other) s_typ=1 ;;
 $ACT_add) grep "^  $ln	" $dirtmp | sed -e 's/[^	]*	//' >> "$gophermap" ;;
 $ACT_log) s_dir="$gophermap" ; s_typ=1 ; s_por=0 ;;
 *) s_typ=`grep "^  $ln	" $dirtmp | cut -f 2 | sed -e 's/\(.\).*/\1/'`
    s_por=`grep "^  $ln	" $dirtmp | cut -f 5`
# if not enough fields, it's a top level address (server only)
    if [ "$s_por" = "" ] ; then
     s_dir=/
     s_ser=`grep "^  $ln	" $dirtmp | cut -f 3`
     s_por=`grep "^  $ln	" $dirtmp | cut -f 4`
# otherwise, directory is given as well
    else
     s_dir=`grep "^  $ln	" $dirtmp | cut -f 3`
     s_ser=`grep "^  $ln	" $dirtmp | cut -f 4`
    fi
    ;;
 esac
}

# save current point in stack
pushlevel () {
 echo "$s_ser	$s_por	$s_dir" >>$stack
}

# recall point from stack
poplevel () {
 s_ser=`tail -n 1 $stack | cut -f 1`
 s_por=`tail -n 1 $stack | cut -f 2`
 s_dir=`tail -n 1 $stack | cut -f 3`
 ln=`wc $stack | { read l dummy ; echo $l ; }`
 if [ $ln -gt 0 ] ; then
  ln=`expr $ln - 1`
  if head -n $ln $stack >$ftmp 2>/dev/null ; then cat $ftmp >$stack
  else :>$stack
  fi
 else
  echo "** no more data in history, quitting"
  rmexit 0
 fi
}

# main program

# initialize stack with first arguments, save some "spare"
rm -f $stack
pushlevel

s_act=X
while [ $s_act != $ACT_quit ] ; do
 pushlevel
 if getdir ; then selectdir
  case $s_act in
  $ACT_back) poplevel ; poplevel ;;
  $ACT_other) echo "** going to $s_ser : $s_por, fetching $s_dir" ;;
  $ACT_select) case $s_typ in
   1) echo "** changing to $s_dir" ;;
   8) echo "** telnetting..."
      $telnet $s_ser $s_por
      echo "** telnet finished, hit return to resume..."
      read inp
      poplevel
      ;;
   7) echo "** please enter request string:"
      read request
      s_dir="$s_dir?$request" 
      ;;
# otherwise download
   *) echo "** downloading $s_dir ..."
      if echo "$s_dir" | mync "$s_ser" "$s_por" >$ftmp
      then
       case $s_typ in
       0) $pager $ftmp ;;
       7) $pager $ftmp ;;
       g) $imgviewer $ftmp ;;
       h) $browser $ftmp ;;
       I) $imgviewer $ftmp ;;
       *) echo "** cannot display file type $s_typ, only save" ;;
       esac
       echo "** enter local filename to save (empty: no saving)"
       read inp
       while [ "$inp" != "" ] ; do
        if [ -f "$inp" ] ; then echo "** warning: $inp exists!"
        elif cat $ftmp >"$inp" ; then break
        else echo "** error: could not write file $inp!"
        echo "** enter local filename to save (empty: no saving)"
        fi
       read inp
       done
      else echo "** cannot download $s_dir!"
      fi
      poplevel
   esac ;;
  $ACT_quit) echo "** bye!" ;;
  $ACT_show) echo "**     gopher://$s_ser:$s_por/$s_typ$s_dir"
    echo '**  (ENTER to resume)' ; read inp ; poplevel ;;
  $ACT_add) poplevel ; echo '** added:' ; tail -n 1 "$gophermap" ; sleep 1 ;;
  $ACT_log) echo "** switching to logfile $gophermap" ; sleep 1 ;;
  *) echo "** unrecognized command, internal error! trying to go on..."
     poplevel ;;
  esac
 else
  echo "** error getting $s_dir from $s_ser:$s_por!"
  poplevel ; poplevel
 fi
done
rmexit 0
