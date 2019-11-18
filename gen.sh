#!/bin/sh

## turn on to assist debugging ##
#export PS4='[$LINENO] '
#set -x
##

# useful variables
cwd=`pwd`
thisScript="$0"
thisFileName=$(basename -- "$0" | cut -d'.' -f1)
args="$@"
returnStatus=0
# script variables
propertiesFile="$thisFileName.properties"
removeOnly=-1
overwriteExisting=-1
skipBuild=-1
doDockerBuild="-Ddockerfile.skip=true"
originDirName="bip-archetype-service-origin"
originGroupId="gov.va.bip.origin"
genLog="$cwd/$thisFileName.log"

# git variables
cgb=$(git rev-parse --abbrev-ref HEAD)
gitRemote=""
gitBranchBaseline="master"
gitBranchDb="master-db"
bitBranchPartner="master-partner"

###   properties   ###
# required in properties file
groupId=""
artifactId=""
version=""
artifactName=""
artifactNameLowerCase=""
artifactNameUpperCase=""
servicePort=""
projectNameSpacePrefix=""
nexusRepoUrl=""
frameworkVersion=""
components=()
prepBranch=""

################################################################################
#########################                              #########################
#########################   SCRIPT UTILITY FUNCTIONS   #########################
#########################                              #########################
################################################################################

## function to exit the script immediately ##
## arg1 (optional): exit code to use       ##
## scope: private (internal calls only)    ##
function exit_now() {
	#  1 = error from a bash command
	#  5 = invalid command line argument
	#  6 = property not allocated a value
	# 10 = project directory already exists
	# 11 = One or more properties not set
	# 12 = prep branch could not be deleted
	# 13 = master branch checkout failed
	# other exit code = some unexpected error

	exit_code=$1
	if [ -z $exit_code ]; then
		exit_code="0"
	elif [ "$exit_code" -eq "0" ]; then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
		echo " BUILD COMPLETE" 2>&1 | tee -a "$genLog"
		echo "" 2>&1 | tee -a "$genLog"
		echo " ##################################################################################" 2>&1 | tee -a "$genLog"
		echo " ## 1. Move $artifactId to a valid location in your local git repo." 2>&1 | tee -a "$genLog"
		echo " ## 2. Build and test $artifactId." 2>&1 | tee -a "$genLog"
		echo " ## 3. Use git to initialize, commit, and register with the remote repo. " 2>&1 | tee -a "$genLog"
		echo " ## SEE: https://github.com/department-of-veterans-affairs/bip-archetype-service " 2>&1 | tee -a "$genLog"
		echo " ##################################################################################" 2>&1 | tee -a "$genLog"
		echo "" 2>&1 | tee -a "$genLog"
	else
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
		echo " ***   FAILURE (exit code $exit_code)   ***" 2>&1 | tee -a "$genLog"
		echo "" 2>&1 | tee -a "$genLog"
		# check exit codes
		if [ "$exit_code" -eq "1" ]; then
			echo "Command error. See output at end of $genLog"
		elif [ "$exit_code" -eq "2" ]; then
			# Invalie command line argument
			echo "ERROR: Docker must be running for command-line argument \"-$OPTARG\" (use \"$thisScript -h\" for help) ... aborting immediately" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "5" ]; then
			# Invalie command line argument
			echo "ERROR: Invalid command-line argument \"-$OPTARG\" (use \"$thisScript -h\" for help) ... aborting immediately" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "6" ]; then
			# One or more properties not set
			echo "ERROR: \"$propertiesFile\" does not provide values for the following properties:" 2>&1 | tee -a "$genLog"
			echo "        $missingProperties" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "7" ]; then
			# Project already exists, no over-write arg
			echo "ERROR: \"$artifactId\" project already exists ... aborting immediately" 2>&1 | tee -a "$genLog"
			echo "        Delete/move the project, or start this script with the -o option" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "8" ]; then
			# No project to remove
			echo "ERROR: Could not remove \"$artifactId\". Does not exist." 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "10" ]; then
			# One or more properties not set
			echo "ERROR: Directory \"$artifactId\" already exists. Delete the directory " 2>&1 | tee -a "$genLog"
			echo "        or execute this generate script and properties in another directory. " 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "11" ]; then
			# One or more properties not set
			echo "ERROR: Could not find bip-framework version '$frameworkVersion'" 2>&1 | tee -a "$genLog"
			echo "        To make bip-framework available, provide one of the following:" 2>&1 | tee -a "$genLog"
			echo "        1. Access to BIP Nexus Repository at '$nexusRepoUrl'" 2>&1 | tee -a "$genLog"
			echo "        2. Clone framework from 'https://github.com/department-of-veterans-affairs/bip-framework'" 2>&1 | tee -a "$genLog"
			echo "           and build it with 'mvn clean install -U'" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "20" ]; then
			# prep branch could not be deleted - DON'T TRY TO DELETE IT AGAIN! Will create endless loop
			echo "ERROR: Branch \"$prepBranch\" could not be deleted, Please makse sure the $prepBranch branch can be deleted using: " 2>&1 | tee -a "$genLog"
			echo "        git  branch -D $prepBranch" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "21" ]; then
			# branch checkout failed
			echo "ERROR: A required branch could not be checked out. Check logs for details." 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "22" ]; then
			# too many git remotes
			echo "ERROR: More than one git remote detected. Script currently requires that only one r/w remote be available." 2>&1 | tee -a "$genLog"
			echo "         Existing remotes:" 2>&1 | tee -a "$genLog"
			git remote  2>&1 | tee -a "$genLog"
			echo "        Please 'git remote remove <name>' all but your primary read/write remote (usually 'origin')." 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "23" ]; then
			# missing git remote
			echo "ERROR: Your local archetype repo does not have a remote defined. Please add a remote read/write repo (usually 'origin')." 2>&1 | tee -a "$genLog"
			echo "        Example: git remote add <repo-name> <url>" 2>&1 | tee -a "$genLog"
		elif [ "$exit_code" -eq "24" ]; then
			# One or more properties not set correctly
			echo "ERROR: \"$propertiesFile\" has bad values for the following properties:" 2>&1 | tee -a "$genLog"
			echo "artifactName should start with a letter and be alphanumeric." 2>&1 | tee -a "$genLog"
			echo "artifactNameLowerCase should all be lower case." 2>&1 | tee -a "$genLog"
			echo "artifactNameUpperCase should all be upper case." 2>&1 | tee -a "$genLog"
			echo "        $invalidArtifactName" 2>&1 | tee -a "$genLog"
		else
			# some unexpected error
			echo "ERROR: Unexpected error code: $exit_code ... aborting immediately. Check logs." 2>&1 | tee -a "$genLog"
		fi
	fi
	echo "" 2>&1 | tee -a "$genLog"
	echo " Help: \"$thisScript -h\"" 2>&1 | tee -a "$genLog"
	echo " Logs: \"$genLog\"" 2>&1 | tee -a "$genLog"
	echo "       search: \"+>> \" (script); \"sed: \" (sed); \"FAIL\" (mvn & cmd)" 2>&1 | tee -a "$genLog"
	echo "------------------------------------------------------------------------" 2>&1 | tee -a "$genLog"
	# exit
	exit $exit_code
}


