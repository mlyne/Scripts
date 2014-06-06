du -sh `ls -1a | grep "^\."`
shows the size of all directories beginning with `.'
--------------------------------------------------------------------------------
fuser -v /dev/tty7
fuser -v `which mc`
fuser -v `which pico`
fuser -v named/udp
fuser -v 113/tcp
fuser -kv /dev/tty7
fuser -kv /home/baaad
--------------------------------------------------------------------------------
cd -
cd will take you back to your previous directory.
--------------------------------------------------------------------------------
C-k  Kill the text from point to the end of the line.
C-u  Kill backward from point to the beginning of the line.
M-d  Kill  from  point  to  the end of the current word, or 
     if between words, to the end of the next word.
M-Backspace  Kill the word behind point.
some of the key combinations I use at most
--------------------------------------------------------------------------------
See the output of a command and log it to a file simultaneously by
using the tee command.
$ ls | tee logfile.txt
--------------------------------------------------------------------------------
To get the size of all directories in the current directory:
find . -maxdepth 1 -type d -print | xargs du -sk | sort -rn
--------------------------------------------------------------------------------
find ./ -type f -follow|xargs grep -i beautify
ever seen the "bash: /usr/bin/grep: Argument list too long" message? 
I get it often while greppin' in /usr/include or something..
well, this is a workaround.
Another posibility is:
find ./ -type f -follow -exec grep -i beautify {} \;
--------------------------------------------------------------------------------
ldconfig -p
find out which libraries are visible to the dynamic linker
--------------------------------------------------------------------------------
     fprintf (stderr, "can't open `%s': %m\n", filename);
is equivalent to:
     fprintf (stderr, "can't open `%s': %s\n", filename, strerror (errno));
The `%m' conversion is a GNU C library extension. (read: not portable :)
--------------------------------------------------------------------------------
man 4 console_codes
if you want to play with the terminal capabilities (echo '\033[XX' yeah!)
--------------------------------------------------------------------------------
awk '$2=="loop" {print $1}' /proc/devices
greps for the string loop on second place and prints the string before it
--------------------------------------------------------------------------------
ever got a console with some funky nonreadable characters on it? (cat /bin/binary :) well,
CTRL+N (0x0E, ^N) activates the G1 character set, which is made up of graphic symbols and
thus isn't a friendly font for typing input to your shell; if you encounter
this problem, echo a CTRL+O (0x0F, ^O) - it activates the G0 character set.
NOTE: echo = CTRL+V (which is actually the escape character, 033 octal, 1B hex, 27 dec)
if you want to know more - man 7 charsets, man 4 console_codes
--------------------------------------------------------------------------------
ever wanted to use a TAB as a delimiter with `cut'? well, here is how:
cat /proc/bus/pci/devices|cut -d"       "  -f1,3,6
where for the -d opt use CTRL+V TAB
--------------------------------------------------------------------------------
wanna see the digits from 0 to 100 in binary? :)
echo "obase=2; i=0; while(i<=100) {print i; print \"\n\"; i += 1;}" | bc -l
--------------------------------------------------------------------------------
convert to lowercase
#define LCASE(c)        (char)( c | 0x20 )
--------------------------------------------------------------------------------
wanna reformat a formated input?
grep "Mem:" meminfo| cut -f2- -d" " | xargs printf "%d | %d | %d | %d | %d | %d | %d\n"
--------------------------------------------------------------------------------
cbrt() - cube root
--------------------------------------------------------------------------------
find ./ -type f -exec chmod -x {} \;
don't execute it in the root directory. I've already done it :\
--------------------------------------------------------------------------------
echo 0x736872316b330a|xxd -r
--------------------------------------------------------------------------------
for i in `echo *`; do lynx -dump $i >> $i.txt; done
--------------------------------------------------------------------------------
If 12 virtual consoles are not sufficient for you, add the following to your /etc/inittab
13:1235:respawn:/sbin/agetty 38400 tty13 linux
14:1235:respawn:/sbin/agetty 38400 tty14 linux
15:1235:respawn:/sbin/agetty 38400 tty15 linux
16:1235:respawn:/sbin/agetty 38400 tty16 linux
Switch with AltGr+F1..F4 (AltGr is the key right to the spacebar)
--------------------------------------------------------------------------------
tail -f /blah/file
this will try to continuously (i.e. won't terminate at EOF) read from /blah/file and echo the 
newly available characters to the console,
--------------------------------------------------------------------------------
ever wanted a range operator (i.e. like perl's 1..100) in bash? here are 2 possible solutions:
for i in `seq 1 100`; do ..
for((i=1;i<101;i++))
credits go to AvatarBG@UniBG
--------------------------------------------------------------------------------
To make your DEL and End keys work right in Eterm add the following to your user.cfg or theme.cfg in section 'actions':
    bind 0xffff to echo '^D'
    bind 0xff57 to echo '^E'
