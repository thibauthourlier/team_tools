
package SangerPaths;

use strict;
use warnings;

my $ensembl_root =
    "/nfs/WWWdev/SHARED_docs/lib/ensembl-branch-";
die sprintf "invalid script path '%s'", $0
    unless
    my ($otterlace_server_root) = # NB: untainted by the pattern match
    $0 =~ m(\A(.*)/cgi-bin/);
my $otter_root =
    "${otterlace_server_root}/lib/otter";

# patch the environment to prevent ServerScriptSupport.pm throwing an
# error when running from the command line
$ENV{SCRIPT_NAME} ||= $0;
$ENV{SCRIPT_FILENAME} ||= $0;
$ENV{DOCUMENT_ROOT} = "${otterlace_server_root}/htdocs";
$ENV{HTTP_CLIENTREALM} = 'sanger'; # emulate a local user

# set error-wrapping
$Bio::Otter::ServerScriptSupport::ERROR_WRAPPING_ENABLED =
    $ENV{OTTERLACE_ERROR_WRAPPING_ENABLED} ? 1 : 0;

# disable compression
$Bio::Otter::ServerScriptSupport::COMPRESSION_ENABLED = 0;

sub import {
    my ( $package, @tags ) = @_;

    # extract the version numbers from the import tags

    my ( $ensembl_version, $otter_version, $humpub );

    foreach my $tag (@tags ) {
        my $version;
        ($version) = $tag =~ /^ensembl(.*)$/;
        $ensembl_version = $version if defined $version;
        ($version) = $tag =~ /^otter(.*)$/;
        $otter_version   = $version if defined $version;
        ($humpub) = $tag =~ /^humpub$/;
    }

    die "the ensembl version is not defined"
        unless defined $ensembl_version;
    die "the otter version is not defined"
        unless defined $otter_version;

    # set up the include path
    unshift @INC,
    ( map {
        sprintf '%s%s/%s', $ensembl_root, $ensembl_version, $_;
      } qw(
      modules
      ensembl/modules
      ensembl-variation/modules
      ), ),
    ( sprintf '%s/%s', $otter_root, $otter_version ),
    ;

    unshift @INC, sprintf('%s/lib/humpub', $otterlace_server_root) if $humpub;

    return;
}

1;