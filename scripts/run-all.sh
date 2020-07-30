#!/usr/bin/env zsh

dir=$(dirname $0)
. $dir/utils.sh

# The lines up to $@ parsing block setup the help.
script_name=$0
tagline="A script to drive the Academy setup process, e.g., for testing"
version_opt='version'
version_help() {
    cat <<EOF
    version               The version tag of the academy and academy-live-events to use (required).
EOF
}
cmd_opts=(version help no_exec session_name project_name range)
read -r -d '' post_help_messages <<- EOM
	This file is meant to be copied separately to another work directory and run there.
	It clones the academy and academy-live-events repos into that directory.

	$(slow_warning)
EOM

set -e
version=
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
		--no*)
			no_exec
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
			error "Unexpected argument $1."
			;;
		*)
			# first non-flag is the version
			[[ -z $version ]] && version=$1 || range+=($1)
			;;
	esac
	shift
done

[[ -z $version ]] && error "The version argument is required."
$NOOP which -s anyscale || error "Please 'pip install anyscale'"

info "Download an academy release using version tag: $version"
version2=$(echo $version | sed -e 's/^v//')
av=academy-$version2
zip=$av.zip
$NOOP curl -o $zip https://codeload.github.com/anyscale/academy/zip/$version
$NOOP unzip $zip

info "Copy academy-live-event's version of ray-project over the academy's copy."
$NOOP cp -rf ./ray-project $av/ray-project

info "Switch to the academy directory."
$NOOP cd $av
scripts_dir=../scripts  # will be the new scripts dir...
if [[ -z $NOOP ]]
then
	info "Working directory: $PWD"
else
	scripts_dir=scripts   # ... unless we are running NOOP=..., since the previous cd not executed.
fi

if [[ -n $project_name ]]
then
	info "Changing the project name in the ray-project/*.yaml files to $project_name"
	edit_project_name $project_name
else
	project_name=$(get_project_name)
fi

info "Create the project named $project_name"
$NOOP anyscale init --name $project_name --requirements ray-project/requirements.txt

info -n "PROMPT ==> Enter the snapshot id just created (or leave blank to create a new one) ==> "
read id
snapshot_args=()
[[ -n $id ]] && snapshot_args=("--snapshot" $id)

info "Creating sessions."
$scripts_dir/create-sessions.sh ${snapshot_args[@]} --name $name_prefix ${range[@]}

info "Open the link for your anyscale.dev project page that was output above."
info -n "PROMPT ==> Watch the sessions start. When they are ready, hit enter to continue ==> "
read toss

compute_range ${range[@]} | read M N M0 N0 MN0
[[ $M != $N ]] && fandl=" first and last"
info "Sanity check of$fandl session."
info "Check session - ${name_prefix}-$M0."
$scripts_dir/check-sessions.sh --name $name_prefix $M $M
if [[ $M != $N ]]
then
	info "Check session - ${name_prefix}-$N0."
	$scripts_dir/check-sessions.sh --name $name_prefix $N $N
fi

info "Get the sessions. The data is written to sessions.csv."
if [[ -z $NOOP ]]  # For NOOP, don't send the output to sessions.csv
then
	$scripts_dir/get-sessions.sh --name $name_prefix ${range[@]} > sessions.csv
else
	$scripts_dir/get-sessions.sh --name $name_prefix ${range[@]}
fi
info "wc sessions.csv"
$NOOP wc sessions.csv
