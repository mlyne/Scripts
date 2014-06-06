Making Text HTML Safe

I'm sure most of you have had at least one occasion where you needed to effectively cut and paste a text file into an HTML file. If that text file contained any reserved characters like & or <, you probably had to convert them to HTML-safe entities such as &lt; for < by hand. Or maybe you haven't fixed the text and you now have an invalid HTML document out there on your Web site.

Well, if you find yourself doing this hand tuning on a regular basis or if you're routinely posting text into HTML files without checking to see if it's HTML safe, stop; because CPAN has a module called HTML::Entities which does all of the work for you.

The module contains a function appropriately named encode_entities() that automatically encodes all HTML reserved characters. So for example, if you have a string of text that's contained in a variable named $text that needs to be HTML encoded, you would first add the statement: use HTML::Entities to the top of your script and then type:

encode_entities($text);

somewhere in the main body of your source code. So if $text contained the string "Fred & Barney's Bowling Academy", it would be converted into "Fred &amp; Barney's Bowling Academy".

We could also build a simple script that converts an entire file such that we can execute the following on the command-line:

html_encode.pl < sample.txt > newtext.txt

Or in plain english, we direct a text file called sample.txt to the script as input and write the resulting encoded text to newtext.txt. The source of the script would look like the following:

#!/usr/bin/perl -w
use strict;
use HTML::Entities;

while (<>) {
    encode_entities($_);
    print;