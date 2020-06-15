#!/usr/bin/env zsh

script_name=$0
name_prefix="academy-user"
let M=1
let N=1
tagline="Do post processing on sessions, e.g., fix Juypter Lab"

dir=$(dirname $0)
. $dir/utils.sh

# Overrides the default help in utils.sh
help() {
	cat <<EOF
$script_name: $tagline

Usage: $script_name [-h|--help] [-n|--name name] [-p|--project name] [N | M N | M-N | M:N]
Where:
	-h | --help           Print this message and exit.
	-n | --name name      The name prefix for the sessions. Default is "$name_prefix". The number will be appended to it.
	-p | --project name   The name of your Anyscale project; will correspond to /usr/ubuntu/<project_name> directory.
						  Defaults to the value for "cluster_name" in ray-project/cluster.yaml.
	N | M N | M-N | M:N   Four ways to specify how many sessions to create or a range of numbers from N-M, inclusive.
	                      With one value N, M defaults to 1. Default is $M-$N.
WARNING: It currently isn't possible to run this in parallel reliably, so this script
runs ONE AT A TIME, which is very slow.
EOF
}

range=()
project_name=
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
		-p|--project)
			shift
			project_name=$1
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

[[ -z $project_name ]] && project_name=$(get_project_name)
[[ -z $project_name ]] && error "Failed to get the project name from $DEFAULT_CLUSTER_YAML. Fix that file or specify the project name here."

[[ ${#range[@]} -eq 0 ]] && range=($M $N)
compute_range ${range[@]} | while read M N M0 N0
do
	echo "Fixing sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N in project $project_name:"

	mkdir -p log
	for n in {$M..$N}
	do
		n0=$(zero_pad $n)
		npn=${name_prefix}-${n0}
		echo "Fixing session $n0, named $npn. Writing output to file log/fix-$npn.log"
		if [[ -z $NOOP ]]
		then
			anyscale ray exec-cmd "$npn" \
				"/home/ubuntu/$project_name/tools/fix-jupyter.sh -j /home/ubuntu/anaconda3/bin/jupyter" \
				> log/fix-$npn.log 2>&1
		else
			$NOOP anyscale ray exec-cmd "$npn" \
				"/home/ubuntu/$project_name/tools/fix-jupyter.sh -j /home/ubuntu/anaconda3/bin/jupyter"
		fi
	done
done
