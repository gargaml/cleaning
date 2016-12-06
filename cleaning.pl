#!/usr/bin/env perl

use 5.14.0;

use warnings;
use strict;
no warnings 'experimental::smartmatch'; # removing 'given / when' warnings.

use File::Copy qw( move );
use File::Path qw( make_path );

use IO::Prompter {
    ask_yesno  => [-yesno, -echo => "yes/no"],
    where      => ["destination: "],
};

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


sub update {
    my ($path, $old_filename, $new_filename) = @_;
    move("$path/$old_filename", "$path/$new_filename");
}

my $path = ".";
my $iterator = iterate_through($path);
while (my $filename = $iterator->()) {
    given (ask_yesno "rename $filename") {
        when ("y") {
            my $destination = where();
            say "destination : $destination";
            update($path, $filename, $destination); 
        }
        when ("n") { 
            undef;
        }
    }
}
