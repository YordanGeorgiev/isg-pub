#!/usr/bin/env perl
use strict ; use warnings ; 
use 5.10.0 ; 
use ExtUtils::Installed;

	#  quick and dirty check for prerequisites perl modules:
	#  courtesy of:http://stackoverflow.com/a/9340304/65706
	#  if you have a calling bash script call by :
	#  perl "/path/to/isg_pub_preq_checker.pl"
	#  export ret=$?
	#  test $ret -ne 0 && doExit 1 "[FATAL] perl modules not found!!!"

	my $PrintOkCheck = 1 ; 

	# check that all the required modules are installed
	my ( $ret , $msg ) = doCheckRequiredModules();

	unless ( $ret == 0 ) {
		print "$msg" ; 
		# give some time for the user to react
		print "printing all installed modules :" ; 
		my $c = 9 ; 
		for ( my $i=0;$i<=$c;$i++){
			print ( ( $c-$i) . '.') ;  
			sleep 1 ; 
		}
		print "\n" ; 
		doListAllInstalledModules();  
		print "\n" ; 
	}

	exit(0);

	sub doListAllInstalledModules {
		my $instmod = ExtUtils::Installed->new();
		 foreach my $module ($instmod->modules()) {
			my $version = $instmod->version($module) || "???"; 
			 print "found module:$module -- v$version\n"; 
			}

	}
	#eof sub

	sub doCheckRequiredModules {

		my @modules = qw(
			YAML::Any
			Test::More
			Spreadsheet::XLSX
			Test::Deep
			File::Copy::Recursive
			IO::HTML
			Test::More
			Filter::Util::Call
			Algorithm::Diff
			Text::Diff
			Test::Base
			Test::CPAN::Meta::YAML
			Test::YAML::Valid  
			Test::YAML::Meta
			Test::YAML
			Data::Printer
			ExtUtils::Installed
			Sub::StrictDecl
			Spreadsheet::WriteExcel
			Mojolicious::Plugin::RenderFile
			JSON
			Carp::Always
			Mojolicious::Plugin::PDFRenderer
			);

		for(@modules) {
			 eval "use $_";
			 if ($@) {
				
				#flush the screen
				print "\033[2J";    
				print "\033[0;0H";

				my $msg = "\n\n\n [FATAL] did not found the following prerequisite perl module: $_ \n\n" ; 
				$msg .= "\n # == START copy paste == " ; 
				$msg .= "\n#you must install it otherwise the application will not work" ; 
				$msg .= "\n#the module could be installef by running the following commands:" ; 
				# if the user knows already the difference between the running the cmd 
				# with sudo or he / she probably knows already how-to install perl modules
				$msg .= "\n# as a start configure the cpan to install dependancies first \n" ; 
				$msg .= "\n" . 'perl -MCPAN -e \'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit\'' . "\n" ; 
				$msg .= "\n#than install the $_ module by running: \n" ; 
				$msg .= "\nsudo perl -MCPAN -e 'install $_'\n\n\n" ; 
				$msg .= "\n # == STOP  copy paste == \n\n\n" ; 
				$msg .= "\n # == START copy paste == " ; 
				$msg .= "\n# if you seem to be stuck in circular reference kind of loop try even :\n" ; 
				$msg .= "\nsudo perl -MCPAN -e 'CPAN::Shell->force(qw( install $_));'\n" ; 
				$msg .= "\n # == STOP  copy paste == " ; 
				$msg .= "\n# You may end-up now with Ctrl + C \n\n\n" ; 

				return ( 1, "$msg")  if $@;
			 } else {
				  say "[INFO ] == ok == check for prerequisite perl module : $_" if $PrintOkCheck == 1 ; 
			 }
		}
		#eof foreach module

		return ( 0 , "all required modules found" ) ;   
	}
	#eof sub
	# ??!!
	#perl -MCPAN -e 'install Module::Signature'
	# the following modules have been or might be part of the installable modules
	#PDF::WebKit
	#HTML::TreeBuilder
	#HTML::TreeBuilder::XPath
	#HTML::TableExtract
	#HTML::ElementTable