## function to display help             ##
## scope: private (internal calls only) ##
function show_help() {
	echo "" 2>&1 | tee -a "$genLog"
	echo "$thisScript : Generate a new skeleton project from the origin project." 2>&1 | tee -a "$genLog"
	echo "  To generate your new project skeleton:" 2>&1 | tee -a "$genLog"
	echo "  1. Update gen.properties with values for your new project." 2>&1 | tee -a "$genLog"
	echo "  2. Run ./gen.sh (with relevant options) to create the new project." 2>&1 | tee -a "$genLog"
	echo "  3. Move the project folder to your git directory and git initialize it." 2>&1 | tee -a "$genLog"
	echo "Examples:" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -h  show this help" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -r  remove generated new project from disk, then exit script" 2>&1 | tee -a "$genLog"
	echo "  $thisScript     generate project using $thisFileName.properties file" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -s  skip (re)building the Origin source project" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -o  over-write new project if it already exists" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -d  build docker image (docker must be running)" 2>&1 | tee -a "$genLog"
	echo "  $thisScript -so both skip build, and overwrite" 2>&1 | tee -a "$genLog"
	echo "" 2>&1 | tee -a "$genLog"
	echo "Notes:" 2>&1 | tee -a "$genLog"
	echo "* Full instructions available in development branch at:" 2>&1 | tee -a "$genLog"
	echo "  https://github.com/department-of-veterans-affairs/bip-archetype-service/" 2>&1 | tee -a "$genLog"
	echo "* A valid \"$thisFileName.properties\" file must exist in the same directory" 2>&1 | tee -a "$genLog"
	echo "  as this script." 2>&1 | tee -a "$genLog"
	echo "* It is recommended that a git credential helper be utilized to" 2>&1 | tee -a "$genLog"
	echo "  eliminate authentication requests while executing. For more info see" 2>&1 | tee -a "$genLog"
	echo "  https://help.github.com/articles/caching-your-github-password-in-git/" 2>&1 | tee -a "$genLog"
	echo "" 2>&1 | tee -a "$genLog"
	echo "" 2>&1 | tee -a "$genLog"
	# if we are showing this, force exit
	exit_now
}

