#!/usr/bin/env zsh

script_name=$0
tagline="Write the session names, session ids, head-node IP addresses, juypter tokens, and URLs."
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

[[ -z $NOOP ]] || error "Can't process the NOOP = $NOOP flag any further"

sessions=()
start=
anyscale list sessions 2> /dev/null | while read line
do
	[[ $line =~ SESSION ]] && start=true && continue
	[[ $start ]] || continue
	session=$(echo $line | sed -e 's/^\([^ ]*\).*/\1/')
	sessions+=("$session")
done

# The "assigned email" field is blank. It's here for convenience when importing the
# CSV file into a spreadsheet to allow users to self-assign themselves a session,
# e.g., for Anyscale in-house testing.
echo "SESSION,ID,DASHBOARD_IP,JUPYTER_TOKEN,JUPYTER_URL,DASHBOARD_URL,TENSORBOARD_URL,ASSIGNED_EMAIL"

declare -A sessions_ips
declare -A sessions_ids
declare -A sessions_tokens
for session in ${sessions[@]}
do
	echo "Session: $session" >&2
	sessions_ips[$session]=$(anyscale ray get-head-ip $session 2> /dev/null)
	anyscale ray exec-cmd $session '~/anaconda3/bin/jupyter notebook list' | \
		grep '^http' | sed -e 's?.*sessions/\([0-9]*\)/.*token=\([^ ]*\).*?\1 \2?' | \
		while read session_id token
		do
			sessions_ids[$session]=$session_id
			sessions_tokens[$session]=$token
		done

	id=$sessions_ids[$session]
	ip=$sessions_ips[$session]
	token=$sessions_tokens[$session]
	durl="http://$ip:8081/auth/?token=$token&redirect_to=dashboard"
	jurl="https://anyscale.dev/sessions/$id/jupyter/lab?token=$token"
	turl="https://anyscale.dev/sessions/$id/auth/?token=$token&session_id=$id&redirect_to=tensorboard"

	echo "$session,$id,$ip,$token,$jurl,$durl,$turl,"
done


