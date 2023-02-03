use application "common";

sub configure_wsl
{
   my ($rule, $force) = @_;

   # is_changed should be true here if some autoconfiguration happened during startup
   unless ($force || (exists $Settings->items->{"Visual::$rule"} &&
                      $Settings->items->{"Visual::$rule"}->flags & Item::Flags::is_changed)) {
      # we keep the existing setting
      print("wslviewer.pl: keeping existing $rule setting\n");
      return true;
   }

   if (!-e "/usr/bin/wslview") {
      state $warned = 0;
      if ($force || !$warned) {
         warn("/usr/bin/wslview not found, to use native viewers for
         visualization on Windows (with WSL) please install wslview
         and run `Polymake.configure_wslview()` afterwards.\n");
         $warned = 1;
      }
      return false;
   }

   # this should make sure the custom variable exists
   application("common")->configured->{"$rule.rules"} > 0 or reconfigure("$rule.rules");

   eval("set_custom \$Visual::$rule='/usr/bin/wslview';
         print('wslviewer.pl: set $rule custom variable for wslview\n');");
   if ($@) {
      warn("wslviewer.pl: setting wslview for $rule failed $@.");
      return false;
   }

   # make sure rules are active
   application("common")->configured->{"$rule.rules"} > 0 or reconfigure("$rule.rules");
   return true;
}

sub wsl_redirect_webbrowser
{
   unless (application("common")->configured->{"webbrowser.rules"} > 0 &&
           $Visual::webbrowser eq "/usr/bin/wslview") {
      print("wslviewer.pl: expected webbrowser to be configured for wsl.\n");
      return 0;
   }
   print("wslviewer.pl: redirecting threejs sub\n");
   *ThreeJS::Viewer::command = sub {
      my ($self, $filename) = @_;
      chomp(my $res = `wslpath -m $Polymake::Resources`);
      $res =~ s/\$/\\\$/g;
      system("perl -pi -e 's{$Polymake::Resources}{file:///$res}g' $filename");
      chomp(my $wslfilename = "file:///".`wslpath -m $filename`);
      "$Visual::webbrowser $wslfilename < /dev/null";
   };

   print("wslviewer.pl: redirecting svg sub\n");
   *PmSvg::Viewer::command = sub {
      my ($self, $filename) = @_;
      chomp(my $wslfilename = "file:///".`wslpath -m $filename`);
      "$Visual::webbrowser $wslfilename < /dev/null";
   };
}


sub wsl_redirect_pdfviewer
{
   unless (application("common")->configured->{"pdfviewer.rules"} > 0 && 
           $Visual::pdfviewer eq "/usr/bin/wslview") {
      print("wslviewer.pl: expected pdfviewer to be configured for wsl.\n");
      return 0;
   }
   print("wslviewer.pl: redirecting tikz sub\n");
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
}

configure_wsl("webbrowser", @_) && wsl_redirect_webbrowser();
configure_wsl("pdfviewer", @_) && wsl_redirect_pdfviewer();
