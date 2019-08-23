#!/bin/sh

## turn on to assist debugging ##
# export PS4='[$LINENO] '
# set -x
##

###############################################################################
#   VARIABLES
###############################################################################

########## useful variables

OIFS=$IFS
cwd=`pwd`
thisScript="$0"
thisFileName=$(basename -- "$0" | cut -d'.' -f1)
args="$@"
returnStatus=0

########## known script variables

### location of log output file
logfile="$cwd/$thisFileName.log"
### name of the file with swa script properties
propertiesFileName="swa-prep.properties"
### name of the request form PDF file
pdfFileName="VA Secure Code Review Validation Request Form.pdf"
### the directory with default files (properties & PDF) for the project
defaultsDir="./defaults"
### the directory with version release tag files (properties & PDF) for the project
tagsDir="./tags"

########## script variables from swa-prep.properties WITH DEFAULT VALUES

### the directory that Fortify SCA is installed under, eg /Applications/Fortify/Fortify_SCA_and_Apps_18.20
fortifyInstallDir="/Applications/Fortify/Fortify_SCA_and_Apps_18.20"
### Base output directory for prep files, eg ~/Documents/SwA_code_review/
outputDir="~/Documents/SwA_code_review/"
### the release version of the tag to be reviewed by SwA, default derived from git repo
releaseVersion="$(git describe --abbrev=0 --tags)"

########## derived script variables

### clone URL for project to be submitted, derived from local git repo
cloneUrl="" #eg "https://github.com/department-of-veterans-affairs/bip-framework.git"
### the project name from $cloneUrl
projectName=""
### fortify version in use, derived from sourceanalyzer -version
fortifyVersion="18.20"
### the project properties file to use, derived as ./$tagsDir/$releaseVersion
propertiesFile=""
### the directory with input files (properties & PDF) for the project, derived as $inputDir/$propertiesFileName
inputDir=""
### location of submission Files, derived as $outputDir/$projectName-$releaseVersion/submission-files
submissionFilesDir=""

################################################################################
#########################                              #########################
#########################   SCRIPT UTILITY FUNCTIONS   #########################
#########################                              #########################
################################################################################

## function to exit the script immediately ##
## arg1 (optional): exit code to use        ##
## scope: private (internal calls only)    ##
function exit_now() {
	#  1 = error from a bash command
	#  5 = invalid command line argument
	#  6 = property not allocated a value
	# 10 = project directory already exists

	exit_code=$1
	if [ -z $exit_code ]; then
		exit_code="0"
	elif [ "$exit_code" -eq "0" ]; then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
		echo " PREP ACTIVITIES COMPLETE" 2>&1 | tee -a "$logfile"
		echo "" 2>&1 | tee -a "$logfile"
		echo "##################################################################################" 2>&1 | tee -a "$logfile"
		echo "## Complete instructions for app registration and code review submission at: " 2>&1 | tee -a "$logfile"
		echo "##   Docs: https://wiki.mobilehealth.va.gov/display/OISSWA/Public+Document+Library" 2>&1 | tee -a "$logfile"
		echo "##   FAQ:  https://wiki.mobilehealth.va.gov/display/OISSWA/Frequently+Asked+Questions" 2>&1 | tee -a "$logfile"
		echo "## Prepared files are in \"$submissionFilesDir\"" 2>&1 | tee -a "$logfile"
		echo "## Submit the package to SwA." 2>&1 | tee -a "$logfile"
		echo "##   Submission ZIP: $outputDir/$reactorName-$releaseVersion/submission-files-$reactorName-$releaseVersion.zip" 2>&1 | tee -a "$logfile"
		echo "##   See: https://wiki.mobilehealth.va.gov/pages/viewpage.action?pageId=26774489" 2>&1 | tee -a "$logfile"
		echo "##################################################################################" 2>&1 | tee -a "$logfile"
		echo "" 2>&1 | tee -a "$logfile"
	else
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
		echo " ***   BUILD FAILED (exit code $exit_code)   ***" 2>&1 | tee -a "$logfile"
		echo "" 2>&1 | tee -a "$logfile"
		# check exit codes
		if [ "$exit_code" -eq "1" ]; then
			echo "Command error. See output at end of $logfile"
		elif [ "$exit_code" -eq "5" ]; then
			# Invalie command line argument
			echo " ERROR: Invalid command-line argument \"$OPTARG\" (use \"$thisScript -h\" for help) ... aborting immediately" 2>&1 | tee -a "$logfile"
		elif [ "$exit_code" -eq "6" ]; then
			# One or more properties not set
			echo " ERROR: \"$propertiesFile\" does not provide values for the following properties:" 2>&1 | tee -a "$logfile"
			echo "        $missingProperties" 2>&1 | tee -a "$logfile"
		elif [ "$exit_code" -eq "8" ]; then
			# Git tag does not exist for project
			echo " ERROR: Release tag \"$releaseVersion\" does not exist in project \"$projectName\"" 2>&1 | tee -a "$logfile"
			echo "        Release tag must be one of: $tagList" 2>&1 | tee -a "$logfile"
		else
			# some unexpected error
			echo " Unexpected error code: $exit_code ... aborting immediately" 2>&1 | tee -a "$logfile"
		fi
	fi
	echo "" 2>&1 | tee -a "$logfile"
	echo " Help: \"$thisScript -h\"" 2>&1 | tee -a "$logfile"
	echo " Logs: \"$logfile\"" 2>&1 | tee -a "$logfile"
	echo "------------------------------------------------------------------------" 2>&1 | tee -a "$logfile"
	# exit
	exit $exit_code
}