## get argument options off of the command line        ##
## required parameter: array of command-line arguments ##
## scope: private (internal calls only)                ##
function get_args() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "+>> Processing command-line arguments" 2>&1 | tee -a "$genLog"

	# echo "args: \"$@\""
	#if [ "$@" -eq "" ]; then
	if [[ "$@" == "" ]]; then
		echo "+>> Using properties file \"$propertiesFile\"" 2>&1 | tee -a "$genLog"
	fi
	while getopts ":hrsod" opt; do
		case "$opt" in
			h)
				show_help
				;;
			r)
				removeOnly=0
				echo "+>> - Removing generated new project only" 2>&1 | tee -a "$genLog"
				;;
			s)
				skipBuild=0
				echo "+>> - Skipping build of Origin project" 2>&1 | tee -a "$genLog"
				;;
			o)
				# echo "+>> -o > overwrite" 2>&1 | tee -a "$genLog"
				overwriteExisting=0
				echo "+>> - Existing project will be deleted and recreated if it already exists" 2>&1 | tee -a "$genLog"
				;;
			d)
				# echo "+>> -o > build docker" 2>&1 | tee -a "$genLog"
				doDockerBuild=""
				if ps ax | grep -v grep | grep -v docker.vmnetd | grep com.docker > /dev/null
				then
					echo "+>> - Build docker image (docker must be running)" 2>&1 | tee -a "$genLog"
				else
					exit_now 2
				fi
				;;
			\?)
				exit_now 5
				;;
		esac
		previous_opt="$opt"
	done
	# shift $((OPTIND -1))
}

################################################################################
########################                                ########################
########################   BUSINESS UTILITY FUNCTIONS   ########################
########################                                ########################
################################################################################

function framework_exists() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "cd $cwd" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cd "$cwd" 2>&1 >> "$genLog"
	echo "+>> pwd = `pwd`" 2>&1 | tee -a "$genLog"

	nexusRepoUrl=`grep -m 1 "<url>" bip-archetype-service-origin/pom.xml | cut -d "<" -f2 | cut -d ">" -f2`
	frameworkVersion=`grep -m 1 "<version>" bip-archetype-service-origin/pom.xml | cut -d "<" -f2 | cut -d ">" -f2`
	echo "+>> Checking for existence of bip-framework $frameworkVersion" 2>&1 | tee -a "$genLog"

	mvn dependency:get -Dartifact=gov.va.bip.framework:bip-framework-parentpom:$frameworkVersion:pom -DremoteRepositories=https://nexus.dev.bip.va.gov/repository/maven-public 2>&1 >> "$genLog"
	if [ "$?" -ne "0" ]; then
		exit_now "11"
	fi
	echo "[OK]" 2>&1 | tee -a "$genLog"
}

## function to populate property vars from $propertiesFile ##
## arg: none                                               ##
## scope: private (internal calls only)                    ##
function read_properties() {
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "cd $cwd" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cd "$cwd" 2>&1 >> "$genLog"
	echo "+>> pwd = `pwd`" 2>&1 | tee -a "$genLog"

	if [ ! -f "$propertiesFile" ]; then
		echo "*** ERROR File \"$propertiesFile\" is missing. Cannot generate the project." 2>&1 | tee -a "$genLog"
		# invalid properties will be caught when validate_properties function is called
	else
		echo "" 2>&1 | tee -a "$genLog"
		echo "+>> Reading project properties declared in $propertiesFile" 2>&1 | tee -a "$genLog"

		# set up to parse property lines
		OIFS=$IFS
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
				echo "     tuple: $tuple" 2>&1 | tee -a "$genLog"

				# assigning values cannot be done using declare or eval - this is what bash reduces us to ...
				if [[ "$theKey" == "groupId" ]]; then groupId=$theVal; fi
				if [[ "$theKey" == "artifactId" ]]; then artifactId=$theVal; fi
				if [[ "$theKey" == "version" ]]; then version=$theVal; fi
				if [[ "$theKey" == "artifactName" ]]; then artifactName=$theVal; fi
				if [[ "$theKey" == "artifactNameLowerCase" ]]; then artifactNameLowerCase=$theVal; fi
				if [[ "$theKey" == "artifactNameUpperCase" ]]; then artifactNameUpperCase=$theVal; fi
				if [[ "$theKey" == "servicePort" ]]; then servicePort=$theVal; fi
				if [[ "$theKey" == "projectNameSpacePrefix" ]]; then projectNameSpacePrefix=$theVal; fi
				if [[ "$theKey" == "components" ]]; then
					if ! [[ "$theVal" == "" || "$theKey" == "$theVal" ]]; then
						tempIFS=$IFS
						IFS=','
						read -r -a components <<< "$theVal";
						IFS=$tempIFS
					fi
				fi

			fi
		done < "$cwd/$propertiesFile"
		IFS=$OIFS
	fi
}

