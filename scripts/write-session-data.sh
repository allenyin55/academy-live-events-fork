#!/usr/bin/env zsh

# WARNING: THE TEXT BELOW HAS TO BE UPDATED FOR EACH EVENT!!

script_name=$0
tagline="Read the output of get-sessions.sh and write text for email distribution about the sessions"

dir=$(dirname $0)
. $dir/utils.sh

# Override help in utils.sh
help() {
	empty_help
}

while [[ $# -gt 0 ]]
do
	case $1 in
		-h|--help)
			help
			exit 0
			;;
		*)
			error "Unexpected argument $1"
			;;
	esac
	shift
done

cat <<EOF 1>&2
$0: The output will start with a line for an email address (if known) and a line for the email subject line,
$0: followed by the body of the email, which ends with a line containing "=====...=====".
$0:
$0: Reading session data from stdin (exit with ^D or end of file):
EOF

sed -e 's/,/ /g' | while read session id ip token jurl durl tburl email
do
	[[ $session = "SESSION" ]] && continue
	cat << EOF

$email

About the RLlib Tutorial, June 24


Greetings!

Thank you for registering for the live Anyscale Academy "Reinforcement Learning with Ray RLlib", June 24, 2020, 10AM Pacific.

If you decide you can't make it, please update your registration using the URL Eventbrite emailed you. Or, try this URL:

https://www.eventbrite.com/e/anyscale-academy-reinforcement-learning-with-ray-rllib-tickets-105573573400


Here is the name of your online "session" and the URLs you will use during class

Your "session" name: $session
Jupyter Lab:         $jurl
Ray Dashboard:       $durl
TensorBoard:         $tburl

You will mostly use the Jupyter Lab environment for the tutorials. The Ray Dashboard is used to observe performance characteristics. TensorBoard is used in several tutorials to examine the results of model training, etc. TensorBoard is used to examine ML model parameters and training information.

Click this zoom link to join the live tutorial:

https://zoom.us/j/92969464830


You can also find all the tutorial notebooks, other source code, and instructions here:

https://github.com/anyscale/academy

Either clone the repo or download the latest release.

NOTES:

1. To save any edits you make to a notebook, download it using the File > Download menu item in Jupyter.
2. If you run into problems during the event, paste the session name above into the Zoom Q&A window and describe the issue.
3. If you need help before or after the event. send email to academy@anyscale.com or ask for help in the #tutorials channel in the Ray slack.

Don't forget to visit our Events page, https://anyscale.com/events for future tutorial and other online events this Summer and Fall. Videos of past events can be found there, too.


See you soon!

The Anyscale Academy Team

===============================================================================

EOF
done
