#!C:\perl\bin -w
#
# Usage:  DB.pl input1.sql [input2.sql input3.sql ...]
#	It generates input1_out.sql [input2_out.sql input3_out.sql ...]
#
#--------------------------------------------------
use strict;

if ($#ARGV < 0) {
	print "Usage: DB.pl input1.sql [input2.sql input3.sql ...]\n";
	exit (0);
}

my $dbo = "dbo";

foreach my $in(@ARGV) {
	my @file = split(/\./, $in);
	my $outFile = "$file[0]_out.sql";
	
	open (OUTPUT, ">$outFile") || die "cannot open output file:$1";

	if ($in =~ /allinteg/) {
		&create_allinteg($in);
	} elsif ($in =~ /alltable/) {
		&create_alltable($in);
	} elsif ($in =~ /dropindex/) {
		&create_dropindex($in);
	} elsif ($in =~ /dropinteg/) {
		&create_dropinteg($in);
	}
	close (OUTPUT);

}

#---------------------Subroutine--------------------------
#------------------------------------------
# create allinteg
#------------------------------------------
sub create_allinteg() {
	my $inFile = shift;
	my (@name1, @name);
	my $i=1;
	my $j = 1;

	open (INPUT, "$inFile") || die "can't open INPUT: $1";
	while (my $Line=<INPUT>) {
		chop $Line;
		if ($Line =~ /^ALTER/) {
			$i = 0;
			@name1 = split (/ /, $Line);
			print OUTPUT "\nALTER TABLE $dbo.$name1[2]";
		} elsif ($Line =~ /PRIMARY KEY/) {
			$Line =~ s/\t//;
			print OUTPUT "\n\t WITH NOCHECK $Line";
		} elsif ($Line =~ /FOREIGN KEY/) {
			$j = 0;
			$Line =~ s/\t//;
			@name = split (/REFERENCES /, $Line);
			print OUTPUT "\n\t WITH NOCHECK $name[0]REFERENCES $dbo.$name[1]";  
		} elsif ($Line =~ /^go/) {
			if ($i==0 && $j ==0) {
				print OUTPUT "\n\t NOT FOR REPLICATION";
			}
			print OUTPUT "\n$Line";
			print OUTPUT "\n";
			$i = 1;
			$j = 1;
		} else {
			print OUTPUT "\n$Line";			
		}
	 
	}
	close (INPUT);
}

#-----------------------------------------
# Create alltable
#-----------------------------------------
sub create_alltable() {
	my $inFile = shift;
	my (@name1, @name);
	open (INPUT, "$inFile") || die "can't open INPUT: $1";
	while (my $Line=<INPUT>) {
		chop $Line;
		if ($Line =~ /CREATE /) {
			@name1 = split (/ /, $Line);
			print OUTPUT "\nCREATE TABLE $dbo.$name1[2]";
		} elsif ($Line =~ /IDENTITY/) {
			@name = split (/\,/, $Line);
			if ($#name > 0) {
				if ($Line =~ /\) \,/) {
					print OUTPUT "\n $name[0],$name[1] NOT FOR REPLICATION,";
					}
				else {
					print OUTPUT "\n $name[0],$name[1] NOT FOR REPLICATION";
					}
			} else {
				print OUTPUT "\n $Line";
			}
		} else {
			print OUTPUT "\n $Line";
		}
	}
	close (INPUT);
}

#----------------------------------------------------------
# Create dropindex
#----------------------------------------------------------
sub create_dropindex() {
	my $inFile = shift;
	my (@name1, @name);

	open (INPUT, "$inFile") or die "can't open INPUT: $1";
	LINE:
	while ($_=<INPUT>) {
		chop $_;		
		 if ($_ =~ /INDEX/) {
			my $tem = $_;
			@name1 = split (/ /, $tem);			
			print OUTPUT "\nif exists (select * from sysindexes where name = '$name1[2]')";
			print OUTPUT "\nbegin";
			print OUTPUT "\n\t PRINT 'Dropping index $name1[4].$name1[2] ...'";
			print OUTPUT "\n\t $tem";
			print OUTPUT "\nend";
			print OUTPUT "\ngo";
			print OUTPUT "\n";
		}
	}
	close (INPUT);
}

#--------------------------------------------------------
# create dropinteg
#--------------------------------------------------------
sub create_dropinteg() {
	my $inFile = shift;
	my ($constraint, $table);
	my (@name, @name1);
	my $j=1;
	my $i=1;

	print OUTPUT "-- Foreign Key";

	open (INPUT, "$inFile") || die "can't open INPUT: $1";
	while (my $Line=<INPUT>) {
		chop $Line;
		if ($Line =~ /^ALTER/) {
			$i=0;
			@name1 = split (/ /, $Line);
			$table = $name1[2];
		} elsif ($Line =~ /FOREIGN KEY/) {
			$j = 0;
			@name = split (/ +/, $Line);
			$constraint = $name[2];
		}
		if ($i==0 && $j==0) {
			print OUTPUT "\nif exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '$table' and CONSTRAINT_NAME = '$constraint')";
			print OUTPUT "\n\tbegin";
			print OUTPUT "\n\t\tPRINT 'Dropping foreign key constraint $table.$constraint...'";
			print OUTPUT "\n\t\tALTER TABLE $table DROP CONSTRAINT $constraint";
			print OUTPUT "\n\tend";
			print OUTPUT "\ngo\n";
			$i=1;
			$j=1;
		}	 
	}
	close (INPUT);

	print OUTPUT "-- primary key";
	$i=1;
	$j=1;

	open (INPUT, "$inFile") or die "can't open INPUT: $1";
	while (my $Line=<INPUT>) {
		chop $Line;
		if ($Line =~ /^ALTER/) {
			$i=0;
			@name1 = split(/ /, $Line);
			$table = $name1[2];		
		} elsif ($Line =~ /PRIMARY KEY/) {
			$j=0;
			@name = split (/ +/, $Line);
			$constraint = $name[2];
		}
		if ($i==0 && $j==0) {
			print OUTPUT "\nif exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '$table' and CONSTRAINT_NAME = '$constraint')";
			print OUTPUT "\n\tbegin";
			print OUTPUT "\n\t\tPRINT 'Dropping primary key constraint $table.$constraint...'";
			print OUTPUT "\n\t\tALTER TABLE $table DROP CONSTRAINT $constraint";
			print OUTPUT "\n\tend";
			print OUTPUT "\ngo\n";
			$i=1;
			$j=1;
		}
	}	 
	close (INPUT);
}
#-------------------------End-----------------------------