## function to validate property vars from $propertiesFile ##
## arg: none                                               ##
## scope: private (internal calls only)                    ##
function validate_properties() {
	# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 2>&1 | tee -a "$genLog"
	echo "+>> Validating project properties declared in $propertiesFile" 2>&1 | tee -a "$genLog"

	missingProperties=""
	if [[ "$groupId" == "" ]]; then missingProperties+="groupId "; fi
	if [[ "$artifactId" == "" ]]; then missingProperties+="artifactId "; fi
	if [[ "$version" == "" ]]; then missingProperties+="version "; fi
	if [[ "$artifactName" == "" ]]; then missingProperties+="artifactName "; fi
	if [[ "$artifactNameLowerCase" == "" ]]; then missingProperties+="artifactNameLowerCase "; fi
	if [[ "$artifactNameUpperCase" == "" ]]; then missingProperties+="artifactNameUpperCase "; fi
	if [[ "$servicePort" == "" ]]; then missingProperties+="servicePort "; fi
	if [[ "$projectNameSpacePrefix" == "" ]]; then missingProperties+="projectNameSpacePrefix "; fi

	if [[ $missingProperties != "" ]]; then
		exit_now 6
	fi

	invalidArtifactName=""
	if [[ !("$artifactName" =~ ^[a-zA-Z_$]{1}[a-zA-Z0-9_$]+$) ]]; then invalidArtifactName+="artifactName "; fi
	if [[ !("$artifactNameLowerCase" =~ ^[a-z_$]{1}[a-z0-9_$]+$) ]]; then invalidArtifactName+="artifactNameLowerCase "; fi
	if [[ !("$artifactNameUpperCase" =~ ^[A-Z_$]{1}[A-Z0-9_$]+$) ]]; then invalidArtifactName+="artifactNameUpperCase "; fi

	if [[ $invalidArtifactName != "" ]]; then
		exit_now 24
	fi
}

## function to check exit status from commands ##
## arg (required): command exist status "$?"   ##
## scope: private (internal calls only)        ##
function check_exit_status() {
	returnStatus="$1"
	if [ "$returnStatus" -eq "0" ]; then
		echo "[OK]" 2>&1 | tee -a "$genLog"
	else
		git_delete_prep_branch
		exit_now "$1"
	fi
}

## function to change directories              ##
## arg (required): directory to change to      ##
## scope: private (internal calls only)        ##
function cd_to() {
	cd_dir="$1"
	echo "cd $cd_dir" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cd "$cd_dir" 2>&1 >> "$genLog"
	check_exit_status "$?"
	echo "+>> pwd = `pwd`" 2>&1 | tee -a "$genLog"
}

##################################################################################
############################                          ############################
############################  GIT UTILITY FUNCTIONS   ############################
############################                          ############################
##################################################################################

## function to test that local repo has 1 remote ##
## and put the remote name into $gitRemote       ##
## arg: none                                     ##
## scope: private (internal calls only)          ##
function git_has_remote() {
	echo "+>> Checking git remote" 2>&1 | tee -a "$genLog"
	tmpRemoteCt=$(git remote | wc -l)
	if [ "$tmpRemoteCt" -gt "1" ]; then
		exit_now "22"
	elif [ "$tmpRemoteCt" -lt "1" ]; then
		exit_now "23"
	fi

	gitRemote="$(git remote)"
}

## function to get the current branch into $gcb ##
## arg: none                                    ##
## scope: private (internal calls only)         ##
function git_current_branch() {
	# tee does not play well with some bash commands, so just redirect output to the log
	echo "git rev-parse --abbrev-ref HEAD" 2>&1 | tee -a "$genLog"
	gcb=$(git rev-parse --abbrev-ref HEAD) 2>&1 >> "$genLog"
}

