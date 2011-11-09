#! /usr/bin/perl

use strict;
use warnings;
use YAML 'LoadFile';
use FindBin '$RealBin';


=head1 NAME

_otterlace_build_config.pl - calculate config for otterlace_build

=head1 DESCRIPTION

Otterlace builds require a zmap build directory, a build host, maybe
some other configuration to set the destination, and the sources for
otterlace.

This script outputs shell-useful build spec.

=head2 Rationale

It has for various reasons not been possible to calculate the build
directory from anything.  This script therefore requires that as
input.

It has also sometimes not been possible to calculate the otterlace
build host from the arch & distro; the full set of
C<< {lenny,lucid}-dev{32,64} >> are not always available.


=head2 Operations

For a list of build directories and some (hopefully stable) data, we
can produce either

=over 4

=item *

The set of Otterlace build hosts

=item *

The one build directory (chosen from the set of inputs) for a
particular Otterlace build host.

This program is called to reproduce the main calculation multiple
times, in order to answer these queries; but that is easier than
passing structured data back to the calling shell, or taking control
of the build as another wrapper on the outside.

=back

=cut

our %CONFIG; # populated in read_config

sub main {
    # What to do?
    my ($op, $for_host);
    if (@ARGV > 2 && $ARGV[0] eq '-host') {
        ($op, $for_host) = splice @ARGV, 0, 2;
    }
    my @zmapdirs = @ARGV;

    # Sane?
    my @bad = grep { ! -d $_ || ! -d "$_/ZMap" || ! -d "$_/Dist" } @zmapdirs;
    if (!@zmapdirs || @bad) {
        my $usage = "Syntax: $0 [ -host <buildhost> ] <ZMap_build_tree>*\n
  Without -host flag, output the set of Otterlace build hosts for
  these ZMap trees.\n
  When given a buildhost (which must be from that set), return the one
  ZMap tree which should be used on the host.\n";

        die "Not ZMap build directories: @bad\n\n$usage" if @bad;
        die $usage;
    }

    # Read config
    my $cfg_fn = "$RealBin/../build-config.yaml"; # TODO: a flag
    eval { read_config($cfg_fn) } or
      die "$0: Failed to read $cfg_fn: $@";

    # Mappings: find the ZMap build hosts
    my %zhost2dir = zhosts(@zmapdirs);

    # Mappings: find the ones we want, then whinge about new ones
    my %ohost2dir;
    while (my ($zhost, $dir) = each %zhost2dir) {
        my $ohost = $CONFIG{zhost2ohost}{$zhost};
        $ohost2dir{$ohost} = $dir if defined $ohost;
    }
    my @unk_zhost = sort
      grep { !exists $CONFIG{zhost2ohost}{$_} } keys %zhost2dir;
    die "$0: unknown (new?) zmap build hosts\n".
      "  Please tell me about: @unk_zhost\n" if @unk_zhost;

    # Output
    my @ohost = sort keys %ohost2dir;
    if (!defined $op) {
        print join '', map {"$_\n"} @ohost;
    } else {
        my $dir = $ohost2dir{$for_host};
        die "$0: $for_host is not an Otterlace build host\n".
          "  Valid hosts are (@ohost)\n" unless defined $dir;
        printf("%s\n", $dir);
    }

    return 0;
}

sub zhosts {
    my @dir = @_;
    my %h2d; # output

    foreach my $dir (sort @dir) {
        # sort makes it stable, but not always chronological.
        # order should not matter

        # Assumption: the build for each arch has one symlink pointing to it
        opendir my $dh, $dir or die "Scan $dir: $!";
        my @link = grep { -l $_ } map {"$dir/$_"} readdir $dh;
        die "No symlinks in $dir - all builds failed?" unless @link;

        # Assumption: each symlink points to ZMap.$HOST/$BLAH
        foreach my $ln (@link) {
            my $dest = readlink $ln;
            die "$0: readlink $ln: $!" unless defined $dest;
            die "$0: $ln -> $dest: cannot comprehend this" unless
              $dest =~ m{(?:^|/)ZMap\.([-a-zA-Z0-9.]+)(/|$)};
            my $host = $1;
            # Alternations in regexp are an attempt to second-guess changes

            $h2d{$host} = $dir;
        }
    }
    return %h2d;
}

sub read_config {
    my ($fn) = @_;
    my @cfg = LoadFile($fn);
    die "Expected one hash" unless eval { $cfg[0]{zhost2ohost} };
    %CONFIG = %{ shift @cfg };
    return 1;
}


exit main();