## function to display help             ##
## scope: private (internal calls only) ##
function show_help() {
	echo "" 2>&1 | tee -a "$logfile"
	echo "Usage: $thisScript [-h]" 2>&1 | tee -a "$logfile"
	echo "Prepares the project files for \"Secure Code Review\" submission to SwA." 2>&1 | tee -a "$logfile"
	echo "  - If the project has never before been set up for SwA submission, sets up required files." 2>&1 | tee -a "$logfile"
	echo "  - If the project is already set up for this process, prepares the files for SwA submission." 2>&1 | tee -a "$logfile"
	echo "Examples:" 2>&1 | tee -a "$logfile"
	echo "  $thisScript -h  :: show this help" 2>&1 | tee -a "$logfile"
	echo "  $thisScript     :: prep project files for SwA submission" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
	# if we are showing this, force exit
	exit_now
}

## get argument options off of the command line        ##
## required parameter: array of command-line arguments ##
## scope: private (internal calls only)                ##
function get_args() {
	# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
	# echo "+>> Processing command-line arguments" 2>&1 | tee -a "$logfile"
	#
	# echo "+>>    args: \"$@\""
	while getopts "h" opt; do
		echo "+>>    opt=$opt OPTARG=$OPTARG"
		case "$opt" in
			h )
				show_help # exits the script
				;;
			\? )
				exit_now 5
				;;
		esac
		previous_opt="$opt"
	done
	# shift $((OPTIND -1))
	# echo "+>>    OPTIND=$OPTIND"
}


################################################################################
########################                                ########################
########################   BUSINESS UTILITY FUNCTIONS   ########################
########################                                ########################
################################################################################

## function to check exit status from commands ##
## arg (required): command exist status "$?"   ##
## scope: private (internal calls only)        ##
function check_exit_status() {
	returnStatus="$1"
	if [ "$returnStatus" -eq "0" ]; then
		echo "[OK]" 2>&1 | tee -a "$logfile"
	else
		exit_now "$1"
	fi
}

## function to change directories              ##
## arg (required): directory to change to      ##
## scope: private (internal calls only)        ##
function cd_to() {
	cd_dir=${1/"~"/$HOME}
	echo "·········································································" 2>&1 | tee -a "$logfile"
	echo "cd $cd_dir" 2>&1 | tee -a "$logfile"
	# tee does not play well with some bash commands, so just redirect output to the log
	cd "$cd_dir" 2>&1 >> "$logfile"
	check_exit_status "$?"
	echo "+>> pwd = `pwd`" 2>&1 | tee -a "$logfile"
	echo "···" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
}

function mk_dir() {
	the_dir=${1/"~"/$HOME}
	echo "···" 2>&1 | tee -a "$logfile"
	echo "mkdir -pv $the_dir" 2>&1 | tee -a "$logfile"
	mkdir -pv $the_dir 2>&1 >> "$logfile"
	check_exit_status "$?"
	echo "ls $the_dir" 2>&1 >> "$logfile"
	ls $the_dir
	check_exit_status "$?"
	echo "···" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
}

