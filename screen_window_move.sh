#!/bin/bash
# Moves current window to specified screen. 
#
# date:		04/05/13
# author:	rednammoc

# TODO:
# * Verify that move was successful. When not, the window is may be bigger than the actual screen.
# 	 This is actually a problem, when you want to move the window one to the left or right again,
# 	  which then does not work as expected.
# * Dynamically get screen count. For now you need to configure screen count manually.

# Global variables
SCREEN_COUNT=3
WINDOW_ID=

usage ()
{
    echo "Usage $0 (-l|--left, -r|--right, -p|--position <POSITION>, -w|--window <ID>, -h|--help)"
}

screen_identify ()
{
    WINDOW_ID=$(xdotool getwindowfocus)
    WINDOW_X=$(xwininfo -metric -id $(xdotool getwindowfocus) | 
        awk -F":" '{ 
           if ( $1 == "  Absolute upper-left X" ) { print $2 }
        }' |
        awk -F" " '{ print $1 }')
    WINDOW_SCREEN_POSITION=

    for SCREEN in $(seq 1 ${SCREEN_COUNT})
    do
        # Grep the starting point of each screen (e.g. 0, 1680, ...)
        SCREEN_X=$(grep "Screen" /etc/X11/xorg.conf -m${SCREEN_COUNT} | sed -n "${SCREEN}p" | cut -f3 -d\" | awk '{ print $1 }' )

        if [[ $WINDOW_X -lt $SCREEN_X ]]
        then
            # Notice the offset of -1 which is neccesary cause SCREEN_X starts at 0.
            WINDOW_SCREEN_POSITION=$(($SCREEN - 1))
            break
        fi
    done

    # WINDOW_SCREEN_POSITION will not be set when the window is at the last screen. So we set it now.
    if [ -z "$WINDOW_SCREEN_POSITION" ] ; then WINDOW_SCREEN_POSITION="$SCREEN_COUNT"; fi
    echo $WINDOW_SCREEN_POSITION
}

move_left ()
{
    window_pos=$( screen_identify )
    move_to $(( $window_pos - 1 ))
}

move_right ()
{
    window_pos=$( screen_identify )
    move_to $(( $window_pos + 1 ))
}

move_to ()
{
    SCREEN="$1"
    if [[ $SCREEN -lt 1 ]] || [[ $SCREEN -gt $SCREEN_COUNT ]]
    then
        echo "ERROR: Can not move to invalid screen #$SCREEN."
        exit 1
    fi

    if [[ $SCREEN -eq $( screen_identify ) ]]
    then
        echo "WARNING: Window already at screen $SCREEN."
        exit 0
    fi

    POS=$(grep "Screen" /etc/X11/xorg.conf -m${SCREEN_COUNT} | sed -n "${SCREEN}p" | cut -f3 -d\")

	# Move current window when there was no preselection.
	if [ -z "${WINDOW_ID}" ]; then WINDOW_ID=$(/usr/bin/xdotool getwindowfocus); fi

    /usr/bin/xdotool windowmove $WINDOW_ID $POS
}

ARGS=`getopt -o "lrp:w:?" -l "left,right,position:,window:help" \
    -n "screen_window.move.sh" -- "$@"`

#Bad arguments
if [ $# -eq 0 ]
then
    usage
    exit 1
fi

eval set -- "$ARGS"
while true
do
    case "$1" in
        -l|--left)
            move_left
            shift;;
        -r|--right)
            move_right
            shift;;
        -p|--position)
            if [ -n "$2" ]
            then
                move_to "$2"
            else
				usage
                exit 1
            fi
            shift 2;;
		-w|--window)
			if [ -n "$2" ]
			then
				WINDOW_ID=$2
			else
				usage
				exit 1
			fi
			shift 2;;
        -h|--help)
            usage
            exit 1;;
        --)
            shift
            break;;
    esac
done