## function to see if LOCAL repo has a branch ##
## arg: $1 = branch name                      ##
## returns 0 if branch exists, otherwise 1    ##
## scope: private (internal calls only)       ##
function git_has_local_branch() {
	tmp="$1"
	if [ "$tmp" == "" ]; then
		echo "*** ERROR The git_has_local_branch() function requires an argument" 2>&1 | tee -a "$genLog"
		echo exit_now 1
	fi

	# NOTE: return value can only be seen in "$?"
	echo "git rev-parse --verify $tmp" 2>&1 | tee -a "$genLog"
	tmp="$(git rev-parse --verify $tmp)"
	if [ "$tmp" == "" ]; then
		# local branch does NOT exist
		echo "1"
		return 1
	fi
	# local branch DOES exist
	echo "0"
	return 0
}

## function to delete the origin prep branch (created to prepare the origin project with required components ) ##
## arg: none                                               ##
## scope: private (internal calls only)                    ##
function git_delete_prep_branch() {
	if [ "$prepBranch" == "" ]; then
		echo  "+>> WARN Function git_delete_prep_branch() was called but \$prepBranch variable is empty." 2>&1 | tee -a "$genLog"
	else
		git_has_local_branch $prepBranch
		if [ "$?" == "0" ]; then
			# put current branch into $gcb
			git_current_branch
			if [ "$gcb" == "$prepBranch" ]; then
				git_checkout_branch $gitBranchBaseline
			fi
			echo "+>> Deleting branch \"$prepBranch\"" 2>&1 | tee -a "$genLog"
			echo "git branch -D $prepBranch" 2>&1 | tee -a "$genLog"
			git branch -D $prepBranch 2>&1 >> "$genLog"
			if [ "$?" -ne "0" ]; then
				exit_now 20
			fi
			echo "[OK]" 2>&1 | tee -a "$genLog"
		else
			echo  "+>> WARN Function git_delete_prep_branch() was called, but \"$prepBranch\" does not exist." 2>&1 | tee -a "$genLog"
		fi
	fi
}

## function to check if the master branch is checkout out in the git repo ##
## arg: $1 = branch name to check out                                     ##
## scope: private (internal calls only)                                   ##
function git_checkout_branch() {
	tmpGitBranchname="$1"
	if [ "$tmpGitBranchname" == "" ]; then
		echo "*** ERROR function git_checkout_branch() requires 1 argument: <branch-name>" 2>&1 | tee -a "$genLog"
		echo exit_now 1
	fi
	echo "+>> Attempting to check out branch \"$tmpGitBranchname\"" 2>&1 | tee -a "$genLog"

	# put git's current branch into $gcb
	git_current_branch

	if [ "$tmpGitBranchname" == "$gcb" ]; then
		echo "+>> Already on branch \"$tmpGitBranchname\"" 2>&1 | tee -a "$genLog"
		echo "+>> Pulling to ensure up to date"
	else
		echo "git checkout $tmpGitBranchname" 2>&1 | tee -a "$genLog"
		git checkout $tmpGitBranchname 2>&1 >> "$genLog"
		if [ "$?" -ne "0" ]; then
			echo "*** ERROR Could not check out branch \"$tmpGitBranchname\"" 2>&1 | tee -a "$genLog"
			check_exit_status "21"
		fi
		echo "[OK]" 2>&1 | tee -a "$genLog"
	fi
}

## function to create a new branch from current branch to           ##
## prepare the origin project with requried components              ##
## NOTE: after execution, current git branch will be the method arg ##
## arg: #1 = branch-name                                            ##
## scope: private (internal calls only)                             ##
function git_create_prep_branch() {
	tmpGitBranchname="$1"
	if [ "$tmpGitBranchname" == "" ]; then
		echo "*** ERROR function git_create_prep_branch() requires 1 argument: <branch-name>" 2>&1 | tee -a "$genLog"
		echo exit_now 1
	fi
	echo "+>> Preparing to create branch \"$prepBranch\", to prepare the origin project with required components." 2>&1 | tee -a "$genLog"

	# put git's current branch into $gcb
	git_current_branch
	# must currently be in the baseline branch
	if ! [ "$gcb" == "$gitBranchBaseline" ]; then
		echo "*** ERROR current git branch is \"$gcb\" but must be \"$gitBranchBaseline\"" 2>&1 | tee -a "$genLog"
		exit_now 1
	fi

	# set the global prep branch name
	prepBranch="$tmpGitBranchname"

	git_has_local_branch $prepBranch
	if [ "$?" == "0" ]; then
		git_delete_prep_branch $prepBranch
	fi

	echo "+>> Creating branch \"$prepBranch\"" 2>&1 | tee -a "$genLog"
	echo "git checkout -b $prepBranch" 2>&1 | tee -a "$genLog"
	git checkout -b $prepBranch 2>&1 >> "$genLog"
	if [ "$?" -ne "0" ]; then
		echo "*** ERROR Could not create branch \"$prepBranch\"" 2>&1 | tee -a "$genLog"
		exit_now "20"
	fi
	echo "[OK]" 2>&1 | tee -a "$genLog"
	### Returning with git currrent branch on the branch provided in arg 1
}