function cp_files() {
	cp_from=${1/"~"/$HOME}
	cp_to=${2/"~"/$HOME}
	echo "···" 2>&1 | tee -a "$logfile"
	echo "cp -f $cp_from $cp_to" 2>&1 | tee -a "$logfile"
	cp -f "$cp_from" "$cp_to" 2>&1 >> "$logfile"
	check_exit_status "$?"
	echo "···" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
}

## function to print current variable values   ##
## arg (required): directory to change to      ##
## scope: private (internal calls only)        ##
function print_vars() {
	echo "" 2>&1 | tee -a "$logfile"
	echo "·········································································" 2>&1 | tee -a "$logfile"
	echo "+>> pwd=`pwd`" 2>&1 | tee -a "$logfile"
	echo "+>> cwd=$cwd" 2>&1 | tee -a "$logfile"
	echo "+>> thisScript=$thisScript" 2>&1 | tee -a "$logfile"
	echo "+>> thisFileName=$thisFileName" 2>&1 | tee -a "$logfile"
	echo "+>> args=$args" 2>&1 | tee -a "$logfile"
	echo "+>> returnStatus=returnStatus" 2>&1 | tee -a "$logfile"
	echo "+>> logfile=$logfile" 2>&1 | tee -a "$logfile"
	echo "+>> propertiesFileName=$propertiesFileName" 2>&1 | tee -a "$logfile"
	echo "+>> pdfFileName=$pdfFileName" 2>&1 | tee -a "$logfile"
	echo "+>> defaultsDir=$defaultsDir" 2>&1 | tee -a "$logfile"
	echo "+>> tagsDir=$tagsDir" 2>&1 | tee -a "$logfile"
	echo "+>> fortifyInstallDir=$fortifyInstallDir" 2>&1 | tee -a "$logfile"
	echo "+>> outputDir=$outputDir" 2>&1 | tee -a "$logfile"
	echo "+>> releaseVersion=$releaseVersion" 2>&1 | tee -a "$logfile"
	echo "+>> cloneUrl=$cloneUrl" 2>&1 | tee -a "$logfile"
	echo "+>> projectName=$projectName" 2>&1 | tee -a "$logfile"
	echo "+>> propertiesFile=$propertiesFile" 2>&1 | tee -a "$logfile"
	echo "+>> inputDir=$inputDir" 2>&1 | tee -a "$logfile"
	echo "+>> submissionFilesDir=$submissionFilesDir" 2>&1 | tee -a "$logfile"
}

################################################################################
############################                        ############################
############################   BUSINESS FUNCTIONS   ############################
############################                        ############################
################################################################################

## function to fork and PR reference changes ##
## arg: none                                 ##
## scope: private (internal calls only)      ##
function prep_app() {
	cd_to "$cwd"

	echo "+>> git pull" 2>&1 | tee -a "$logfile"
	git pull 2>&1 >> "$logfile"
	check_exit_status "$?"

	echo "+>> cloneUrl=\$(git config --get remote.origin.url | grep https)" 2>&1 | tee -a "$logfile"
	cloneUrl="$(git config --get remote.origin.url | grep https)"
	check_exit_status "$?"

	projectName="${cloneUrl##*/}"
	projectName="${projectName%*.git}"
}

