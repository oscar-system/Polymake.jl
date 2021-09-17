# polymake helper script for json representation of objects, functions, and methods

require JSON;

die "usage: $0 <pathname>" unless @ARGV >= 1;

my $jsonpath = shift @ARGV;

my @apps = @ARGV > 0 ? @ARGV : @User::start_applications;

# avoid wrapper compilation
$Polymake::Core::CPlusPlus::code_generation = "none";

sub type_for_julia($$;$) {
   my ($appname, $typename, $tparam) = @_;
   if ($tparam) {
      # remove at least some templates for better type guessing ...
      $typename =~ s/<$_>//g foreach map {$_->[0]} @$tparam;
   }
   my $type = application($appname)->eval_type($typename,1);
   if ($type) {
      if (instanceof Polymake::Core::BigObjectType($type)) {
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
   $fun{description} = $ov->text;
   my $textdoc = true;
   my $numparam = $ann->{param} ? scalar(@{$ann->{param}}) : 0;
   foreach my $arg (@{$ann->{param}}) {
      push @{$fun{args}}, {
                             name => $arg->name,
                             type => type_for_julia($appname,$arg->type,$ann->{tparam}),
                             description => $arg->text
                           };
   }
   $fun{mandatory_args} = defined $ann->{mandatory} ? $ann->{mandatory} + 1 : $numparam;

   if ($fun{mandatory_args} > $numparam) {
      push @{$fun{args}}, ({name => "",type=>"Anything",description=>""})
                           x ($fun{mandatory_args} - $numparam);
      $textdoc = false;
   }

   $fun{type_params} = [ map { {name=>$_->name, type=>"", description=>$_->text} } @{$ann->{tparam}}]
      if defined $ann->{tparam};

   $fun{mandatory_type_params} = $ann->{mandatory_tparams}
      if defined($ann->{mandatory_tparams});

   # not needed $fun{include} = ;
   if (defined ($ann->{options}) && scalar($ann->{options}) > 0) {
      push @{$fun{args}}, {name => "options", type => "OptionSet", description=>""};
      push @{$fun{opts}},
         map {
            {
               name => $_->name,
               type => type_for_julia($appname,$_->type,$ann->{tparam}),
               description=> $_->text
            }
         }
         @{$ann->{options}[0]->annex->{keys}};
   }

   $fun{examples} = [ map {$_->body} @{$ann->{examples}} ]
      if defined $ann->{examples};

   $fun{return} = {type => type_for_julia($appname,$ann->{return}->type,$ann->{tparam}), description=>$ann->{return}->text}
      if defined($ann->{return});

   if ($textdoc) {
      my $text_writer = new Core::Help::PlainText(0);
      $ov->write_function_text($help, $text_writer, true);
      $fun{doc} = $text_writer->text;
   } else {
      # this is necessary due to a bug in polymake
      $fun{doc} = "";
   }

   return \%fun;
}

sub methods_to_hash($$) {
   my ($appname, $type) = @_;
   my @methods;
   return [] if !defined($type->help_topic);
	foreach my $m ($type->help_topic->find("!rel","methods", ".*")) {
      foreach my $ov (%{$m->topics} ? (values %{$m->topics}) : ($m)) {
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
   foreach my $type (@gen_types) {
      my $ann = $type->help->annex;
      my $objhash = {
                       name => $type->full_name,
                       doc => $type->help->display_text
                    };
      my $c = 0;
      foreach my $p (@{$type->params // [] }) {
         push @{$objhash->{type_params}}, {
                                      name => $p->name,
                                      description =>
                                          defined($ann->{tparam})
                                             && @{$ann->{tparam}} >= $c
                                          ? $ann->{tparam}[$c++]->text
                                          : ""
                                   };
      }

      $objhash->{mandatory_type_params} = $ann->{mandatory_tparams}
         if defined($ann) && defined($ann->{mandatory_tparams});

      $objhash->{linear_isa} = [
                                  map { $_->qualified_name }
                                  grep { !defined($_->generic) }
                                  @{$type->linear_isa}
                               ];

      $objhash->{description} = $type->help->text
         if defined($type->help->text);

      $objhash->{examples} = [ map {$_->body} @{$ann->{examples}} ]
         if defined $ann && defined $ann->{examples};


      push @{$data{objects}}, $objhash;
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

