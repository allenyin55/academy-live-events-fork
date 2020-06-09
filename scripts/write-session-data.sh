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

echo "Read session data from stdin (exit with ^D or end of file):" >&2
sed -e 's/,/ /g' | while read session id ip token durl jurl
do
	[[ $session = "SESSION" ]] && continue
	cat << EOF

Greetings!

Thank you for registering for the live Anyscale Academy "Reinforcement Learning with Ray RLlib", June 24, 2020, 10AM Pacific.

If you decide you can't make it, please update your registration using the URL Eventbrite emailed you. Or, try this URL:

https://www.eventbrite.com/e/anyscale-academy-reinforcement-learning-with-ray-rllib-tickets-105573573400

Before the class starts, click the following URLs. One opens a Jupyter Lab environment for the tutorials and the other opens the Ray Dashboard:

Your "session" name: $session
Jupyter Lab:         $jurl
Ray Dashboard:       $durl

Click this zoom link to join the live tutorial:

https://zoom.us/j/98719676934

You can also find all the tutorial notebooks and code here:

https://github.com/anyscale/academy

Either clone the repo or download the latest release (in the Releases tab).

NOTES:

1. To save any edits you make to a notebook, download it using the File > Download menu item in Jupyter.
2. If you run into problems, paste the session name above into the Zoom Q&A window and describe the issue.
3. Need help before or after the event? Send email to academy@anyscale.com or ask for help in the #tutorials channel in the Ray slack.

Don't forget to visit our Events page, https://anyscale.com/events for future tutorial and "Ray Summit Connect" events this Summer and Fall. Videos of past events can be found there, too.


See you soon!

The Anyscale Academy Team

EOF
done
