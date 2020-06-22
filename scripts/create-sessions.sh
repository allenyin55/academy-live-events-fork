#!/usr/bin/env zsh

# Import this BEFORE defining values like "cmd_opts"
dir=$(dirname $0)
. $dir/utils.sh

script_name=$0
tagline="Create N sessions"
cmd_opts=(session_name range)
post_help_messages=

# TODO: Rather than fire all of them at once, do 20 or so at a time.

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

mkdir -p log

[[ ${#range[@]} -eq 0 ]] && range=($M $N)
compute_range ${range[@]} | while read M N M0 N0
do
	echo "Creating sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N."
 	echo "Writing output to file log/create-$M0-$N0.log"

	for n in {$M..$N}
	do
		n0=$(zero_pad $n)
		npn=${name_prefix}-${n0}
		echo "Creating session $n0, named $npn ..."
		$NOOP anyscale start --session-name $npn
	done > log/create-$M0-$N0.log" 2>&1
done