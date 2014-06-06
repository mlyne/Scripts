#!/software/arch/bin/perl -w
#
# POD documentation - main docs before the code

=head1 NAME

reagent2target.pl - Produces *.ace files for reagent tracking

=head1 SYNOPSIS

reagent2target.pl > output_file.ace

=head1 DESCRIPTION

Takes the user through a series of menus which take
input from the command line. The data is then processed
into ACE format and written to a file.

The initial "process" menu specifies the type of reagent
and tracking process.

The process options are:

    FL_electronic
    FL_de_novo
    FL_current_reagent
    Lark
    Odyssey
    Update Reagent info


=head2 FL_electronic

Clones/sequences for which we have requested electronic extension
Normally requested by Mike Lyne, Ines Barroso, Alan Schafer or
Anne Ambler.
Normally requested from:

=over

=item Dirk Walther, Lab:B<PA_Bioinf>

=item Don Morris, Lab:B<PA_Bioinf>

=back


=cut