## function to set derived values based on current props & user input ##
## arg: none                                                          ##
## scope: private (internal calls only)                               ##
function set_derived_values() {
	### already set by prep_app(): cloneUrl; projectName

	outputDir="${outputDir/"~"/$HOME}"
	inputDir="$tagsDir/$releaseVersion"
	propertiesFile="$inputDir/$propertiesFileName"
	submissionFilesDir="$outputDir/$projectName-$releaseVersion/submission-files"

	fortifyVersionRemoveThis="Fortify Static Code Analyzer " 2>&1 >> "$logfile"
	fortifyVersion=$(sourceanalyzer -version) 2>&1 >> "$logfile"
	fortifyVersion=${fortifyVersion#"$fortifyVersionRemoveThis"} 2>&1 >> "$logfile"
	fortifyVersion=$(echo $fortifyVersion | cut -d' ' -f 1) 2>&1 >> "$logfile"
	fortifyVersion=(${fortifyVersion//./ })
	fortifyVersion="${fortifyVersion[0]}.${fortifyVersion[1]}"
}

## function to populate property vars from $propertiesFile ##
## arg: none                                               ##
## scope: private (internal calls only)                    ##
function read_properties() {
	tmpFile=""
	if [ -d "$inputDir" ] && [ -f "$propertiesFile" ]; then
		tmpFile="$propertiesFile"
		echo "+>> found properties file \"$tmpFile\""
	elif [ -d "$defaultsDir" ] && [ -f "$defaultsDir/$propertiesFileName" ]; then
		tmpFile="$defaultsDir/$propertiesFileName"
		echo "+>> found properties file \"$tmpFile\""
	fi

	if [ "$tmpFile" == "" ] || [ ! -f "$tmpFile" ]; then
		echo "*** WARN Properties File \"$defaultsDir/$propertiesFileName\" is missing." 2>&1 | tee -a "$logfile"
	else
		echo "+>> Reading property values declared in $tmpFile" 2>&1 | tee -a "$logfile"

		# set up to parse property lines
		IFS='='
		# read file
		# echo "△ start reading file"
		while read line
		do
			if [[ $line != *"#"* && $line != "" ]]; then
				# remove all whitespace from the line
				tuple=`echo "${line//[[:space:]]/}"`
				# get the key and value from the tuple
				theKey=$(echo "$tuple" | cut -d'=' -f 1)
				theVal=$(echo "$tuple" | cut -d'=' -f 2)
				echo "     tuple: $theKey=$theVal" 2>&1 | tee -a "$logfile"

				# assigning values cannot be done using declare or eval - this is what bash reduces us to ...
				if [[ "$theKey" == "swa.prep.fortify.sca.install.dir" ]]; then fortifyInstallDir=$theVal; fi
				if [[ "$theKey" == "swa.prep.output.dir" ]]; then outputDir=$theVal; fi
				if [[ "$theKey" == "swa.prep.release.tag" ]]; then releaseVersion=$theVal; fi
			fi
		done < "$tmpFile"
		IFS=$OIFS
	fi
}

## function to populate property vars from $propertiesFile ##
## arg: none                                               ##
## scope: private (internal calls only)                    ##
function confirm_properties() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
	echo "Confirm Properties" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"

	# --- write the properties file ---
	echo "Absolute path of the Fortify/SCA installation" 2>&1 | tee -a "$logfile"
	if [ "$fortifyInstallDir" == "" ]; then
		echo "  Type or paste the absolute path of the Fortify/SCA installation, then press [Enter] (or Ctrl+C to abort):" 2>&1 | tee -a "$logfile"
		echo "  NO SPACES!! Example: /Applications/Fortify/Fortify_SCA_and_Apps_18.20" 2>&1 | tee -a "$logfile"
		read -p "INPUT: " fortifyInstallDir 2>&1 >> "$logfile"
		check_exit_status "$?"
	else
		tmp=""
		echo "  The path is currently set to: $fortifyInstallDir" 2>&1 | tee -a "$logfile"
		echo "  Press [Enter] to accept the current value, or type or paste a new path (NO SPACES!!) then press [Enter] (or Ctrl+C to abort):" 2>&1 | tee -a "$logfile"
		read -p "INPUT: " tmp 2>&1 >> "$logfile"
		check_exit_status "$?"
		if [ "$tmp" != "" ]; then fortifyInstallDir="$tmp"; fi
	fi
	echo "" 2>&1 | tee -a "$logfile"

	echo "" 2>&1 | tee -a "$logfile"
	echo "Absolute path under which to save SwA files" 2>&1 | tee -a "$logfile"
	if [ "$outputDir" == "" ]; then
		echo "  Type or paste the absolute path under which to save SwA files, then press [Enter] (or Ctrl+C to abort):" 2>&1 | tee -a "$logfile"
		echo "  NO SPACES!! Example: ~/Documents/SwA_Code_Reviews" 2>&1 | tee -a "$logfile"
		read -p "INPUT: " outputDir 2>&1 >> "$logfile"
		check_exit_status "$?"
	else
		tmp=""
		echo "  The path is currently set to: $outputDir" 2>&1 | tee -a "$logfile"
		echo "  Press [Enter] to accept the current value, or type or paste a new path (NO SPACES!!) then press [Enter] (or Ctrl+C to abort):" 2>&1 | tee -a "$logfile"
		read -p "INPUT: " tmp 2>&1 >> "$logfile"
		check_exit_status "$?"
		if [ "$tmp" != "" ]; then outputDir="$tmp"; fi
	fi
	echo "" 2>&1 | tee -a "$logfile"

	echo "" 2>&1 | tee -a "$logfile"
	echo "The project release tag for which SwA files will be prepared" 2>&1 | tee -a "$logfile"
	if [ "$releaseVersion" == "" ]; then
		echo "  Type or paste the project release tag for which SwA files will be prepared, then press [Enter] (or Ctrl+C to abort):" 2>&1 | tee -a "$logfile"
		echo "  Example: 1.0.1" 2>&1 | tee -a "$logfile"
		read -p "INPUT: " releaseVersion 2>&1 >> "$logfile"
		check_exit_status "$?"
	else
		tmp=""
		echo "  The release tag is set to: $releaseVersion" 2>&1 | tee -a "$logfile"
		echo "  To view available tags, open a new terminal window/tab in the project folder and run: git tag" 2>&1 | tee -a "$logfile"
		echo "  Press [Enter] to accept the current value, or type or paste a release tag then press [Enter] (or Ctrl+C to abort):" 2>&1 | tee -a "$logfile"
		read -p "INPUT: " tmp 2>&1 >> "$logfile"
		check_exit_status "$?"
		if [ "$tmp" != "" ]; then releaseVersion="$tmp"; fi
	fi
	echo "" 2>&1 | tee -a "$logfile"
}

## function to prompt user to verify property vars are correct ##
## arg: none                                                   ##
## scope: private (internal calls only)                        ##
function verify_values() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
	echo "Verify Values" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
	echo "Confirm properties and derived values:" 2>&1 | tee -a "$logfile"
	echo "  From \"$propertiesFile\":" 2>&1 | tee -a "$logfile"
	echo "    swa.prep.fortify.sca.install.dir=$fortifyInstallDir" 2>&1 | tee -a "$logfile"
	echo "    swa.prep.output.dir=$outputDir" 2>&1 | tee -a "$logfile"
	echo "    swa.prep.release.tag=$releaseVersion" 2>&1 | tee -a "$logfile"
	echo "  Derived values:" 2>&1 | tee -a "$logfile"
	echo "    Active Fortify SCA version: $fortifyVersion"
	echo "    Project clone url: $cloneUrl" 2>&1 | tee -a "$logfile"
	echo "    Project name: $projectName" 2>&1 | tee -a "$logfile"
	echo "    Properties file: $propertiesFile" 2>&1 | tee -a "$logfile"
	echo "    Input files (props/PDF): $inputDir" 2>&1 | tee -a "$logfile"
	echo "    Location of submission files: $submissionFilesDir" 2>&1 | tee -a "$logfile"
	read -p "Press [Enter] to confirm, or Ctrl+C to abort: " 2>&1 >> "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
}

## function to write PDF and properties to the $inputDir ##
## arg: none                                             ##
## scope: private (internal calls only)                  ##
function write_input_dir() {
	cd_to "$cwd"

	# print_vars

	# create dir if necessary
	if ! [ -d "$inputDir" ]; then
		mk_dir $inputDir
	fi

	if ! [ -f "$inputDir/$pdfFileName" ]; then
		cp_files "$defaultsDir/$pdfFileName" "$inputDir/"
	fi

	# write the file
	echo "+>> Writing properties to: $propertiesFile ..." 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"

	echo "###############################################################################" > "$propertiesFile"
	echo "# SwA Code Review - Properties " >> "$propertiesFile"
	echo "###############################################################################" >> "$propertiesFile"
	echo "" >> "$propertiesFile"
	echo "#" >> "$propertiesFile"
	echo "# Properties related to YOUR LOCAL COMPUTER" >> "$propertiesFile"
	echo "#" >> "$propertiesFile"
	echo "" >> "$propertiesFile"
	echo "### The directory under which the Fortify SCA and Apps are installed" >> "$propertiesFile"
	echo "### NO SPACES ALLOWED, no / on the end" >> "$propertiesFile"
	echo "swa.prep.fortify.sca.install.dir=$fortifyInstallDir" >> "$propertiesFile"
	echo "" >> "$propertiesFile"
	echo "### The directory under which the \"your-project-name\" and prepared files are to be put" >> "$propertiesFile"
	echo "### Directories will be created in this folder for the tag to be reviewed" >> "$propertiesFile"
	echo "### NO SPACES ALLOWED, no / on the end" >> "$propertiesFile"
	echo "swa.prep.output.dir=$outputDir" >> "$propertiesFile"
	echo "" >> "$propertiesFile"
	echo "#" >> "$propertiesFile"
	echo "# Properties related to YOUR GITHUB PROJECT" >> "$propertiesFile"
	echo "#" >> "$propertiesFile"
	echo "" >> "$propertiesFile"
	echo "### The release TAG version to be submitted to SwA" >> "$propertiesFile"
	echo "swa.prep.release.tag=$releaseVersion" >> "$propertiesFile"
	echo "" >> "$propertiesFile"
}

function verify_inputs() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
	echo "Confirm PDF" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"

	echo "Confirm code review request form PDF:" 2>&1 | tee -a "$logfile"
	echo "  Open \"$inputDir/$pdfFileName\"" 2>&1 | tee -a "$logfile"
	echo "  Make any necessary changes, and save the PDF in place." 2>&1 | tee -a "$logfile"
	read -p "When done, press [Enter] to continue, or Ctrl+C to abort: " 2>&1 >> "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
}

