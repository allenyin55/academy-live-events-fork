# Source this file to load common utilities.

help() {
	cat <<EOF
$script_name: $tagline.

Usage: $script_name [-h | --help] [-n | --name name] [N | M N | M-N | M:N]
Where:
	-h | --help           Print this message and exit.
	-n | --name name      The name prefix to use. Default is "$name_prefix". The number will be appended to it.
	N | M N | M-N | M:N   Four ways to specify how many sessions to create or a range of numbers from N-M, inclusive.
	                      With one value N, M defaults to 1. Default is $M-$N.
EOF
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

# usage:
# split_range M N
# split_range M:N
# split_range M-N
# split_range N  # implies M==1
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