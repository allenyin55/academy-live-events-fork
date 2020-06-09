#!/usr/bin/env zsh

script_name=$0
name_prefix="academy-user"
M=1
N=1
tagline="Create N sessions"

dir=$(dirname $0)
. $dir/utils.sh

range=()
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
compute_range ${range[@]} | while read M N M0 N0
do
	echo "Creating sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N"

	for n in {$M..$N}
	do
		n0=$(zero_pad $n)
		echo "Creating session $n0, named ${name_prefix}-${n0}..."
		$NOOP anyscale start --session-name ${name_prefix}-${n0} &
	done
done