## function to prepare the submission folder ##
## arg: none                                 ##
## scope: private (internal calls only)      ##
function prep_output_folder() {
	# make sure directory exists
	if [ ! -d "$outputDir" ]; then
		mk_dir $outputDir
	fi

	cd_to "$outputDir"

	# remove old folder
	echo "+>> rm -rf $outputDir/$projectName-$releaseVersion" 2>&1 | tee -a "$logfile"
	rm -rf "$outputDir/$projectName-$releaseVersion" 2>&1 >> "$logfile"
	check_exit_status "$?"

	# create folder
	mk_dir $submissionFilesDir

	# copy PDF to submission folder
	cp_files "$cwd/tags/$releaseVersion/$pdfFileName" "$submissionFilesDir/"

	cd_to "$projectName-$releaseVersion"

	# git
	echo "+>> git clone $cloneUrl" 2>&1 | tee -a "$logfile"
	git clone "$cloneUrl" 2>&1 >> "$logfile"
	check_exit_status "$?"

	cd_to "$projectName"

	echo "+>> git fetch && git fetch --tags" 2>&1 | tee -a "$logfile"
	git fetch && git fetch --tags 2>&1 >> "$logfile"
	check_exit_status "$?"

	### check that tag exists in the git repo
	echo "+>> git tag --list" 2>&1 | tee -a "$logfile"
	IFS=" "
	tagList=$(git tag --list)
	tagList="${tagList[@]}"
	IFS=$OIFS
	if ! [[ "$tagList" =~ "$releaseVersion" ]]; then
		exit_now 8
	fi

	echo "+>> git checkout $releaseVersion" 2>&1 | tee -a "$logfile"
	git checkout $releaseVersion 2>&1 >> "$logfile"
	check_exit_status "$?"

	# build and scan
	echo "+>> mvn clean install -DskipTests=true -U" 2>&1 | tee -a "$logfile"
	mvn clean install -DskipTests=true -U 2>&1 >> "$logfile"
	check_exit_status "$?"

	### Fortify

	# get the name of the maven reactor module
	echo "+>> reactorName=$(mvn -q -Dexec.executable=echo -Dexec.args=\'\${project.artifactId}\' --non-recursive exec:exec)" 2>&1 | tee -a "$logfile"
	reactorName=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.artifactId}' --non-recursive exec:exec) 2>&1 >> "$logfile"
	check_exit_status "$?"

	mainFpr="`pwd`/$reactorName.fpr"

	# since mvn clean install was previously run, only need to specify initialize to catch the lifecycle phase
	echo "+>> mvn initialize -Pfortify-sca" 2>&1 | tee -a "$logfile"
	mvn initialize -Pfortify-sca 2>&1 >> "$logfile"
	check_exit_status "$?"

	echo "+>> mvn antrun:run@fortify-merge -Pfortify-merge" 2>&1 | tee -a "$logfile"
	mvn antrun:run@fortify-merge -Pfortify-merge 2>&1 >> "$logfile"
	check_exit_status "$?"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
	echo "Confirm FPR" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
	echo "Open \"$mainFpr\" in Fortify Audit Workbench." 2>&1 | tee -a "$logfile"
	echo "	- make sure \"Filter set\" is set to \"Security Auditor View\"" 2>&1 | tee -a "$logfile"
	echo "Confirm that:" 2>&1 | tee -a "$logfile"
	echo "  - scan is free of warnings (all critical/high fixed and/or suppressions applied)" 2>&1 | tee -a "$logfile"
	echo "  - the Summary > Build Information > Build Label value is correct" 2>&1 | tee -a "$logfile"
	read -p "When done, press [Enter] to continue, or Ctrl+C to abort: " 2>&1 >> "$logfile"
	echo "" 2>&1 | tee -a "$logfile"

	# move FPR to submissions folder
	echo "+>> mv $mainFpr $submissionFilesDir/" 2>&1 | tee -a "$logfile"
	mv "$mainFpr" "$submissionFilesDir/" 2>&1 >> "$logfile"
	check_exit_status "$?"
	echo "" 2>&1 | tee -a "$logfile"

	cd_to "$submissionFilesDir"

	# move zipped source files into submissions folder
	echo "+>> FPRUtility -sourceArchive -extract -project $reactorName.fpr -recoverSourceDirectory -f $projectName" 2>&1 | tee -a "$logfile"
	FPRUtility -sourceArchive -extract -project "$reactorName.fpr" -recoverSourceDirectory -f "$projectName" 2>&1 >> "$logfile"
	echo "+>> zip -rq9m $projectName-$releaseVersion.zip $projectName" 2>&1 | tee -a "$logfile"
	zip -rq9m "$projectName-$releaseVersion.zip" "$projectName" 2>&1 >> "$logfile"

	# move rules zip to sumissions folder
	cd_to "$fortifyInstallDir/Core/config"

	echo "+>> zip -rq9 rules.zip rules -x \*.DS_Store Thumbs.db" 2>&1 | tee -a "$logfile"
	zip -rq9 rules.zip rules -x \*.DS_Store Thumbs.db 2>&1 >> "$logfile"
	check_exit_status "$?"

	echo "+>> mv rules.zip $submissionFilesDir/" 2>&1 | tee -a "$logfile"
	mv -f "rules.zip" "$submissionFilesDir/" 2>&1 >> "$logfile"
	check_exit_status "$?"
}

