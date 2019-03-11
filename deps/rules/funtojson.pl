# polymake helper script for json representation of functions and methods

require JSON;

die "usage: $0 <pathname>" unless @ARGV >= 1;


my $jsonpath = shift @ARGV;

my @apps = @ARGV > 0 ? @ARGV : @User::start_applications;

sub type_for_julia($$;$) {
   my ($appname, $typename, $tparam) = @_;
   if ($tparam) {
      # remove at least some templates for better type guessing ...
      $typename =~ s/<$_>//g foreach map {$_->[0]} @$tparam;
   }
   my $type = application($appname)->eval_type($typename,1);
   if ($type) {
      if (instanceof Polymake::Core::ObjectType($type)) {
         $type = $type->generic while $type->generic;
         return "BigObject<". ($type->name) .">";
      } elsif (instanceof Polymake::Core::PropertyType($type)) {
         if (defined($type->super) && instanceof Polymake::Core::BigObjectArray($type->super)) {
            return "BigObjectArray<". ($type->params->[0]->name) .">";
         } else {
            $type = $type->generic while $type->generic;
            return $type->name;
         }
      }
   }
   return "OptionSet"
      if ($typename eq "HASH");
   return "Anything";
}

sub help_to_hash($$$) {
   my ($appname,$help,$ov) = @_;
   my %fun;
   # return \%fun if $ov->text eq "UNDOCUMENTED\n";
   my $ann = $ov->annex;
   $fun{name} = $help->name;
   my $numparam = $ann->{param} ? scalar(@{$ann->{param}}) : 0;
   $fun{args} = [map { type_for_julia($appname,$_->[0]) } @{$ann->{param}}];
   $fun{mandatory} = defined $ann->{mandatory} ? $ann->{mandatory} + 1 : $numparam;
   push @{$fun{args}}, ("Anything") x ($fun{mandatory} - $numparam)
      if $fun{mandatory} > $numparam;
   $fun{type_params} = defined $ann->{tparam} ? scalar(@{$ann->{tparam}}) : 0;
   # not needed $fun{include} = ;
   push @{$fun{args}}, "OptionSet" if defined $ann->{options};
   $fun{return} = $help->return_type if defined($help->return_type);
   return \%fun;
}

sub methods_to_hash($$) {
   my ($appname, $type) = @_;
   my @methods;
   return [] if !defined($type->help_topic);
	foreach my $m ($type->help_topic->find("!rel","methods", ".*")) {
      foreach my $ov ((values %{$m->topics}) || ($m)) {
         my $fun = help_to_hash($appname, $m, $ov);
         $fun->{method_of} = type_for_julia($appname,$type->name);
         push @methods, $fun;
      }
   }
   return \@methods;
}

sub functions_to_hash($) {
   my ($appname) = @_;
   my @functions;
   foreach my $f (User::application($appname)->help->find("!rel", "functions", ".*")) {
      foreach my $ov (%{$f->topics} ? (values %{$f->topics}) : ($f)) {
         my $funhash = help_to_hash($appname, $f, $ov);
         push @functions, $funhash;
      }
   }
   return \@functions;
}

sub app_to_json($$) {
   my ($path, $appname) = @_;
   my $filename = "$path/$appname.json";
   my %data;
   $data{version} = "dev";
   $data{app} = $appname;
   # call funcs and meths
   push @{$data{functions}}, @{functions_to_hash($appname)};
   my @gen_types = grep {!defined($_->generic) } @{User::application($appname)->object_types};
   foreach my $gt (@gen_types) {
      push @{$data{functions}}, @{methods_to_hash($appname,$gt)};
      if ($gt->full_spez) {
         foreach my $spez (values %{$gt->full_spez}) {
            push @{$data{functions}}, @{methods_to_hash($appname,$spez)};
         }
      }
   }

   my $generator = JSON->new->canonical->pretty;
   my $text = $generator->encode(\%data);
   open my $F, ">:utf8", $filename
     or die "can't write to ", $filename, ": $!\n";
   print $F $text, "\n";
   close $F;
}

foreach my $app (@apps) {
   app_to_json($jsonpath,$app);
}

