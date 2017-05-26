package DocPub::Model::HtmlToPdfConverter ; 

   use strict ; 
   use warnings ; 

   require Exporter; 
   use AutoLoader ; 

	use utf8 ; 
	use Encode ; 

	use Data::Printer ; 
	use Carp ; 
	use Spreadsheet::WriteExcel;
	use Spreadsheet::ParseExcel ; 
	use Spreadsheet::ParseExcel::Cell ; 
	use Time::Local qw( timelocal_nocheck ) ; 


   our $ModuleDebug           = 0 ; 
   our $IsUnitTest            = 0 ; 
	our $objController 			= {} ; 
	our $objLogger					= q{} ;
	our $app_config				= q{} ;


   #
   # -----------------------------------------------------------------------------
	# get the table headers for the table resultset 
   # -----------------------------------------------------------------------------
	sub doConvert {

		my $self 			= shift ;
		my $db 				= shift ; 
		my $table 			= shift ;
		my $rs_meta 		= shift ; 
		my $rs				= shift ; 
		my $id				= $objController->param('branch-id') || $objController->param('path-id') || 1 ; 
		#debug print "HtmlToPdfConverter:: doConvert pdf_dir" . $pdf_dir ; 
		
		unless ( $rs_meta or $rs ) {
			return ; 
		}

		# Create a new Excel workbook
		my $project_version_dir 		= $app_config->{'ConfDir'} ; 
		$project_version_dir 			=~ s/(.*)(\/)(.*)/$1/g ; 
		my $pdf_dir 						= $project_version_dir . "/doc_pub/public/pdf/" . $db  ; 
		
		
		$pdf_dir = '/tmp' ; 
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = $self-> GetTimeUnits(); 
		my $ts = $year . $mon . $mday . '_' . $hour . $min . $sec ;  
		$table = lc ( $table ) ; 
		my $out_file = "$pdf_dir/" . $db . '.' . "$table" . '-' . $id . '.' . $ts . '.pdf' ; 


		my $web_host 				= $app_config->{'web_host'} ;
		my $web_port 				= $app_config->{'web_port'} ;
		#todo
		#$web_port 				= '5001' ; 
		my $ProductVersionDir 	= $app_config->{'ProductVersionDir'} ;

		my $item						= $objController->param('item')  || 'Issue' ;
		my $item_id					= $objController->param('branch-id')  || '1' ; 
		my $url						= $objController->req->url ;
		$url							= Mojo::Util::url_unescape ( $url ) ; 
		$url							=~ s/export/viewpdf/g ; 
		$url							= 'http://' . "$web_host" . ':' . "$web_port" . "$url" ; 
		my $ret						= 1 ; 
		my $msg						= '' ; 
		my $cmd 						= '' ; 

		#/usr/bin/wkhtmltopdf --page-size A4 --orientation Portrait --zoom 0.75 --page-width 800 --margin-bottom 15 --margin-left 10 --margin-right 1 --margin-top 15 "$url" $out_file

		#old $cmd		.= '/bin/sh /usr/bin/wkhtmltopdf' ; 	
		$cmd		.= '/bin/sh /usr/bin/wkhtmltopdf.sh' ; 	
		#$cmd 		.= ' -T 10mm --header-right [page]/[toPage] ' ; 
		#$cmd		.= ' --header-font-size 9 ' ; 
		#$cmd		.= ' --header-spacing 10 ' ; 
		##$cmd		.= ' --footer-line ' ; 
		# the space breaks the whole execution !!!

		# enable footer 
		# $cmd		.= " --footer-left Oxit_Oy " ; 
		# $cmd		.= ' --footer-font-size 9 ' ; 
		$cmd		.= ' --footer-spacing 10 ' ; 
		$cmd  	.= ' --footer-right [page]/[toPage] ' ; 
		$cmd		.= ' --page-size A4 ' ; 	
		$cmd		.= ' --orientation Portrait ' ; 	
		$cmd		.= ' --zoom 0.75 ' ; 
		$cmd		.= ' --page-width 800 ' ; 
		$cmd		.= ' --margin-bottom 30 ' ; 
		$cmd		.= ' --margin-left 10 ' ; 
		$cmd		.= ' --margin-right 1 ' ; 
		$cmd		.= ' --margin-top 20 ' ; 
		$cmd		.= ' toc ' ; 
		#$cmd		.= '--load-error-handling ignore ' ; 
		$cmd		.= " \"$url\" " ; 
		$cmd		.= " $out_file " ; 
		print '@ doc_pub/lib/DocPub/Model/HtmlToPdfConverter.pm cmd: ' . "$cmd" . "\n\n" ; 
		# Action !!!
		#
		`$cmd` ; 
		# The Excel file in now in $str. Remember to binmode() the output
		# filehandle before printing it.
		binmode STDOUT;
		sleep 2 ; 	
		return $out_file ; 
		#  Headers and footers can be added to the document by the --header-* and
		#  --footer* arguments respectfully.  In header and footer text string supplied
		#  to e.g. --header-left, the following variables will be substituted.
		#
		#   * [page]       Replaced by the number of the pages currently being printed
		#   * [frompage]   Replaced by the number of the first page to be printed
		#   * [topage]     Replaced by the number of the last page to be printed
		#   * [webpage]    Replaced by the URL of the page being printed
		#   * [section]    Replaced by the name of the current section
		#   * [subsection] Replaced by the name of the current subsection
		#   * [date]       Replaced by the current date in system local format
		#   * [isodate]    Replaced by the current date in ISO 8601 extended format
		#   * [time]       Replaced by the current time in system local format
		#   * [title]      Replaced by the title of the of the current page object
		#   * [doctitle]   Replaced by the title of the output document
		#   * [sitepage]   Replaced by the number of the page in the current site being converted
		#   * [sitepages]  Replaced by the number of pages in the current site being converted
		#
		#
		#  As an example specifying --header-right "Page [page] of [toPage]", will result
		#  in the text "Page x of y" where x is the number of the current page and y is
		#  the number of the last page, to appear in the upper left corner in the
		#  document.
#
	}
	#eof sub doConvertTableToSheet

	#
	# -----------------------------------------------------------------------------
	# call by: 
	# my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = $objTimer-> GetTimeUnits(); 
	# -----------------------------------------------------------------------------
	sub GetTimeUnits {

		my $self = shift ; 

		# Purpose: returns the time in yyyymmdd-format 
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
		#---- change 'month'- and 'year'-values to correct format ---- 
		$sec = "0$sec" if ($sec < 10); 
		$min = "0$min" if ($min < 10); 
		$hour = "0$hour" if ($hour < 10);
		$mon = $mon + 1;
		$mon = "0$mon" if ($mon < 10); 
		$year = $year + 1900;
		$mday = "0$mday" if ($mday < 10); 

		return ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) ; 

	} #eof sub 

   

   #
   # -----------------------------------------------------------------------------
   # doInitialize the object with the minimum data it will need to operate 
   # -----------------------------------------------------------------------------
   sub doInitialize {

      my $self = shift ; 
		
		# get the application configuration hash
		# get the application configuration hash
		# global app config hash
		$app_config 	= $objController->app->get('AppConfig') ; 
		$objLogger 		= $app_config->{'ObjLogger'} ;

   }
   #eof sub doInitialize


   #
   # -----------------------------------------------------------------------------
   # the constructor 
   # -----------------------------------------------------------------------------
   sub new {

      my $class            = shift ;    # Class name is in the first parameter
		$objController			= ${ ( shift @_ ) } ; 

		my @args 				= ( @_ ); 

      # Anonymous hash reference holds instance attributes
      my $self = { }; 
      bless($self, $class);     # Say: $self is a $class

      $self->doInitialize() ; 
      return $self;
   } 
   #eof const 
	
	

	
1;


__END__


=head1 NAME

NiceTableBuilder

=head1 SYNOPSIS

use DocPub::View::NiceTableBuilder ; 
  
=head1 DESCRIPTION


=head2 EXPORT


=head1 SEE ALSO

  perldoc perlvars

  No mailing list for this module


=head1 AUTHOR

  yordan.georgiev@gmail.com

=head1 COPYRIGHT LICENSE

  Copyright (C) 2015 Yordan Georgiev

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.8.1 or,
  at your option, any later version of Perl 5 you may have available.

=cut


# 
# -----------------------------------------------------------------------------
# VersionHistory
# -----------------------------------------------------------------------------
#
# 1.0.0 -- 2015-08-24 13-22-44 -- ysg -- initial version 
#
