#!/usr/bin/env zsh

# Import this BEFORE defining values like "cmd_opts"
dir=$(dirname $0)
. $dir/utils.sh

# The next few lines setup the help.
script_name=$0
tagline="Write the session names, session ids, head-node IP addresses, juypter tokens, and URLs for the specified range of sessions, but only if they are ACTIVE."
cmd_opts=(help no_exec session_name range)
post_help_messages=$(slow_warning)

range=()
name_prefix=$DEFAULT_NAME_PREFIX
let M=$DEFAULT_M
let N=$DEFAULT_N
while [[ $# -gt 0 ]]
do
	case $1 in
		-h|--help)
			help
			exit 0
			;;
		--no*)
			no_exec
			;;
		-n|--name)
			shift
			name_prefix=$1
			;;
		-*)
			error "Unexpected argument $1"
			;;
		*)
			range+=($1)
			;;
	esac
	shift
done

declare -A sessions
$NOOP anyscale list sessions 2> /dev/null | grep ACTIVE | cut -f1 -d' ' | while read session
do
	sessions[$session]=true
done

# The "assigned email" field is blank. It's here for convenience when importing the
# CSV file into a spreadsheet to allow users to self-assign themselves a session,
# e.g., for Anyscale in-house testing.
echo "SESSION,ID,DASHBOARD_IP,JUPYTER_TOKEN,JUPYTER_URL,DASHBOARD_URL,TENSORBOARD_URL,ASSIGNED_EMAIL"

[[ ${#range[@]} -eq 0 ]] && range=($M $N)
compute_range ${range[@]} | read M N M0 N0 MN0
info "Getting session data for sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N:" 1>&2

for n in {$M..$N}
do
	n0=$(zero_pad $n)
	npn=${name_prefix}-${n0}
	if [[ -z $sessions[$npn] ]]
	then
		warning "Session $npn wasn't found in 'anyscale list sessions'. Skipping..." 1>&2
	else
		if [[ -z $NOOP ]]
		then
			ip=$(anyscale ray get-head-ip $npn 2> /dev/null)
			anyscale exec -n "$npn" '~/anaconda3/bin/jupyter notebook list' | \
				grep '^http' | sed -e 's?.*sessions/\([0-9]*\)/.*token=\([^ ]*\).*?\1 \2?' | \
				while read id token
				do
					durl="http://$ip:8081/auth/?token=$token&redirect_to=dashboard"
					jurl="https://anyscale.dev/sessions/$id/jupyter/lab?token=$token"
					turl="https://anyscale.dev/sessions/$id/auth/?token=$token&session_id=$id&redirect_to=tensorboard"

					echo "$npn,$id,$ip,$token,$jurl,$durl,$turl,"
				done
		else
			$NOOP anyscale ray get-head-ip $npn
			$NOOP anyscale exec -n "$npn" '~/anaconda3/bin/jupyter notebook list'
		fi
	fi
done
info "Finished!"


