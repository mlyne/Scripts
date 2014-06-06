-------------------------------------------------------------------------------
Filename Path, Basename, and Suffix

  file="/path/to/the/file.sfx"

  Extract Path  (NOTE: may be empty)
    path="`expr "$file" : '\(.*\)/'`"
    : ${path:=.}

  Remove Path (basename alternative)
    basename="`expr "//$file" : '.*/\([^/]*\)'`"

  Get Suffix  (path kept if present)
    suffix="`expr "$file" : '.*\.\([^./]*\)$'`"

  Remove Suffix   (path kept if present)
    name="`expr "$file" : '\(.*\)\.[^./]*$' \| "$file"`"


Example, this is a favourite file processing loop of mine
(path is often omitted as it is not used)

  for i in "$@" ; do
    [ ! -r "$i" ] && { echo "No such file \"$i\""; continue; }
    path="`expr "$i" : '\(.*\)/'`"                  # get file path (if any)
    name="`expr "//$i" : '.*/\([^/]*\)'`"           # remove path to file
    suffix="`expr "$name" : '.*\.\([^./]*\)$'`"     # extract last suffix
    name="`expr "$name" : '\(.*\)\.[^.]*$'`"        # remove last suffix
    : ${path:=.}
    ...
  done

-------------------------------------------------------------------------------
Creating a specific size file
   EG: to create a 8Mbyte byte file

      dd if=/dev/zero of=/export/swap/XXX bs=8k count=1024

-------------------------------------------------------------------------------
Read `n' BINARY characters from file or tty
    n=10
    input=`dd if=/dev/tty bs=1 count=$n 2>/dev/null`

Good to read single characetrs from stdin in "raw" mode.. See below...

-------------------------------------------------------------------------------
generate 'n' numbers one per line
   n=10
   dd 2>/dev/null if=/dev/zero bs=$n count=1 | tr \\0 \\012 |
      cat -n | tr -d ' \11'

get $n null characters, translate to newlines, use cat to number the lines
and then remove extra spaces adn tabs added by the cat.

Alturnative
    perl -le 'for(1..10){print}'

See also "columnize ouput" in "script.hints"

-------------------------------------------------------------------------------
Generating file sequences...

Count loop..

  num=0
  while [ $num -lt 999 ]; do
    num=`expr $num + 1`
    num=`printf %03d $num`

    # do whatever and save to next sequence file
    touch file_$num.suffix
  done


The next file..
This will continue to generate files in sequence even if gaps are present in
the previously generated files.

  while :; do

    # determine the checkpoint number for next checkpoint image to generate
    num=`ls file_*.suffix 2>/dev/null | tail -1 | sed 's/[^0-9]//g'`
    [ ! "$num" ] && num=0  # start with number 1 if no previous file found
    num=`expr $num + 1`
    num=`printf %03d $num`

    # do whatever and save to next sequence file
    touch file_$num.suffix
  done

-------------------------------------------------------------------------------
Turn off input echo

   /bin/stty cbreak -echo </dev/tty >/dev/tty 2>&1
   read password
   /bin/stty -cbreak echo </dev/tty >/dev/tty 2>&1

-------------------------------------------------------------------------------
Read a single character (keypress) 

if [ -f /vmunix ]; then  # is this a BSD system?
  key_wait() {
    echo -n "Enter a character: "                  # prompt
    /bin/stty cbreak -echo </dev/tty >/dev/tty 2>&1
    key=`dd if=/dev/tty bs=1 count=1 2>/dev/null`  # read a key press
    /bin/stty -cbreak echo </dev/tty >/dev/tty 2>&1
    echo "$key"    # echo newline and/or key -- OPTIONAL
  }
else 
   key_wait() {
    echo -n "Enter a character: "                  # prompt
    /bin/stty -icanon && /bin/stty eol ^A
    key=`dd if=/dev/tty bs=1 count=1 2>/dev/null`  # read a key press
    /bin/stty icanon && /bin/stty eol ^@
    echo "$key"    # echo newline and/or key -- OPTIONAL
  }
fi

key=`key_wait`
echo "Thank you for typing a $key ."

-------------------------------------------------------------------------------
Bourne Shell    open file,  read,  close

exec 5<&0 0<some_file    # save stdin, open file as stdin
read line1      # first line
read line2      # second line
read line3      # one more line
exec -<&0 0<&5 5<&-    # close file, reset stdin

echo "1: $line1"
echo "2: $line2"
echo "3: $line3"

-------------------------------------------------------------------------------
Read from Stdin with a Timeout

    # read with 4 second timeout
    stty raw
    stty min 0 time 40
    read input
    stty -raw
    echo $var

Timed version (ksh?)

    : #Dan Mercer: damercer@mmm.com
    wake_up() {
        echo "Morning already"
    }
    trap wake_up USR1
    (sleep 20;kill -usr1 $$) &
    echo "Waiting for answer..."
    read ans
    echo "Here we are"

-------------------------------------------------------------------------------
How do I get a particular line or range of lines from a file?

Using absolute Line numbers use
   front end         head -<number> file
   tail end          tail +<number> file
   single line       sed -n '<number>p;<number>q' file
   range of lines    sed -n '<from>,<to>p;<to>q' file

   NOTE: The `q' in the sed commands above is to avoid uneeded computer
   cycles, similarly for the exit in the nawk script below. Sed could also
   replace the head and tail commands, in a similar fashion, but is slower.

