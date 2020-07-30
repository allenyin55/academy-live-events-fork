#!/usr/bin/env zsh

# Import this BEFORE defining values like "cmd_opts"
dir=$(dirname $0)
. $dir/utils.sh

# The next few lines setup the help.
script_name=$0
tagline="Push code updates to running sessions, e.g., notebook bug fixes"
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

[[ ${#range[@]} -eq 0 ]] && range=($M $N)
compute_range ${range[@]} | read M N M0 N0 MN0
info "Pushing code updates to sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N"

for n in {$M..$N}
do
	n0=$(zero_pad $n)
	npn=${name_prefix}-${n0}
	info "Pushing the latest code to session $n0, named ${npn}..."
	$NOOP anyscale push ${npn}
done
info "Finished!"
