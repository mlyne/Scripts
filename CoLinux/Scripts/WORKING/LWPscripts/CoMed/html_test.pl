#!/usr/bin/perl -w

my $string = "SearchLITE";

print <<TXT_HTML;
<html>
<head>
<title>Results of $string (mlyne)</title>
</head>
<BODY text=#000000 vLink=#cc0000 link=#cc0000 bgColor=white>

<TABLE borderColor=#99CC00 cellSpacing=0 borderColorDark=#ffffff cellPadding=0 width="100%" borderColorLight=#330099 border=0 hspace="0" vspace="0">
 <TBODY>
  <TR vAlign=top bgColor=#315399>
   <TD width="9%" height=66>
    <DIV align=left>
     <IMG height=120 src="/images/matrixsmall.jpg" alt="$string" width=120>
    </DIV>
   </TD>

   <TD vAlign=center width="91%" height=66>
    <FONT face="Arial, Helvetica, sans-serif" size=6>
     <B>
      <FONT color=#00FF00>&nbsp;&nbsp;&nbsp;$string</FONT>
     </B>
    </FONT>
   </TD>
  </TR>
 </TBODY>
</TABLE>

<DIV align=left>
 <TABLE borderColor=#FF0000 cellSpacing=0 borderColorDark=#FFFFFF cellPadding=0 width="100%" borderColorLight=#FFFFFF border=0 hspace="0" vspace="0">
  <TBODY>
   <TR bgColor=#315399>
    <TD>
     <DIV align=left>

      <FONT face="Arial, Helvetica, sans-serif" color=#00000 size=2>
        <FONT color=#000000>
         <A href="http://pubmatrix.grc.nia.nih.gov/secure-bin/index.pl">
          <FONT onmouseover='this.color="white";return true' onmouseout='this.color="#00CCCC";return true' color=#00CCCC size=2>
           <B>
            <FONT face="Arial, Helvetica, sans-serif">$string</FONT>
           </B>
          </FONT>
         </A>
        </FONT>
      </FONT>

       <FONT color=#ffffff>|</FONT>

       <FONT face="Arial, Helvetica, sans-serif" color=#000000 size=2>
        <B>
         <FONT face="Arial, Helvetica, sans-serif" color=#000000 size=2>
          <B>
           <FONT color=#ffffff>
            <FONT onmouseover='this.color="white";return true' onmouseout='this.color="#00CCCC";return true' color=#00CCCC size=2>
             <B>
              <FONT face="Arial, Helvetica, sans-serif" color=#000000 size=2>
               <B>
                <FONT face="Arial, Helvetica, sans-serif" color=#000000 size=2>
                 <B>
                  <FONT color=#ffffff>
                   <A href="mailto:michaellyne@arakis.com">
                    <FONT onmouseover='this.color="white";return true' onmouseout='this.color="#00CCCC";return true' color=#00CCCC size=2>
                     <B>
                      <FONT face="Arial, Helvetica, sans-serif">Contact Us</FONT>
                     </B>
                    </FONT>
                   </A>
                  </FONT>
                 </B>
                </FONT>
               </B>
              </FONT>
             </B>
            </FONT>
           </FONT>
          </B>
         </FONT>
        </B>
       </FONT>
TXT_HTML

print <<TABLE_TITLE;
<div align=center>
<font size=+2 color=blue>Matrix Results for SearchLITE</font><br>
<TABLE border 1>
<TR>
<TH colspan=11>
Some text Here for <font color=red>
MLYNE</font>
</TH></TR>
<tr><th>SearchLITE</th>
TABLE_TITLE
       
print <<TABLE_END;      
</TR>
</table>
</div>
</body>
</html><br>
TABLE_END


