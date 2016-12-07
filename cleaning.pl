#!/usr/bin/env perl

use 5.14.0;

use warnings;
use strict;
no warnings 'experimental::smartmatch'; # removing 'given / when' warnings.

use Cwd;
use File::Copy qw( move );
use File::Path qw( make_path );
use List::Util qw( max );

require Term::ReadKey;
use IO::Prompter {
    ask_yesno  => [-yesno, -echo => "yes/no"],
    where      => ["destination: "],
};


my %conf = (
    confirm_override => 1,
    default_path     => getcwd(),
    );

my %work = (
    renamed   => 0,
    moved     => 0,
    ignored   => 0);

my $main_separator  = "*"x60;
my $inner_separator = "-"x40;   





############################################################
###                  Action functions
############################################################


# update = move inside the same directory (or potentially in a subdirectory).
sub update {
    my ($path, $old_filename) = @_;

    # TODO: more precise autocompletion (limited to subdirectories).
    my $new_filename = prompt("Enter the new name of the file: ",
			      -complete => 'dirnames',
			      -complete => 'filenames');

    if ( $new_filename =~ m{ / }x ) {
	my ($dir) = $new_filename =~ m{ (.*) / }x;
	$dir = "$path/$dir";
	unless (-d $dir) {
	    make_path $dir or
		die "Can't create dir '$dir'";
	}
    }

    if ( $conf{confirm_override} && -e $new_filename ) {
        unless (ask_yesno("File '$new_filename' already exists. ",
			  "Do you want to proceed? [y] ",
			  -default => "yes")) {
	    return;
	}
    }

    move "$path/$old_filename", "$path/$new_filename";
    $work{renamed}++;
}

# TODO: rename this function.
sub move_cst {
    my ($path, $old_filename) = @_;

    my $new_filename = prompt("Enter the new name of the file: ",
			      -complete => 'dirnames',
			      -complete => 'filenames');

    if ( $new_filename =~ m{ / }x ) {
	my ($dir) = $new_filename =~ m{ (.*) / }x;
	unless (-d $dir) {
	    make_path $dir 
		or die "Can't create dir '$dir'";
	}
    }

    if ( $conf{confirm_override} && -e $new_filename ) {
        unless (ask_yesno("File '$new_filename' already exists. ",
			  "Do you want to proceed? [y] ",
			  -default => "yes")) {
	    return;
	}
    }

    move "$path/$old_filename", $new_filename;
    $work{moved}++;
}

sub ignore {
    my ($path, $filename) = @_;
    #TODO: index of files that have been ignored?
    $work{ignored}++;
}


############################################################
###                   Prettification functions
############################################################


sub alert_start {
    print "\n", $main_separator,"\n\n";
}


sub print_end {
    say "\n",$main_separator;
    my $max = length(max values %work);
    for (qw(renamed moved ignored)) {
	printf "  %*d element%s $_\n", $max, $work{$_}, $work{$_}>1?"s":"";
    }
    say "\n";
}



############################################################
###                   
############################################################

# Creates an iterator for a directory.
sub iterate_through {
    my ($path) = @_;
    opendir(my $dh, $path) || die "Can't open $path";

    return sub {
        while (my $filename = readdir($dh)) {
            if ($filename eq "." || $filename eq "..") {
                next;
            } else {
                return $filename;
            }
        }
        
        closedir($dh);
        return undef;
    };
}

# Ask user to chose which directory to start with.
sub init_path {
    unless (ask_yesno("Do want to clean the current directory ",
		      "($conf{default_path})? [y] ",
		      -def => "y") ) {
        return prompt("Enter the directory to clean: ",
		      -complete => 'dirnames',
		      -must => { "(must exist)" => sub { -d $_[0] } });
	
    }
    return $conf{default_path};
}

# Iterates through the elements of a directory,
#  asks the user what to do,
#  then call the appropriate subroutine to do the action.
sub clean_directory {
    my ($path) = @_;

    say "\n",$inner_separator,"\n","Cleaning '$path'.\n";
    
    my $iterator = iterate_through($path);
    while (my $filename = $iterator->()) {
	if (-d "$path/$filename" and 
	    ask_yesno ("> $filename is a directory. ",
		       "Do you want to clean his elements one by one? [n]",
		       -default => "no") ) {
	    clean_directory("$path/$filename");
	} else {
	    given (prompt "> $filename: (R)ename / (M)ove / (N)one? ", -k1) {
		when (/R/i) {
		    update($path, $filename); 
		}
		when (/M/i) {
		    move_cst($path, $filename);
		}
		when (/N/i) { 
		    ignore();
		}
	    }
	}
    } continue {
	print "\n";
    }
}



alert_start();
clean_directory( init_path() );
print_end();