The problem with the above is if you want the lines relative to both
the start and the end of the file at the same time. "Sed" is a stream
editor but if you are dealing with a REAL file and not a pipe you can
also use "ed"

   All lines but last 15 lines     echo '1,$-15 p'   | ed -s file
   The 10th to the 5th last line   echo '$-10,$-5 p' | ed -s file


A random line from a file however has fewer simple solutions, without having
to calculate the line number (and needing the number of lines in the file)
before hand. (See ``random.hints'').  WARNING the following does not work

   nawk ' BEGIN      {srand(); RNUM = int(LNUM * rand())+1} 
          NR == RNUM {print $0;  exit 0}
        ' LNUM=`wc -l < file`  file

    problems RNUM = 0 = no output,
             RNUM = 1 = first line,
             RNUM = LNUM-1 = 2rd last line
             RNUM = LNUM = NO OUTPUT      <--- The problem

-------------------------------------------------------------------------------
Subtract lines in one file from another

Situation: you have a master list "master" and you want to remove a list of
entries "list" from that master list...

  cat master list list | sort | uniq -u > new_master

An alturnative I usally use is to use comm

  sort -o master master
  sort -o list list
  comm -23 master list > new_master

Of course you can also get the items not in the master, and those in BOTH
files (the union) with this method to (just different comm options). 

-------------------------------------------------------------------------------
Reverse the lines in a file
  1/ My first idea was to put some line numbers in front of infile
     (e.g. using 'pr' oder 'nl' or the like), than sorting using
     `| sort -r -n +0 -1 |' and removing the line numbers afterwards
     (e.g. with `sed').  Seems to be a little bit awkward...
                               --- Peter Funk  pf@artcom0.north.de
  2/ Awk it
     awk '{x[NR]=$0}END{for(i=NR;i>0;i--){print x[i]}}' infile >outfile
     NOTE: this will barf of extreamly large files. sort works on large files
                               --- dsilvia@blunt.net.com   Dave S.
  3/ A GNU text utility `tac' the reverse of cat!
                               --- Noah Friedman   friedman@gnu.ai.mit.edu
  4/ a ed solution (twice as fast as the above awk solution)
       ed - infile <<-EOF
              g/^/m0
              w
              EOF
     NOTE: this will gag on long lines instead of long files

  5/ the perl solution is very simple!
        perl -e "print reverse <>"
 
-------------------------------------------------------------------------------
Lock File (file creation)
Methods for lockfiles
  
  File Permission  ( file mode = 000 )
      Create a lockfile with zero permission.
	The example below uses this method in shell. It creates the
      lockfile and places the current pid of the process in it. NOTE a
      trap should be provided to remove the lock file on any abnormal exit
      by the program running this.
      WARNING: this technique does not work for ROOT which will always
      succeed to create the file even if it exists.

       Lockfile() {         # create a lockfile with the process ID in it
         masksave=`umask`; umask 777
         ( echo $$ > $1 ) 2>/dev/null; success=$?
         while  [ $success -ne 0 ];  do
           sleep 2
           ( echo $$ > $1 ) 2>/dev/null; success=$?
         done
         umask $masksave
       }

   Exclusive Open
      This requires the open(2) command to use the O_CREAT & O_EXCL
      flags to ensure that a file is opens if it had to be created.
      The csh `noclobber' flag should do this (Look at source).
      NOTE: This does NOT work over NFS (unless version 3 release)

   Hard Links to a file `ln'
       This works for root but on System V the `ln' command removes
       any file that the link is created for (ala `mv' ) as such
       on System V this fails for both users and root.
       This is the method normally used for passwd file locking.
       NOTE: This method is known to work over NFS

   Symbolic Links `ln -s'
       It is not known if this has the same problem on System V or if
       this is atomic over NFS.

   lock directory instead of a file `mkdir'
       This should work properly in all cases but is unknown if this
       is atomic over NFS.

  NOTE: The lockfile often contains the process-ID of the  process locking
  the file. When the program notices that a file has a lock, it can then
  check to see if the other process still exists (using a kill 0 and looking
  at the return code and errno).  This implementation fails miserably with
  NFS-mounted files, because they could easily be lock by a process on a
  remote machine.  This is a fairly brain-dead locking mechanism which was
  fine when everyone worked on a single vax without networked file systems,
  but is now obviously inadequate. Still it works for many situations.

  Alternitivly a scheme in checking the lockfile creation date is possible.

  For more locking info please see C/C.hints

-------------------------------------------------------------------------------
To match all files in a directory (required 3 pattern matches)
  .[^.] .??* *
    ^This may be a ! n some shells, or in real ancheit shells (sh on ultrix)
    no `not' function may not be provided for shell regex.

-------------------------------------------------------------------------------
Is a directory empty?

  # Anthony Thyssen -- my own solution - simple and obvious to script reader
  if [ -z "`ls -A $dir`" ];              # then empty

  # Jim Rogers -- 28790008@hplsdv7.hp.com   (compressed)
  if [ `ls -a $dir | wc -l` -eq 2 ];     # then  empty

  # S.Kondakci -- jpc.694747676@avdms8.msfc.nasa.gov
  if ls -a $dir | grep 'total 0';        # then empty
  # modified by Stan Ryckman -- sgr@alden.UUCP
  if ls -l $dir | fgrep -x 'total 0';    # then empty

  # David W. Tamkin -- dattier@gagme.chi.il.us
  if [ ". .. * ?" = "`echo .* * ?`" ]    # then empty

  # Maarten Litmaath -- maart@paramount.nikhefk.nikhef.nl  (built-in cmds only)
  DirEmpty() {    # if directory empty -- built in cmds only used
    cd "${1-.}"
    set .* ? *
    case $#$3$4 in
      4\?\*) exit 0
    esac
    exit 1
  }

