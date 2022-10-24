use application "common";

set_custom $Visual::webbrowser="/usr/bin/wslview";
set_custom $Visual::pdfviewer="/usr/bin/wslview";

*ThreeJS::Viewer::command = sub {
   my ($self, $filename) = @_;
   chomp(my $res = `wslpath -m $Polymake::Resources`);
   $res =~ s/\$/\\\$/g;
   system("perl -pi -e 's{$Polymake::Resources}{file:///$res}g' $filename");
   chomp(my $wslfilename = "file:///".`wslpath -m $filename`);
   "$Visual::webbrowser $wslfilename < /dev/null";
};


*TikZ::Viewer::command = sub {
   my ($self, $filename)=@_;
   my $latextemplate = $self->tempfile.".tex";
   open my $fh, ">", $latextemplate;
   print $fh TikZ::Viewer::write_latextemplate("$filename");
   close $fh;
   my $pdfout_dir = $self->tempfile->dirname;
   my $pdfout_name = $self->tempfile->basename;
   chomp(my $wslfilename = "file:///".`wslpath -m $latextemplate`);
   $wslfilename =~ s/\.tex/.pdf/;
   "$Visual::pdflatex -interaction=batchmode --output-directory=$pdfout_dir --jobname=$pdfout_name $latextemplate 1>/dev/null; $Visual::pdfviewer $wslfilename < /dev/null";
};


*PmSvg::Viewer::command = sub {
   my ($self, $filename) = @_;
   chomp(my $wslfilename = "file:///".`wslpath -m $filename`);
   "$Visual::webbrowser $wslfilename < /dev/null";
};

