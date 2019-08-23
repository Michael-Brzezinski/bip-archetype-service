#!/bin/sh

## turn on to assist debugging ##
# export PS4='[$LINENO] '
# set -x
##

echo "Initializing ..."

args="$@"
previous_opt=""
doBuildFirst=false

maven_phases="initialize"
maven_args="-Pfortify-sca"

artifactVersion=`grep -m 1 "<version>" pom.xml | cut -d "<" -f2 | rev | cut -d ">" -f1 | rev`
fortifyVersion=`sourceanalyzer -version`

## get argument options off of the command line        ##
## required parameter: array of command-line arguments ##
## scope: private (internal calls only)                ##
function get_args() {
	# echo "+>>    args: \"$@\""
	while getopts ":hb" opt; do
		# echo "+>>    opt=$opt OPTARG=$OPTARG"
		previous_opt="$opt"
		case "$opt" in
			h )
				echo ""
				echo "Usage: $thisScript [-h|-b]"
				echo "Runs fortify on the project, and merges into the root FPR."
				echo "Options:"
				echo "  -h   show this help."
				echo "  []   (no arg) do not build the project before running Fortify."
				echo "  -b   build the project before running Fortify."
				echo ""
				exit 0
				;;
			b )
				doBuildFirst=true
				;;
			\? )
				echo "+>> ERROR: unknown argument \"$opt\""
				exit 1
				;;
		esac
	done
	# shift $((OPTIND -1))
	# echo "+>>    OPTIND=$OPTIND"
}

echo ""
echo "====================================================="
echo "Fortify Scan & Merge for BIP Framework"
echo "Artifact version: $artifactVersion"
echo "SCA version: $fortifyVersion"
echo "====================================================="
echo ""

get_args $args

if [ $doBuildFirst ]; then
	echo "* Project will be built before running Fortify"
	echo "  Run './fortify -h' to see options."
	read -p "  Press Enter to continue, Ctrl+C to abort: "

	echo "+>> mvn clean install -U"
	mvn clean install -U
	if [ "$?" -ne "0" ]; then echo "Error: processing error."; exit 2; fi;
else
	echo "* Project will NOT be built before running Fortify"
	echo "  Run './fortify -h' to see options."
	read -p "  Press Enter to continue, Ctrl+C to abort: "
fi
echo ""

echo "+>> mvn initialize -Pfortify-sca"
mvn initialize -Pfortify-sca
if [ "$?" -ne "0" ]; then echo "Error: processing error."; exit 2; fi;

echo "sleep 2"
sleep 2

echo "+>> mvn antrun:run@fortify-merge -Pfortify-merge"
mvn antrun:run@fortify-merge -Pfortify-merge
if [ "$?" -ne "0" ]; then echo "Error: processing error."; exit 2; fi;

echo "==== Done ===="
echo ""