function post_prep_activities() {
	cd_to $submissionFilesDir

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$logfile"
	echo "Review submission files" 2>&1 | tee -a "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
	echo "Review files under \"$submissionFilesDir\"" 2>&1 | tee -a "$logfile"
	# echo "Compare file list under \"Audit Workbench > Project Summary > Build Information > Files\""
	# echo "with \"$submissionFilesDir\"" 2>&1 | tee -a "$logfile"
	# echo "- Delete any files/folders that are not necessary for SwA Code Review." 2>&1 | tee -a "$logfile"
	# echo "- Add back from source as needed, e.g. any generated files under /target" 2>&1 | tee -a "$logfile"
	read -p "When done, press [Enter] to continue, or Ctrl+C to abort: " 2>&1 >> "$logfile"
	echo "" 2>&1 | tee -a "$logfile"

	cd_to ".."

	echo "+>> zip -rq9 submission-files-$projectName-$releaseVersion.zip submission-files -x \*.DS_Store Thumbs.db" 2>&1 | tee -a "$logfile"
	zip -rq9 "submission-files-$projectName-$releaseVersion.zip" "submission-files" -x \*.DS_Store Thumbs.db 2>&1 >> "$logfile"
	echo "" 2>&1 | tee -a "$logfile"
}

################################################################################
#######################                                  #######################
#######################   SCRIPT EXECUTION BEGINS HERE   #######################
#######################                                  #######################
################################################################################

### output header info, get the log started ##
echo ""  2>&1 | tee "$logfile"
echo "=========================================================================" 2>&1 | tee -a "$logfile"
echo "Prepare Project Files for SwA Code Review Submission" 2>&1 | tee -a "$logfile"
echo "=========================================================================" 2>&1 | tee -a "$logfile"
echo "" 2>&1 | tee -a "$logfile"

### call each function in order ##
get_args $args
### pull, get vars from clone URL, etc
prep_app
### set the initial derived values based on scripted defaults (no props yet)
set_derived_values
### read available properties from defaults or existing tag dir
read_properties
### confirm or get properties from user
confirm_properties
### set the final derived values based on props & user input
set_derived_values
### get confirmation that the properties are correct
verify_values
### write files to the release inputs directory to be copied to submission dir
write_input_dir
### get confiremation that the PDF is correct
verify_inputs
### create working folder if necessary (exits with messages if folder must be created)
prep_output_folder
### final cleanup and instructions
post_prep_activities

### print instructions and exit
exit_now 0
