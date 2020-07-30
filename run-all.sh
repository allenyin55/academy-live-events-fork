#!/usr/bin/env zsh

# Edit the following definitions as required:

LATEST_ACADEMY=v151

dir=$(dirname $0)
. $dir/scripts/utils.sh

script_name=$0
tagline="A script to drive the Academy setup process, e.g., for testing"
cmd_opts=(session_name project_name range)
post_help_messages=slow_warning

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

echo "Download the academy and academy-live-events (latest releases):"
for ext in "" "-live-events"
do
	zip=academy$ext-$LATEST_ACADEMY.zip
	$NOOP curl -o $zip https://codeload.github.com/anyscale/academy$ext/zip/$LATEST_ACADEMY
	$NOOP unzip $zip
done

echo "Copy the live event's version of ray-project over the academy's:"
$NOOP cp -rf academy-live-events/ray-project academy/ray-project

echo "Copy the live event's scripts directory to the academy:"
$NOOP cp -rf academy-live-events/scripts academy/

echo "Switch to the academy directory:"
$NOOP cd academy

if [[ -n $project_name ]]
then
	edit_project_name $project_name
else
	project_name=$(get_project_name)
fi


$NOOP which -s anyscale || error "Please 'pip install anyscale'."

echo "Create the project $project_name:"
$NOOP anyscale init --requirements ray-project/requirements.txt

echo -n "Enter the snapshot id just created (or leave blank): "
read id
snapshot_args=()
[[ -n $id ]] && snapshot_args=("--snapshot" $id)

echo "Creating sessions:"
$NOOP scripts/create-sessions.sh ${snapshot_args[@]} --name $name_prefix ${range[@]}

echo "Click the link for your anyscale.dev project page output above."
echo -n "Watch the sessions start. When they are ready, hit enter to continue: "
read toss

echo "Sanity checks of first and last session:"
compute_range ${range[@]} | while read M N M0 N0 MN0
do
	echo "Check session - ${name_prefix}-$M0:"
	$NOOP scripts/check-sessions.sh --name $name_prefix $M $M
	echo "Content of log/check-$M0.log:"
	$NOOP cat log/check-$M0.log
	echo "Check session - ${name_prefix}-$N0:"
	$NOOP scripts/check-sessions.sh --name $name_prefix $N $N
	echo "Content of log/check-$N0.log:"
	$NOOP cat log/check-$N0.log
done

echo "Get the sessions. The data is written to sessions.csv:"
if [[ -z $NOOP ]]
then
	scripts/get-sessions.sh --name $name_prefix ${range[@]} > sessions.csv
else
	$NOOP scripts/get-sessions.sh --name $name_prefix ${range[@]}
fi
echo "wc sessions.csv"
$NOOP wc sessions.csv
