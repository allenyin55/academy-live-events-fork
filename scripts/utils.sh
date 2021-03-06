# Source this file to load common utilities.

DEFAULT_CLUSTER_YAML="ray-project/cluster.yaml"
DEFAULT_PROJECT_YAML="ray-project/project.yaml"
DEFAULT_NAME_PREFIX="academy-user"
let DEFAULT_M=1
let DEFAULT_N=1

# Construct help in pieces:
help_opt='[-h | --help]'
no_exec_opt='[--no | --no-exec]'
session_name_opt='[-n | --name name]'
project_name_opt='[-p | --project name]'
snapshot_id_opt='[-s | --snapshot id]'
range_opt='[N | M N | M-N | M:N]'

help_help() {
    cat <<EOF
    -h | --help           Print this message and exit.
EOF
}

no_exec_help() {
    cat <<EOF
    --no | --no-exec      Just print the commands, don't execute them.
EOF
}

session_name_help() {
    cat <<EOF
    -n | --name name      The session name prefix to use. Default is "$DEFAULT_NAME_PREFIX". The number will be appended to it.
EOF
}

project_name_help() {
    cat <<EOF
    -p | --project name   The name of the Anyscale project; will correspond to /usr/ubuntu/<project_name> directory.
                          Defaults to the value for "cluster_name" in ray-project/cluster.yaml.
EOF
}

snapshot_id_help() {
    cat <<EOF
    -s | --snapshot id    The snapshot to use. By default a snapshot of the current project directory is created.
                          Use of this option is recommended. Use the snapshot created when you create the project.
                          Its UUID is printed to the console.
EOF
}

range_help() {
    cat <<EOF
    N | M N | M-N | M:N   Four ways to specify the range of session numbers from N-M, inclusive.
                          With one value N, M defaults to 1. Default is $M-$N.
EOF
}

slow_warning() {
    cat <<EOF

WARNING: Some commands must be run serially, which can be quite slow.
EOF
}

# Define the following in each script:
# For cmd_opts, use "session_name", etc.
# script_name=
# cmd_opts=()
# post_help_messages=()

help() {
    cmd_flags=( $(for x in ${cmd_opts[@]}; do echo $(echo \$${x}_opt); done) )
    cmd_helps=( $(for x in ${cmd_opts[@]}; do echo $(echo ${x}_help); done) )
    cat << EOF
$script_name: $tagline.

Usage: $script_name $(eval echo $(echo ${cmd_flags[@]}))
Where:
EOF
    for h in ${cmd_helps}
    do
        eval $(echo $h)
    done

    cat <<EOF2
$post_help_messages

TIP: To see what commands will be executed without running them, use --no-exec.
     This is equivalent to running: NOOP=info $script_name ...
EOF2
}

# When you want to use this "empty" help, override help in the script to call this:
empty_help() {
    cat <<EOF
$script_name: $tagline.

Usage: $script_name $help_opt $no_exec_opt
Where:
$(help_help)
$(no_exec_help)

TIP: To see what commands will be executed without running them, use --no-exec.
     This is equivalent to running: NOOP=info $script_name ...
EOF
}

error() {
    echo "ERROR: ($script_name) $@" >&2
    help >&2
    exit 1
}

warning() {
    noln=
    if [[ $1 = "-n" ]]
    then
        noln="-n"
        shift
    fi
    echo $noln "WARN: ($script_name)  $@" >&2
}

info() {
    noln=
    if [[ $1 = "-n" ]]
    then
        noln="-n"
        shift
    fi
    echo $noln "INFO: ($script_name)  $@" >&2
}

no_exec() {
    export NOOP=info
}

# usage zero_pad N [number_digits]
# where number_digits defaults to 3
zero_pad() {
    number=$1
    number_digits=$2
    [[ -z $number_digits ]] && number_digits=3
    printf "%0${number_digits}d" $number
}

# Determine the range provided by the user:
# Usage:
# split_range M N
# split_range M:N
# split_range M-N
# split_range N  # implies M==1
# If N<M, the scripts will actually count DOWN from M to N!
split_range() {
    echo "$@" | sed -e 's/[:-]/ /' | read min max
    if [[ -z $max ]]
    then
        M=1
        N=$min
    else
        M=$min
        N=$max
    fi
    echo $M $N
}

# From the passed in arguments, compute the range, the zero-padded
# min and max values, and a string for the range that is "00M-00N"
# unless the min and max are equal, in which case "00M" is returned.
compute_range() {
    M=1
    N=1
    [[ $# -gt 2 ]] && error "Unexpected arguments $@"
    if [[ $# -gt 0 ]]
    then
        split_range "$@" | read M N
    fi

    M0=$(zero_pad $M)
    N0=$(zero_pad $N)
    MN0="$M0-$N0"
    [[ $M0 = $N0 ]] && MN0=$M0

    echo $M $N $M0 $N0 $MN0
}

edit_project_name() {
    project_name=$1
    shift
    yamls=("$@")
    [[ ${#yamls[@]} -eq 0 ]] && yamls=($DEFAULT_CLUSTER_YAML $DEFAULT_PROJECT_YAML)

    for y in "${yamls[@]}"
    do
        $NOOP sed -i.bak -e "s/^\(.*name\): \(.*\)$/\1: $project_name/" $y
    done
}

get_project_name() {
    yaml="$@"
    [[ -z $yaml ]] && yaml=$DEFAULT_CLUSTER_YAML
    grep cluster_name "$yaml" | sed -e 's/^[^:]*: *\(.*\)/\1/'
}

