#!/bin/sh

# Exit on first error.
set -e -o pipefail

function fatal()
{
	echo "${0##*/}: $*" >&2
	exit 1
}

if [ "`id -u`" = "0" ]; then
	fatal "Do not work on web content as root"
fi

if [ $# -ne 1 ]; then
	fatal "Please provide the directory name"
fi

# Try to detect the most common and dangerous misuse - running this script
# right on a vhost home directory, which would have devastating results.
if [ -e "$1/public_html" -o -e "$1/.bash_profile" ]; then
	fatal "The directory must be within public_html or equivalent"
fi

# Files matching this don't need to be readable by Apache directly.  This set
# is somewhat Drupal-specific.  We might not have the setup to run Python and
# Perl scripts of mode 600, but we do need to restrict their permissions.
F600='( -name *.php* -o -name *.inc -o -name *.module -o -name *.install -o -name *.info -o -name *.py -o -name *.pl -o -name *~ -o -name *.swp -o -name *.orig -o -name *.rej -o -name CHANGELOG* )'
# These shouldn't be found in Drupal, but we need to restrict access to them if
# they are present - and mode 700 is right under our environment.
F700='-name *.cgi'

D700='( -name CVS -o -name .svn )'

# We assume that the target directory tree is trusted and does not change from
# under us.  Also, we assume that the initial directory permissions are
# sufficient for us to be able to traverse the tree and chmod the files;
# otherwise we'd have to fix directory permissions first, which could expose
# unsafe file permissions to a greater extent for a moment.

# Disable wildcard expansion ("-f"), and print each command ("-x").
set -fx

find "$1" -type f $F600 ! -perm 600 -print0 | xargs -0r chmod 600 --
find "$1" -type f $F700 ! -perm 700 -print0 | xargs -0r chmod 700 --
find "$1" -type f ! $F600 -a ! $F700 ! -perm 644 -print0 |
	xargs -0r chmod 644 --
find "$1" -type d $D700 ! -perm 700 -print0 | xargs -0r chmod 700 --
find "$1" -type d ! $D700 ! -perm 711 -print0 | xargs -0r chmod 711 --
