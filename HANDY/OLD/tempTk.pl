#!/software/arch/bin/perl -w
#
#
#

use Tk;                                          # Slurp the module in.
# -------------------------------------------------------
# Create a main window 
# -------------------------------------------------------
$top = MainWindow->new(); 
$top->title ("Simple");
# -------------------------------------------------------
# Instantiate widgets and arrange them
# -------------------------------------------------------
$l = $top-->Label(text   => 'hello',            # label properties
                 anchor => 'n',                 # anchor text to "north"
                 relief => 'groove',            # border style
                 width  =>  10, height => 3);  # 10 chars wide, 3 high.

$l->pack();      # Give it a default place within the main window
# -------------------------------------------------------
# Sit in an infinite loop dispatching incoming events.
# -------------------------------------------------------
MainLoop();
