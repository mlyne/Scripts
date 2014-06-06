#!/usr/bin/perl -w
# $Rev$
# $Author$
# $Date$

use strict;
use WWW::Mechanize;
use JSON -support_by_pp;

fetch_json_page("http://www.southparkstudios.com/includes/utils/proxy_feed.php?html=season_json.jhtml%3fseason=1");

sub fetch_json_page
{
  my ($json_url) = @_;
  my $browser = WWW::Mechanize->new();
  eval{
    # download the json page:
    print "Getting json $json_url\n";
    $browser->get( $json_url );
    my $content = $browser->content();
    my $json = new JSON;
    
    # these are some nice json options to relax restrictions a bit:
    my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);

    # iterate over each episode in the JSON structure:
    my $episode_num = 1;
    foreach my $episode( @{ $json_text->{season}->{episode} } ) {
      my %ep_hash = ();
      $ep_hash{title} = "Episode $episode_num: $episode->{title}";
      $ep_hash{description} = $episode->{description};
      $ep_hash{url} = "http://www.southparkstudios.com/episodes/" . $episode->{id};
      $ep_hash{publish_date} = $episode->{airdate};
      $ep_hash{thumbnail_url} = $episode->{thumbnail_190} || $episode->{thumbnail_larger};
      
      # print episode information:
      while (my($k, $v) = each (%ep_hash)){
        print "$k => $v\n";
      }
      print "\n";
      
      $episode_num++;
    }
  };
  # catch crashes:
  if($@){
    print "[[JSON ERROR]] JSON parser crashed! $@\n";
  }
}