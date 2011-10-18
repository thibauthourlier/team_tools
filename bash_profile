# -*- Shell-script -*-

PATH="\
/software/perl-5.12.2/bin:\
$PATH\
"

# anacode environment
anacode_dir=/software/anacode

# distro-specific directories, appended first so that their contents
# will override the contents of distro-independent directories

# we must use the full path to anacode_distro_code as $anacode_dir/bin
# is not yet on $PATH

anacode_distro_code="$( $anacode_dir/bin/anacode_distro_code )"
if [ -n "$anacode_distro_code" ]
then
    anacode_distro_dir="$anacode_dir/distro/$anacode_distro_code"
    if [ -d "$anacode_distro_dir" ]
    then

        PATH="\
$PATH\
:$anacode_distro_dir/bin\
"

        PERL5LIB="\
$PERL5LIB\
:$anacode_distro_dir/lib\
:$anacode_distro_dir/lib/site_perl\
"

    fi
fi

# distro-independent directories

PATH="\
$PATH\
:$anacode_dir/bin\
"

PERL5LIB="\
$PERL5LIB\
:$anacode_dir/lib\
:$anacode_dir/lib/site_perl\
"

# team_tools environment

if true &&
    [ -n "$ANACODE_TEAM_TOOLS" ] &&
    [ -d "$ANACODE_TEAM_TOOLS" ]
then

    PATH="\
$PATH\
:$ANACODE_TEAM_TOOLS/bin\
:$ANACODE_TEAM_TOOLS/otterlace/server/bin\
:$ANACODE_TEAM_TOOLS/otterlace/release/scripts\
"

    PERL5LIB="\
$PERL5LIB\
:$ANACODE_TEAM_TOOLS/perl/lib\
"

fi

PERL5LIB="${PERL5LIB#:}" # in case $PERL5LIB was originally empty

export PATH PERL5LIB

export no_proxy=localhost
export http_proxy=http://webcache.sanger.ac.uk:3128

CVS_RSH=ssh
export CVS_RSH

unset \
    anacode_dir \
    anacode_distro_code \