## function to merge code related to requried components          ##
## required parameter: $1 = name of component to be added/merged  ##
## scope: private (internal calls only)                           ##
function git_merge_component_branch() {
	if [ "$1" == "" ]; then
		echo "+>> No component, nothing to merge" 2>&1 | tee -a "$genLog"
	else
		tmpBranchName="master-$1"

		echo "+>> Attempting to check out component branch with \"$tmpBranchName\"" 2>&1 | tee -a "$genLog"

		# make sure we are on the branch
		echo "git checkout $tmpBranchName" 2>&1 | tee -a "$genLog"
		git checkout $tmpBranchName 2>&1 >> "$genLog"
		if [ "$?" -ne "0" ]; then
			echo "*** ERROR: could not check out branch \"$tmpBranchName\"" 2>&1 | tee -a "$genLog"
			check_exit_status "21"
		fi

		# pull in case branch was already on local and not up to date
		echo "git pull" 2>&1 | tee -a "$genLog"
		git pull 2>&1 >> "$genLog"
		check_exit_status "$?"

		echo "+>> Attempting to merge component \"$tmpBranchName\" into \"$prepBranch\"" 2>&1 | tee -a "$genLog"

		# switch back to the prep branch
		echo "git checkout $prepBranch" 2>&1 | tee -a "$genLog"
		git checkout $prepBranch 2>&1 >> "$genLog"
		if [ "$?" -ne "0" ]; then
			echo "*** ERROR: could not check out branch \"$prepBranch\"" 2>&1 | tee -a "$genLog"
			check_exit_status "21"
		fi

		# finally do the merge
		echo "git merge $tmpBranchName" 2>&1 | tee -a "$genLog"
		git merge $tmpBranchName 2>&1 >> "$genLog"
		if [ "$?" -eq "0" ]; then
			echo "+>> No file conflicts found." 2>&1 | tee -a "$genLog"
		else
			echo "*** ERROR Merge from $tmpBranchName branch not successful, contact framework team." 2>&1 | tee -a "$genLog"
			echo "+>> Resetting changes - checking out master and deleting $prepBranch" 2>&1 | tee -a "$genLog"
			
			echo "git reset --hard" 2>&1 | tee -a "$genLog"
			git reset --hard 2>&1 >> "$genLog"
			check_exit_status "$?"
			
			git_checkout_branch $gitBranchBaseline

			exit_now 1
		fi
	fi
}


################################################################################
############################                        ############################
############################   BUSINESS FUNCTIONS   ############################
############################                        ############################
################################################################################

function remove_only() {
	if [ "$removeOnly" -eq "0" ]; then
		cd_to "$cwd"
		echo "" 2>&1 | tee -a "$genLog"

		if [ -d "$artifactId" ]; then
			echo "+>> Removing '$artifactId'" 2>&1 | tee -a "$genLog"
			echo "rm -rf $artifactId" 2>&1 | tee -a "$genLog"
			rm -rf "$artifactId" 2>&1 >> "$genLog"
			check_exit_status "$?"
		else
			exit_now 8
		fi
		# do not continue any further processing of any kind
		echo "" 2>&1 | tee -a "$genLog"
		exit 0
	fi
}

## function to (re)build the Origin project ##
## arg: none                                ##
## scope: private (internal calls only)     ##
function build_origin() {
	cd_to "$cwd/$originDirName"

	if [ "$skipBuild" -eq "0" ]; then
		echo "+>> Not building $originDirName" 2>&1 | tee -a "$genLog"
	else
		echo "+>> Building the $originDirName project" 2>&1 | tee -a "$genLog"
		echo "mvn clean install $doDockerBuild" 2>&1 | tee -a "$genLog"
		mvn clean install $doDockerBuild  2>&1 >> "$genLog"
		check_exit_status "$?"
	fi
}