-------------------------------------------------------------------------------
Read/Delete file (protect the source)

  for i in file1 file2 file3 ... fileN
  do
     (rm -f - "$i"; cat) < $i
  done | ...{pipeline}...

Can also be used to write to the same filename (different Inode).
Just replace cat with your modify data function

  (rm -f file; cat - > file) < file

WARNING: the above could go really wrong, particularly on user interupt.
I do not recomend it in anything but temporary files.

-------------------------------------------------------------------------------
Is one file newer than another

ls:
   newer() {        # is file 1 newer than all others given
      [ `ls -1rtd "$@" | tail -1` = "$1" ]
   }
   older() {        # is file 1 older than all others given
      [ `ls -1td "$@" | tail -1` = "$1" ]
   }
   # NOTE: the use of -r ensudes that ls is forced to reorder the files
   # to produce a true result. This ensures that if the files are the
   # same age (in which case ls don't bother re-ording) the result is always
   # false.

find:
   newer () {        # is file 1 newer than file 2
       [ "`find . -name $1 -newer $2 ! -type d -print`" ]
   }

make:
   # Rich Salz --- rsalz@bbn.com
   newer () {        # is file 1 newer than file 2
     echo "$1 : $2 ; @/bin/false" >/tmp/x$$
     make -qf /tmp/x$$; status=$?
     rm -f /tmp/x$$
     exit $status
   }

bash:
   if [ "$file1" -nt "$file2" ]

perl:
   if (-M $file1 < -M $file2)

ksh:
   if [[ "$file1" -nt "$file2" ]]

multiple find:           *
   # multiple file test  
   # Alex P. Ugolini, Jr. ---  ugolinia@mr.med.ge.com
   newlist=`find file1 file2 file3 file4 -newer filen -print`

multiple ls:
 This is the best solution. ls can list a large collection of files
 in the right order. You can then if you want sed for newer or older files
 than a known filename (present or not)
   # Tom Christiansen ---  tchrist@convex.COM 
   set `ls -td file1 file2`
   echo $1 is newer

NOTE: the find, and ls solutions could result in all the files in a
directory being stat'ed, so caution is required if dealing with VERY large
directories.

-------------------------------------------------------------------------------
Complex Find Commands...

Adding a suffix to a filename found
EG:   find /path -type f -exec command {}.suffix \;
doesn't work as find only expands the "{}" token and doesn't recognise
"{}.suffix". Solutions :-

shell argument to command
  find /path -type f -exec sh -c 'command $0.suffix' {} \;

construct a command with sed
  find /path -type d -print | sed 's:.*:command &.suffix:' | sh

cut down on number of commands (does not solve the problem though)
  find /path -print | xargs command

