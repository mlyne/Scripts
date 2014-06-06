#!/usr/bin/perl -w

use Tk;
use Cwd;

$top = new MainWindow;
print
    "Filename: ",
    $top->getOpenFile(-defaultextension => ".pl",
		      -filetypes        =>
		      [['Perl Scripts',     '.pl'            ],
		       ['Text Files',       ['.txt', '.text']],
		       ['C Source Files',   '.c',      'TEXT'],
		       ['GIF Files',        '.gif',          ],
		       ['GIF Files',        '',        'GIFF'],
		       ['All Files',        '*',             ],
		      ],
		      -initialdir       => Cwd::cwd(),
		      -initialfile      => "getopenfile",
		      -title            => "Your customized title",
		     ),
    "\n";

__END__