## function to copy the origin project to a new project directory ##
## arg: none                                                      ##
## scope: private (internal calls only)                           ##
function copy_origin_project() {
	cd_to "$cwd"

	if [ -d "./$artifactId" ]; then
		if [ "$overwriteExisting" -eq "0" ]; then
			echo "+>> Over-writing existing $artifactId project" 2>&1 | tee -a "$genLog"
			echo "rm -rf $artifactId/" 2>&1 | tee -a "$genLog"
			# tee does not play well with some bash commands, so just redirect output to the log
			rm -rf "$artifactId/" 2>&1 >> "$genLog"
			check_exit_status "$?"
		else
			exit_now 7
		fi
	fi

	echo "+>> Copy $originDirName to $artifactId" 2>&1 | tee -a "$genLog"
	echo "cp -R -f ./$originDirName/ ./$artifactId/" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cp -R -f "./$originDirName/" "./$artifactId/" 2>&1 >> "$genLog"
	check_exit_status "$?"
}

## function to prepare the desired Origin project based on which the archetype project needs to be generated ##
## arg: none                                ##
## scope: private (internal calls only)     ##
function prepare_origin_project() {
	# check out the baseline branch
	git_checkout_branch "$gitBranchBaseline"
	# create the prep branch, put branch name in $prepBranch
	git_create_prep_branch "originPrep-$artifactName"
	# git current branch is now the prep branch

	if [ ${#components[@]} -eq 0 ]; then
		echo "+>> No components selected, proceeding with baseline Origin project" 2>&1 | tee -a "$genLog"
	else
		echo "+>> Merging components \"${components[*]}\" into branch \"$prepBranch\"." 2>&1 | tee -a "$genLog"
		for component in "${components[@]}"
		do
			git_merge_component_branch "$component"
		done
	fi
	copy_origin_project
	build_origin
}

## function to clean up and prepare files for new project ##
## arg: none                                              ##
## scope: private (internal calls only)                   ##
function prepare_files() {
	cd_to "$cwd/$artifactId"

	# copy the reactor (root) README for new projects
	echo "+>> Copy README.md" 2>&1 | tee -a "$genLog"
	echo "cp -fv ./archive/bip-archetype-service-newprojects-README.md ./README.md" 2>&1 | tee -a "$genLog"
	# tee does not play well with some bash commands, so just redirect output to the log
	cp -fv "./archive/bip-archetype-service-newprojects-README.md" "./README.md" 2>&1 >> "$genLog"
	check_exit_status "$?"

	# delete the archive directory
	echo "+>> Delete archive directory" 2>&1 | tee -a "$genLog"
	echo "rm -rf ./archive" 2>&1 | tee -a "$genLog"
	rm -rf "./archive" 2>&1 >> "$genLog"
	check_exit_status "$?"

	# maven clean has proven unreliable in some scenarios,
	# so making sure all target directories are deleted
	echo "+>> Delete all target directories" 2>&1 | tee -a "$genLog"
	oldWord="target"
	find . -name "$oldWord" -depth -type d -maxdepth 4 -print | while read tmpDir; do
		echo "rm -rf $tmpDir" 2>&1 | tee -a "$genLog"
		rm -rf "$tmpDir" 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"
}

## function to rename project directories ##
## arg: none                              ##
## scope: private (internal calls only)   ##
function rename_directories() {
	cd_to "$cwd/$artifactId"

	# rename bip-origin dirs
	echo "+>> Renaming directories in place: bip-origin to $artifactId" 2>&1 | tee -a "$genLog"
	oldWord="bip-origin"
	find . -name "*$oldWord*" -depth -type d -maxdepth 4 -print | while read tmpDir; do
		newDir=${tmpDir//$oldWord/$artifactId}
		echo "mv -f -v $tmpDir $newDir" 2>&1 | tee -a "$genLog"
		mv -f $tmpDir $newDir 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"

	# rename origin dirs
	originGroupidAsPath=${originGroupId//\./\/}
	artifactGroupidAsPath=${groupId//\./\/}
	echo "+>> Renaming directories in place: $originGroupidAsPath to $artifactGroupidAsPath" 2>&1 | tee -a "$genLog"
	oldWord="$originGroupidAsPath"
	find . -path "*$originGroupidAsPath" -depth -type d -maxdepth 20 -print | while read tmpDir; do
		newDir=${tmpDir//$oldWord/$artifactGroupidAsPath}
		echo "mkdir -p $newDir"
		mkdir -p "$newDir"
		check_exit_status "$?"
		echo "mv -f $tmpDir/* $newDir" 2>&1 | tee -a "$genLog"
		mv -f $tmpDir/* $newDir/  2>&1 >> "$genLog"
		echo "rm -rf $tmpDir"
		rm -rf "$tmpDir"
		check_exit_status "$?"
	done; check_exit_status "$?"
	echo "+)) done"
}

## function to rename project files     ##
## arg: none                            ##
## scope: private (internal calls only) ##
function rename_files() {
	cd_to "$cwd/$artifactId"

	# rename bip-origin files
	echo "+>> Renaming files in place: bip-origin to $artifactId" 2>&1 | tee -a "$genLog"
	oldWord="bip-origin"
	find . -name "*$oldWord*" -depth -type f -maxdepth 20 -print | while read tmpFile; do
		newFile=${tmpFile//$oldWord/$artifactId}
		mv -f -v $tmpFile $newFile 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"

	# rename Origin files
	echo "+>> Renaming files in place: Origin to $artifactName" 2>&1 | tee -a "$genLog"
	oldWord="Origin"
	find . -name "*$oldWord*" -depth -type f -maxdepth 20 -print | while read tmpFile; do
		newFile=${tmpFile//$oldWord/$artifactName}
		mv -f -v $tmpFile $newFile 2>&1 >> "$genLog"
		check_exit_status "$?"
	done; check_exit_status "$?"
}

## function to change text inside files  ##
## arg: none                             ##
## scope: private (internal calls only)  ##
function change_text() {
	cd_to "$cwd/$artifactId"

	#########################################################
	## NOTE sed *always* returns "0" as its exit code      ##
	##      regardless if it succeeds or not. If changes   ##
	##      are made to sed commands, you must check the   ##
	##      gen.log (search "sed -i") to verify   ##
	##      that no sed error messages follow the command  ##
	## Error lines will begin with "sed: "                 ##
	#########################################################

	find "$PWD" -type f -maxdepth 20 \
		! -iwholename '*.DS_Store' \
		! -iname 'swa\-prep.sh' \
		! -iname '*.jks' \
		! -iname '*.classpath' \
		! -ipath '*.settings*' \
		! -iname '*.pdf' \
		| while read tmpFile; do
		## ^^^^
		## Do not include .project in the above exclusions

		# replace archetype package/groupId for slash
		oldVal="gov\/va\/bip\/origin"
		newVal="${groupId//./\\/}"
		echo "LC_ALL=C sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		LC_ALL=C sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# replace archetype package/groupId
		oldVal="gov.va.bip.origin"
		newVal="$groupId"
		echo "LC_ALL=C sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		LC_ALL=C sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# artifactId replacement
		oldVal="bip-origin"
		newVal="$artifactId"
		echo "LC_ALL=C sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		LC_ALL=C sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# camelcase replacement
		oldVal="Origin"
		newVal="$artifactName"
		echo "LC_ALL=C sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		LC_ALL=C sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# lowercase replacement
		oldVal="origin"
		newVal="$artifactNameLowerCase"
		echo "LC_ALL=C sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		LC_ALL=C sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# uppercase replacement
		oldVal="ORIGIN"
		newVal="$artifactNameUpperCase"
		echo "LC_ALL=C sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		LC_ALL=C sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
		# projectNameSpacePrefix replacement
		oldVal="bip-project-namespace-prefix"
		newVal="$projectNameSpacePrefix"
		echo "LC_ALL=C sed -i \"\" -e 's/'\"$oldVal\"'/'\"$newVal\"'/g' \"$tmpFile\"" 2>&1 | tee -a "$genLog"
		LC_ALL=C sed -i "" -e 's/'"$oldVal"'/'"$newVal"'/g' "$tmpFile" 2>&1 >> "$genLog"
	done;
	### do not check exit status, as windows editions of bash mysteriously report errors, but still do the work
	# check_exit_status "$?"
}

## function to build the new project    ##
## arg: none                            ##
## scope: private (internal calls only) ##
function build_new_project() {
	cd_to "$cwd/$artifactId"

	echo "+>> Building the $artifactId project" 2>&1 | tee -a "$genLog"
	echo "mvn clean package $doDockerBuild" 2>&1 | tee -a "$genLog"
	mvn clean package $doDockerBuild  2>&1 >> "$genLog"
	check_exit_status "$?"
}

################################################################################
#######################                                  #######################
#######################   SCRIPT EXECUTION BEGINS HERE   #######################
#######################                                  #######################
################################################################################

## output header info, get the log started ##
echo ""  2>&1 | tee "$genLog"
echo "=========================================================================" 2>&1 | tee -a "$genLog"
echo "Generate a BIP Service project" 2>&1 | tee -a "$genLog"
echo "=========================================================================" 2>&1 | tee -a "$genLog"
echo "" 2>&1 | tee -a "$genLog"

## call each function in order ##
get_args $args
read_properties
validate_properties
remove_only
framework_exists
git_has_remote
# multiple steps carried out in prepare_origin_project...
prepare_origin_project

prepare_files
rename_directories
rename_files
change_text
build_new_project
git_delete_prep_branch
exit_now 0
