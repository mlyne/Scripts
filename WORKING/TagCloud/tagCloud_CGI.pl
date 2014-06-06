
#!/usr/bin/perl
# use CGI::Carp qw(fatalsToBrowser);

use LWP::Simple;
use HTML::TreeBuilder;
use HTML::TagCloud;
use URI::URL;
use Lingua::EN::StopWords qw(%StopWords);
use HTML::Parse;
use HTML::FormatText;
use CGI;
$data = new CGI;
$WORDS{"w"}=1;
$visited_links{"link"} = 1;


print "Content-type: text/html\n\n";

$url=$data->param('url');

$url_count=0;

$MAX_Number=$data->param('MAX_Number');
$back_color=$data->param('back_color');
$font_color=$data->param('font_color');

if ($MAX_Number eq "") { $MAX_Number=50; }

$font_color="#".$font_color;
$back_color="#".$back_color;


if (($back_color eq "") || ($back_color eq "#"))  { $back_color = "#FFFFCC";}
if (($font_color eq "") || ($font_color eq "#")) { $font_color = "#009966";}



$MAX_level = 0;

if ($url eq "") {$url="http://www.mysite.com/home.cgi"; }

$cloud = HTML::TagCloud->new;

   process_link ($url, 0);



    my  $html = $cloud->html_and_css(2500);
    $html =~ s/<a /<a style='font-family: Arial;  color: $font_color;'/g;
    $url_end=substr($url, -4, 4);
    $html =~ s/$url_end\"/$url_end\" target=_blank/g;
    
   print "<body bgcolor=$back_color>";
   print $html;
   print "</body>";

 
sub process_link ($$)
{

  my $url_temp = shift;
  my $level = shift;

  my $page = get( $url_temp );
 
  my $plain_page = HTML::FormatText->new->format(parse_html($page));

 
  while ( $plain_page =~ m/(\w['\w-]*)/g ) {

      if(length($1) > 2)
      {
           $WORDS{lc $1}++;
      }
    }

# Output hash in a descending numeric sort of its values
foreach my $word ( sort { $WORDS{$b} <=> $WORDS{$a} } keys %WORDS) {
 
    if ($url_count >= $MAX_Number) { return;}
 
    if ( !exists($StopWords{$word}))
    {
       $cloud->add($word, $url_temp, $WORDS{$word});
       $url_count=$url_count+1;

       }
}

  if ($level >= $MAX_level)
  { 
     return 1;
  }
  else
  {
     $level=$level+1;
  }
    my $tree = HTML::TreeBuilder->new->parse($page);
    for (@{  $tree->extract_links('a')  }) {
      my($link, $element) = @$_;
           
     if ($link =~ m/\.xml/ )
     { }
     else
     { 
              ## Enable the following line if you want to display only the links from your site
              ##if( $link =~ m/mysite/)
              {
                 if ( !exists($visited_links{$link}))
                 {
                         $visited_links{$link} = 1;
                         process_link ($link, $level) ;
                 }
              }                         
      }
  }

  $tree->delete();                     
  return 1;
}
