#
# Pulldown menus in Perl/Tk.
# Copyright 1996 Eric Foster-Johnson
#
use Tk;

# Create main window.
my $main = new MainWindow;

# A menu bar is really a Frame.
$menubar = $main->Frame(-relief=>"raised",
    -borderwidth=>2);

# Menubuttons appear on the menu bar.
$filebutton = $menubar->Menubutton(-text=>"File",
    -underline => 0);  # F in File

# Menus are children of Menubuttons.
$filemenu = $filebutton->Menu();

# Associate Menubutton with Menu.
$filebutton->configure(-menu=>$filemenu);


# Create menu choices.
$filemenu->command(-command => \&open_choice,
    -label => "Open...",
    -underline => 0); # O in Open

$filemenu->separator;

$filemenu->command(-label => "Exit",
    -command => \&exit_choice,
    -underline => 1);  # "x" in Exit


# Help menu.
$helpbutton = $menubar->Menubutton(-text=>"Help",
    -underline => 0);  # H in Help

$helpmenu = $helpbutton->Menu();

$helpmenu->command(-command => \&about_choice,
    -label => "About TkMenu...",
    -underline => 0); # A in About

$helpbutton->configure(-menu=>$helpmenu);


# Pack most Menubuttons from the left.
$filebutton->pack(-side=>"left");

# Help menu should appear on the right.
$helpbutton->pack(-side=>"right");

$menubar->pack(-side=>"top", -fill=>"x");


# Create a label widget for the main area.
$label = $main->Label(-text => "Main Area");

# Set to expand, with padding.
$label->pack(-side=>"top", -expand=>1,
    -padx=>100, -pady=>100);


# Create a status area.
$status = $main->Label(-text=>"Status area",
    -relief=>sunken,
    -borderwidth=>2,
    -anchor=>"w");

$status->pack(-side=>"top", -fill=>"x");


# Let Perl/Tk handle window events.
MainLoop;


# Subroutine to handle button click.
sub exit_choice {

    print "You chose the Exit choice!\n";
    exit;
}

sub open_choice {
    # Fill in status area.
    $status->configure(-text=>"Open file.");

    print "Open file\n";
}

sub about_choice {
    # Fill in status area.
    $status->configure(-text=>"About program.");

    print "About tkmenu.pl\n";
}

# tkmenu.pl
