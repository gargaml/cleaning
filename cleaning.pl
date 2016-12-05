#!/usr/bin/env perl

use 5.14.0;

use warnings;
use strict;

use File::Copy qw/move/;

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

sub prompt {
    my ($sentence) = @_;
    
    print("$sentence(y/n) ");
    chomp(my $answer = <STDIN>);
    if ($answer =~ /n/) {
        return "n";
    } else {
        return "y";
    }
}

sub where {
    print("destination: ");
    chomp(my $destination = <STDIN>);
    return $destination;
}

sub update {
    my ($path, $old_filename, $new_filename) = @_;
    move("$path/$old_filename", "$path/$new_filename");
}

my $path = ".";
my $iterator = iterate_through($path);
while (my $filename = $iterator->()) {
    given (prompt "rename $filename") {
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
