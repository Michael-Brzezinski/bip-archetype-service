# SwA Preparation Script
VA OIS Software Assurance (SwA) performs reviews for design and code reviews, and quality reviews. For code reviews, SwA is interested in reviewing **release** versions of the software. For background and technical details, see [Software Assurance and Fortify](../../docs/fortify-and-swa.md).

This README and related `swa-prep.sh` script are specific to the SwA process described under the _Secure Code Review > How do I register applications, request secure code review tools and validations?_ section on the [SwA FAQ page](https://wiki.mobilehealth.va.gov/display/OISSWA/Frequently+Asked+Questions).

Some SwA website pages with instructions for the SwA submission requirements and process:
* [Document Library (PDFs, etc)](https://wiki.mobilehealth.va.gov/display/OISSWA/Public+Document+Library)
* [Application Registration](https://wiki.mobilehealth.va.gov/display/OISSWA/How+to+open+an+NSD+ticket+to+register+a+VA+application)
* [Code Review Submission](https://wiki.mobilehealth.va.gov/pages/viewpage.action?pageId=26774489)
* [FAQ](https://wiki.mobilehealth.va.gov/display/OISSWA/Frequently+Asked+Questions)

## What does the script do?

The script is intended for use with applications based on the BIP Framework (and for the framework itself).

The script can be run in _GitBash_ or any other bash terminal. As it runs, the script prompts the user to perform any manual steps, and automates those steps that can be automated.

The script offers:
1. Repeatability and consistency for each released artifact
2. Local traceability for the preparation of packages that will be sent to SwA

This script does _not_ alter the state of your local git repo or code workspace, but _does_ add a PDF and properties file under the `./local-dev/swa/tags/` directory for the tag that was processed. It is recommended to commit and push the files.

#### swa-prep.sh & swa-prep.properties

This script creates a folder with:

	* A copy of the `VA Secure Code Review Validation Request Form.pdf` to be filled out
	* A zip of the code taken from a git tag (a release version)
	* A fresh Fortify FPR derived from the tag
	* A zip of the local Fortify rulepack that was used to scan the code

#### Script execution overview

In general, the steps the script takes:
* Clone the project repo and check out the TAG of the release version.
* Build and scan the project
* Assemble the Code Review Request PDF, a zip of the code that was scanned, the FPR, and a ZIP of the Fortify rules used to perform the scan.

## When and how do I run the script?

The script has been tested on macOS. For Windows users, please use [Git Bash](https://gitforwindows.org/) to execute the script. If you encounter any problems, please open a "SwA Script" issue on EPMO GitHub [bip-archetype-service](https://github.ec.va.gov/EPMO/bip-archetype-service) project.

#### Prerequisites

SwA submissions are done only on release candidates. A release version will have a git TAG version that does not have "-SNAPSHOT" on the end of it.

* The user workstation should be set up for BIP projects as documented in EPMO GitHub at the BIP [Quick Start Guide](https://github.ec.va.gov/EPMO/bip-reference-person/blob/master/docs/quick-start-guide.md). This includes:
 	* Local installation of [Fortify apps and Fortify maven plugins](https://wiki.mobilehealth.va.gov/display/OISSWA/How+to+download+the+VA-Licensed+Fortify+software).
	* The project must produce the `[project-name]-reactor.fpr` when built with the `-P fortify-sca` profile
* Know the name of the release tag that is to be submitted. To see available tags, run `git pull` then `git tag` in the project directory.

To make the preparation process go faster and easier, it is worth taking the time to update default files for your project.
* Open `[project-reactor]/local-dev/swa/defaults/VA Secure Code Review Validation Request Form.pdf` in a PDF editor (Acrobat, Preview, etc). Fill out the form and save it in place.
* Open `[project-reactor]/local-dev/swa/defaults/swa-prep.properties` in an editor. Update property values to sensible defaults if desired, and save in place.

#### Running the script

Steps:
1. [Register with SwA](https://wiki.mobilehealth.va.gov/display/OISSWA/How+to+open+an+NSD+ticket+to+register+a+VA+application) if you have not already registered the application.
2. Create a release on the Jenkins server - assumption is that the project is release-ready, e.g. meets sonar requirements, Fortify FPR is clean (code fixed, suppressions done).
3. Open a bash terminal
	* Change to the local-dev/swa directory in your project
		```bash
		$ cd ~/git/bip-my-project/local-dev/swa
		```
	* Run the script and follow prompts (you may need to set the script to be executable: `chmod +x swa-prep.sh`)
		```bash
		$ ./swa-prep.sh
		```
	* Follow the prompts, and supply information or perform actions as directed.
	* Read the message that is output when the script finishes.
	* Consider committing and pushing the new files created by the script (in your project local-dev/swa/tags directory).
4. Use the created submission files to [submit the code review request](https://wiki.mobilehealth.va.gov/pages/viewpage.action?pageId=26774489) to SwA

## Maintenance

The "VA Secure Code Review Validation Request Form.pdf" may change from time to time. You can check for recent versions at the Swa [Public Document Library](https://wiki.mobilehealth.va.gov/display/OISSWA/Public+Document+Library). Download it, and copy it into `[project-reactor]/local-dev/swa/defaults/`.  If the file name changes, you can either rename the new file to `VA Secure Code Review Validation Request Form.pdf`, or change the value of the `pdfFileName` variable near the top of `swa-prep.sh`.