The Sed solution is probably the most versital as the `&' can be output
multiple times, and you can do suffix (or other string) matches.

Note that most finds do not require a -print is no -ls or -exec is used.
that is this is perfectly acceptable...
    find /path -type f | xargs command

NOTE on find-grep    grep will NOT outout a filename if less than one
argument is provided. as such it is a good idea in a find-xargs-grep
that a extra /dev/null be put on the grep command line...
   find /path -name "*.txt" | xargs grep "string" /dev/null

-------------------------------------------------------------------------------
find -older option
to make a
     find . -older testfile -print
do the following
     find . \( ! -newer testfile -a ! -name testfile \) -print

BUG: on the rare instance of two files being the same age this will fail

-------------------------------------------------------------------------------
List complete modification time of file (to the second) (without C)

EG: the "ls" command fails for files older than 6 months
:::::> ls -l oldfile
-rwxr-xr-x  1 root       106496 Oct 11  1990 oldfile

TAR
   :::> tar cf - oldfile | tar tvf -
   rwxr-xr-x  0/10 106496 Oct 11 12:51 1990 oldfile

CPIO
   :::> echo oldfile | cpio -oac | cpio -ictv
   209 blocks
   100755 root   106496  Oct 11 12:51:48 1990  oldfile
   209 blocks

PERL  ***
   :::> perl -e 'require "ctime.pl"; print &ctime((stat(shift))[9]),"\n";' \
            oldfile

NOTE: both cpio and tar methods will read the whole file -- which can be slow
The best method is the perl one if you have it which does a real file stat()

-------------------------------------------------------------------------------
Compare log files.

New log file matches the old log file but may have extra lines at the end
of the file only.   status = 0 if this is the case.
NOTE: This test does not check if the files are reversed! IE: the files
match but it is the old one that is longer instead of the new log file.

if    comm -3 $new $old | cat $old - | cmp -s - $new;  then
  mv $new $old             # replace old log with new log
elif  comm -3 $old $new | cat $new - | cmp -s - $old;  then
  :                        # ignore new file as it matches but is shorter
else
  echo error               # old and new log files do not match at all
fi

-------------------------------------------------------------------------------
Read from a pipeline via a file!

Some commands can only read information from a file and not a pipeline
like standrad input.  IE: the data can't be read from another command
directly.


On linux your can force a command to read standard input, by reading from
the /dev/fd0 device...

    command | read_from /dev/fd/0


But a more generic solution (works on more machines) also exists...

Use a named pipe!

    mknod pipe p
    command > pipe &
    read_from pipe

I do this all the time to pre-process files for commands which does not
accept standard input (or doing so has disadvantages).

For Example.

  * Sun pkgadd will not take standard input so I use a named pipe to allow
    me to de-compress a gziped pkg package into the pkgadd command without
    needing to decompress the stored package itself.

  * SGI xfsrestore must read from a file (or device), if you want to still
    control it interactivally (EG; stdin is still needed!).  However that
    command can't properly read from a remote sun tape drive (rmt command
    incompatiblity).  

    Solution was read the tape though a network pipe manually using `dd'
    into a named pipe (file could be too big to save to a temporary file).
    Then get xfsretore read from that named pipe.

    mknod /tmp/pipe p
    ssh -n -x TAPE_HOST  dd ibs=10k if=/dev/rmt/0hn > /tmp/pipe &
    xfsrestore -i -f /tmp/pipe .


On Bash named pipes or /dev/fd? usage is built into the shell.

    read_from <(command)

or for writing to the file
 
    write_to >(command)

The `pipe' argument is substituted with the appropriate named pipe or
/dev/fd?  device name for the system being used.

-------------------------------------------------------------------------------
Program output -- line by line, as printed, or in large blocks

If a program is `expecting' a particular output (like a prompt) from a
command before sending the next command to that same program, the output
string may never be recieved as it is buffered forever (as the buffer is
never full!). This results in a Deadlock for interactive program control.

The buffering is due to the interaction of different programs and the stdio
library.

If a program uses low-level writes, the output will be blocked in the
system writes, as such partical lines or whole paragraphs can be the
case. Network Packets are preformed in this way.

The same thing will happen if a program turns off or removes the standard
IO libraries buffering mechnisim (using setbuf, or setvbuf).

However if a program uses the high level stdio library routines for
writing (putchar, printf, etc..) the stdio library will buffer the
output until it is flushed (written with a low-level write).

This will be done when :
  1/  The program does a forced flush.
      This includes, if program: turns off buffering, or opened file in
      append mode.
  2/  If output is to a tty (or pty), when end of line is reached
  3/  Otherwise when the buffer is full.

This buffering causes many of the problems with deadlocks in a programs
interactive (both input and output) control of another program.  See
``interactive.hints''.

Solution..

  * A program such as  ``pty''  (ask archie) can force programs to think it
    is talking to a tty when it in fact isn't.  What this program does is
    run the command in a psuedo-tty but this you don't have to worry about.

    In particular the pty package provides a script called (don't ask)
    ``condom'' which accepts a command and runs that command as if it was
    talking to a tty, regardless of the piping arrangements around it.

  * Expect (and derivatives) also launches the command in its own pty for
    that same reason.

-------------------------------------------------------------------------------
