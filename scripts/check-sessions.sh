#!/usr/bin/env zsh

script_name=$0
name_prefix="academy-user"
let M=1
let N=1
tagline="Check that Juypter Lab is properly configured in sessions"

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
	echo "Checking Jupyter Lab in sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N:"

	mkdir -p log
	for n in {$M..$N}
	do
		n0=$(zero_pad $n)
		npn=${name_prefix}-${n0}
		echo "Checking session $n0, named $npn. Writing output to file log/check-$npn.log"
		if [[ -z $NOOP ]]
		then
			anyscale ray exec-cmd "$npn" \
				"/home/ubuntu/anaconda3/bin/jupyter labextension list" \
				> log/check-$npn.log 2>&1 &
		else
			$NOOP anyscale ray exec-cmd "$npn" \
				"/home/ubuntu/anaconda3/bin/jupyter labextension list"
		fi
	done
done
