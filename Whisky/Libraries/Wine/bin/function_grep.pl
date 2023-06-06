#! /usr/bin/perl -w
#
# Copyright 2000 Patrik Stridvall
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
#

use strict;

my $name0=$0;
$name0 =~ s%^.*/%%;

my $invert = 0;
my $pattern;
my @files = ();
my $usage;

while(defined($_ = shift)) {
    if (/^-v$/) {
        $invert = 1;
    } elsif (/^--?(\?|h|help)$/) {
        $usage=0;
    } elsif (/^-/) {
        print STDERR "$name0:error: unknown option '$_'\n";
        $usage=2;
        last;
    } elsif(!defined($pattern)) {
        $pattern = $_;
    } else {
        push @files, $_;
    }
}
if (defined $usage)
{
    print "Usage: $name0 [--help] [-v] pattern files...\n";
    print "where:\n";
    print "--help    Prints this help message\n";
    print "-v        Return functions that do not match pattern\n";
    print "pattern   A regular expression for the function name\n";
    print "files...  A list of files to search the function in\n";
    exit $usage;
}

foreach my $file (@files) {
    open(IN, "< $file") || die "Error: Can't open $file: $!\n";

    my $level = 0;
    my $extern_c = 0;

    my $again = 0;
    my $lookahead = 0;
    while($again || defined(my $line = <IN>)) {
	if(!$again) {
	    chomp $line;
	    if($lookahead) {
		$lookahead = 0;
		$_ .= "\n" . $line;
	    } else {
		$_ = $line;
	    }
	} else {
	    $again = 0;
	}

	# remove C comments
	if(s/^(|.*?[^\/])(\/\*.*?\*\/)(.*)$/$1 $3/s) {
	    $again = 1;
	    next;
	} elsif(/^(.*?)\/\*/s) {
	    $lookahead = 1;
	    next;
	}

	# remove C++ comments
	while(s/^(.*?)\/\/.*?$/$1\n/s) { $again = 1; }
	if($again) { next; }

	# remove empty rows
	if(/^\s*$/) { next; }

	# remove preprocessor directives
	if(s/^\s*\#/\#/m) {
	    if(/^\#[.\n\r]*?\\$/m) {
		$lookahead = 1;
		next;
	    } elsif(s/^\#\s*(.*?)(\s+(.*?))?\s*$//m) {
		next;
	    }
	}

	# Remove extern "C"
	if(s/^\s*extern[\s\n]+"C"[\s\n]+\{//m) {
	    $extern_c = 1;
	    $again = 1;
	    next;
	} elsif(m/^\s*extern[\s\n]+"C"/m) {
	    $lookahead = 1;
	    next;
	}

	if($level > 0)
	{
	    my $line = "";
	    while(/^[^\{\}]/) {
		s/^([^\{\}\'\"]*)//s;
		$line .= $1;
	        if(s/^\'//) {
		    $line .= "\'";
		    while(/^./ && !s/^\'//) {
			s/^([^\'\\]*)//s;
			$line .= $1;
			if(s/^\\//) {
			    $line .= "\\";
			    if(s/^(.)//s) {
				$line .= $1;
				if($1 eq "0") {
				    s/^(\d{0,3})//s;
				    $line .= $1;
				}
			    }
			}
		    }
		    $line .= "\'";
		} elsif(s/^\"//) {
		    $line .= "\"";
		    while(/^./ && !s/^\"//) {
			s/^([^\"\\]*)//s;
			$line .= $1;
			if(s/^\\//) {
			    $line .= "\\";
			    if(s/^(.)//s) {
				$line .= $1;
				if($1 eq "0") {
				    s/^(\d{0,3})//s;
				    $line .= $1;
				}
			    }
			}
		    }
		    $line .= "\"";
		}
	    }

	    if(s/^\{//) {
		$_ = $'; $again = 1;
		$line .= "{";
		$level++;
	    } elsif(s/^\}//) {
		$_ = $'; $again = 1;
		$line .= "}" if $level > 1;
		$level--;
		if($level == -1 && $extern_c) {
		    $extern_c = 0;
		    $level = 0;
		}
	    }

	    next;
	} elsif(/^class[^\}]*{/) {
	    $_ = $'; $again = 1;
	    $level++;
	    next;
	} elsif(/^class[^\}]*$/) {
	    $lookahead = 1;
	    next;
	} elsif(/^typedef[^\}]*;/) {
	    next;
        } elsif(/(extern\s+|static\s+)?
		(?:__inline__\s+|__inline\s+|inline\s+)?
		((struct\s+|union\s+|enum\s+)?(?:\w+(?:\:\:(?:\s*operator\s*[^\)\s]+)?)?)+((\s*(?:\*|\&))+\s*|\s+))
		((__cdecl|__stdcall|CDECL|VFWAPIV|VFWAPI|WINAPIV|WINAPI|CALLBACK)\s+)?
		((?:\w+(?:\:\:)?)+(\(\w+\))?)\s*\(([^\)]*)\)\s*
		(?:\w+(?:\s*\([^\)]*\))?\s*)*\s*
                (\{|\;)/sx)
	{
	    $_ = $'; $again = 1;
	    if($11 eq "{")  {
		$level++;
	    }

	    my $linkage = $1;
            my $return_type = $2;
            my $calling_convention = $7;
            my $name = $8;
            my $arguments = $10;

            if(!defined($linkage)) {
                $linkage = "";
            }

            if(!defined($calling_convention)) {
                $calling_convention = "";
            }

            $linkage =~ s/\s*$//;

            $return_type =~ s/\s*$//;
            $return_type =~ s/\s*\*\s*/*/g;
            $return_type =~ s/(\*+)/ $1/g;

            $arguments =~ y/\t\n/  /;
            $arguments =~ s/^\s*(.*?)\s*$/$1/;
            if($arguments eq "") { $arguments = "void" }

            my @argument_types;
            my @argument_names;
            my @arguments = split(/,/, $arguments);
            foreach my $n (0..$#arguments) {
                my $argument_type = "";
                my $argument_name = "";
                my $argument = $arguments[$n];
                $argument =~ s/^\s*(.*?)\s*$/$1/;
                # print "  " . ($n + 1) . ": '$argument'\n";
                $argument =~ s/^(IN OUT(?=\s)|IN(?=\s)|OUT(?=\s)|\s*)\s*//;
                $argument =~ s/^(const(?=\s)|CONST(?=\s)|__const(?=\s)|__restrict(?=\s)|\s*)\s*//;
                if($argument =~ /^\.\.\.$/) {
                    $argument_type = "...";
                    $argument_name = "...";
                } elsif($argument =~ /^
                        ((?:struct\s+|union\s+|enum\s+|(?:signed\s+|unsigned\s+)
                          (?:short\s+(?=int)|long\s+(?=int))?)?(?:\w+(?:\:\:)?)+)\s*
                        ((?:const(?=\s)|CONST(?=\s)|__const(?=\s)|__restrict(?=\s))?\s*(?:\*\s*?)*)\s*
                        (?:const(?=\s)|CONST(?=\s)|__const(?=\s)|__restrict(?=\s))?\s*
			(\w*)\s*
			(?:\[\]|\s+OPTIONAL)?/x)
                {
                    $argument_type = "$1";
                    if($2 ne "") {
                        $argument_type .= " $2";
                    }
                    $argument_name = $3;

                    $argument_type =~ s/\s*const\s*/ /;
                    $argument_type =~ s/^\s*(.*?)\s*$/$1/;

                    $argument_name =~ s/^\s*(.*?)\s*$/$1/;
                } else {
                    die "$file: $.: syntax error: '$argument'\n";
                }
                $argument_types[$n] = $argument_type;
                $argument_names[$n] = $argument_name;
                # print "  " . ($n + 1) . ": '$argument_type': '$argument_name'\n";
            }
            if($#argument_types == 0 && $argument_types[0] =~ /^void$/i) {
                $#argument_types = -1;
                $#argument_names = -1;
            }

	    @arguments = ();
            foreach my $n (0..$#argument_types) {
		if($argument_names[$n] && $argument_names[$n] ne "...") {
		    if($argument_types[$n] !~ /\*$/) {
			$arguments[$n] = $argument_types[$n] . " " . $argument_names[$n];
		    } else {
			$arguments[$n] = $argument_types[$n] . $argument_names[$n];
		    }
		} else {
		    $arguments[$n] = $argument_types[$n];
		}
	    }

	    $arguments = join(", ", @arguments);
	    if(!$arguments) { $arguments = "void"; }

	    if((!$invert && $name =~ /$pattern/) || ($invert && $name !~ /$pattern/)) {
		if($calling_convention) {
		    print "$return_type $calling_convention $name($arguments)\n";
		} else {
		    if($return_type =~ /\*$/) {
			print "$return_type$name($arguments)\n";
		    } else {
			print "$return_type $name($arguments)\n";
		    }
		}
	    }
        } elsif(/\'(?:[^\\\']*|\\.)*\'/s) {
            $_ = $'; $again = 1;
        } elsif(/\"(?:[^\\\"]*|\\.)*\"/s) {
            $_ = $'; $again = 1;
        } elsif(/;/s) {
            $_ = $'; $again = 1;
        } elsif(/extern\s+"C"\s+{/s) {
            $_ = $'; $again = 1;
        } elsif(/\{/s) {
            $_ = $'; $again = 1;
            $level++;
        } else {
            $lookahead = 1;
        }
    }
    close(IN);
}
