#!/usr/bin/env zsh

# Import this BEFORE defining values like "cmd_opts"
dir=$(dirname $0)
. $dir/utils.sh

script_name=$0
tagline="Check that Juypter Lab is properly configured in sessions"
cmd_opts=(session_name range)
post_help_messages=slow_warning

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

[[ ${#range[@]} -eq 0 ]] && range=($M $N)
compute_range ${range[@]} | while read M N M0 N0 MN0
do
	logfile=log/check-$MN0.log
	echo "Checking Jupyter Lab in sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N:"
 	echo "Writing output to file $logfile"

	mkdir -p log
	for n in {$M..$N}
	do
		n0=$(zero_pad $n)
		npn=${name_prefix}-${n0}
		echo "Checking session $n0, named $npn ..."
		$NOOP anyscale ray exec-cmd "$npn" "/home/ubuntu/anaconda3/bin/jupyter labextension list"
	done > $logfile 2>&1
done
