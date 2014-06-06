#!/usr/bin/perl -w

use strict;
use HTML::TokeParser::Simple;

my $file = $ARGV[0];
my $html_file = $ARGV[1];

open(OUT_FILE_HTML, "> $html_file.html") || die "cannot open $html_file: $!\n";

# --- START Header HTML --- #

print OUT_FILE_HTML <<TXT_HTML;
<html>
<head>
<title>Results of SearchLITE (Copyright &copy; 2003, 2004 Arakis Ltd.)</title>
</head>
<BODY text=#000000 vLink=#9F79EE link=#8A2BE2 bgColor=white>

<TABLE borderColor=#9966ff cellSpacing=0 borderColorDark=#9966ff cellPadding=0 width="100%" borderColorLight=#330099 border=0 hspace="0" vspace="0">
 <TBODY>
  <TR vAlign=top bgColor=#d7bcff>
   <TD width="15%" height=66>
    <DIV align=left>
     <IMG height=210 src="SearchLITElogo_tr.gif" alt="SearchLITE" width=210>
    </DIV>
   </TD>

   <TD vAlign=center width="50%" height=66>
   <FONT face="Arial, Helvetica, sans-serif" size=10>
     <B>
      <FONT color=#000000>&nbsp;&nbsp;&nbsp;Search</FONT><FONT color=white>LITE&nbsp;&nbsp;&nbsp;</FONT>
     </B>
    </FONT>
   </TD>
   
    <TD width="11%" height=66>
     <DIV align=right>
      <IMG height=66 src="Arakis1_sq.gif" alt="Arakis Logo" width=150>
     </DIV>
   </TD>      
  </TR>
 </TBODY>
</TABLE>

<B><A href="http://chem.sis.nlm.nih.gov/chemidplus/cmplxqry.html"TARGET="resource window">Search ChemID for Structure</A></B>

<div align=center>
<font size=+2 color=#9900CC>SearchLITE Matrix - HyperLink Search Results</font><br>
<TABLE border 1>
<TR>
<TH colspan=11>
Pharmacology KnowledgeBase<font color=purple>
PharMatrix</font>
</TH>

TXT_HTML
# --- END Header HTML --- #

my $add_tag = "\"\nTARGET=\"resource window";

my $p = HTML::TokeParser::Simple->new($file);

while(my $token = $p->get_token) {

	next if ($token->is_tag('head'));
	next if ($token->is_tag('meta'));
	next if ($token->is_tag('link'));
	next if ($token->is_tag('style'));
	next if ($token->is_tag('body'));
	next if ($token->is_tag('col'));
	next if ($token->is_tag('div'));
	next if ($token->is_tag('table'));
	next if ($token->is_tag('html'));

	if ( $token->is_start_tag( 'td' ) ) {
		$token->delete_attr('class');
	  	$token->delete_attr('width');
	  	$token->delete_attr('style');
	  	$token->delete_attr('height');
#		print 'Tag_td: '.$token->as_is."\n"
	} 
	
	if ( $token->is_start_tag( 'a' ) ) {
    	my $action = $token->return_attr->{href};
#    	print $action, "\n*\n";
    	my $new_act = "$action$add_tag";
     	$token->set_attr('action', $new_act);
  	}

	
	if ( $token->is_tag( 'a' ) ) {
#		print 'Tag_a: '.$token->as_is."\n"
	}
	
	if ( $token->is_text ) {
#		print 'Txt: '.$token->as_is."\n"
	}
	
	print OUT_FILE_HTML $token->as_is;

#  print 'Text: '.$token->as_is."\n" if ($token->is_text);
#  print 'Tag: '.$token->as_is."\n" if ($token->is_tag);
   
}

print OUT_FILE_HTML <<TXT_HTML;
</TR>
</table>
</div>
</body>
</html>
TXT_HTML

close(OUT_FILE_HTML);

