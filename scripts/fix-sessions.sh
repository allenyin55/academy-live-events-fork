#!/usr/bin/env zsh

# Import this BEFORE defining values like "cmd_opts"
dir=$(dirname $0)
. $dir/utils.sh

# The next few lines setup the help.
script_name=$0
tagline="Do post processing on sessions, e.g., fix Juypter Lab"
cmd_opts=(session_name project_name range)
post_help_messages=$(slow_warning)

range=()
name_prefix=$DEFAULT_NAME_PREFIX
project_name=
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
compute_range ${range[@]} | read M N M0 N0 MN0
info "Fixing sessions numbered N = $M0 to $N0 with name format ${name_prefix}-N in project $project_name:"
for n in {$M..$N}
do
	n0=$(zero_pad $n)
	npn=${name_prefix}-${n0}
	info "Fixing session $n0, named $npn ..."
	$NOOP anyscale exec -n "$npn" \
		"/home/ubuntu/$project_name/tools/fix-jupyter.sh -j /home/ubuntu/anaconda3/bin/jupyter"
done 2>&1
info "Finished!"

