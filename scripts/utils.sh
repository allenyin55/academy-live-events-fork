# Source this file to load common utilities.

DEFAULT_CLUSTER_YAML="ray-project/cluster.yaml"
DEFAULT_NAME_PREFIX="academy-user"
let DEFAULT_M=1
let DEFAULT_N=1

# Construct help in pieces:
session_name_opt='[-n | --name name]'
project_name_opt='[-p | --project name]'
range_opt='[N | M N | M-N | M:N]'

session_name_help() {
    cat <<EOF
    -n | --name name      The name prefix to use. Default is "$DEFAULT_NAME_PREFIX". The number will be appended to it.
EOF
}

project_name_help() {
    cat <<EOF
    -p | --project name   The name of your Anyscale project; will correspond to /usr/ubuntu/<project_name> directory.
                          Defaults to the value for "cluster_name" in ray-project/cluster.yaml.
EOF
}

range_help() {
    cat <<EOF
    N | M N | M-N | M:N   Four ways to specify how many sessions to create or a range of numbers from N-M, inclusive.
                          With one value N, M defaults to 1. Default is $M-$N.
EOF
}

slow_warning() {
    cat <<EOF

WARNING: It currently isn't possible to run this in parallel reliably, so this script
         runs ONE AT A TIME, which is very slow.
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
    cat <<EOF
$script_name: $tagline.

Usage: $script_name [-h | --help] $(eval echo $(echo ${cmd_flags[@]}))
Where:
    -h | --help           Print this message and exit.
EOF
    for h in ${cmd_helps}
    do
        eval $(echo $h)
    done
    eval $(echo $post_help_messages)
}

# When you want to use this "empty" help, override help in the script to call this:
empty_help() {
    cat <<EOF
$script_name: $tagline.

Usage: $script_name [-h|--help]
Where:
    -h | --help    Print this message and exit
EOF
}

error() {
    echo "ERROR: $@" >&2
    help >&2
    exit 1
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
    echo "$@" | sed -e 's/[:-]/ /' | while read min max
    do
        if [[ -z $max ]]
        then
            M=1
            N=$min
        else
            M=$min
            N=$max
        fi
    done
    echo $M $N
}

# From the passed in arguments, compute the range and also
# the zero-padded min and max values.
compute_range() {
    M=1
    N=1
    [[ $# -gt 2 ]] && error "Unexpected arguments $@"
    if [[ $# -gt 0 ]]
    then
        split_range "$@" | while read m n; do
            M=$m
            N=$n
        done
    fi

    M0=$(zero_pad $M)
    N0=$(zero_pad $N)
    echo $M $N $M0 $N0
}

get_project_name() {
    yaml="$@"
    [[ -z $yaml ]] && yaml=$DEFAULT_CLUSTER_YAML
    grep cluster_name "$yaml" | sed -e 's/^[^:]*: *\(.*\)/\1/'
}
