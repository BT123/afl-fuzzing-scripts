#!/bin/bash
echo "Script to run afl on multicore machine by floyd, http://floyd.ch, @floyd.ch"
echo "After you ran this script successfully, run as many runXXX.sh scripts in this directory as you like fuzzing instances (in other screen windows)."
#assumes afl binaries are in $PATH
#Mandatory options:
BIN="/opt/binary"
BIN_ARGS="@@ /tmp/outfile-$RANDOM.bin" #or /dev/null or whatever
INPUT_OUTPUT_LOC="/opt/test/floyds"
AFL_FUZZ_ARGS="" #-t 1200 or so
#Optional options:
DO_DETERMINISTIC="true"
MAX_NUMBER_OF_INSTANCES="005"
FIRST_TIME_INPUT_DIR="input"
#End Options

INPUT_DEFINING_FILE_NAME="dir-input.txt"
OUTPUT_DEFINING_FILE_NAME="dir-output.txt"
INPUT_DIR=""
OUTPUT_DIR=""

SCRIPT_NAME="`basename $0`"
SCRIPT_DIR="`dirname $0`"
SCRIPT_NUMBER_END="${SCRIPT_NAME#run}"
SCRIPT_NUMBER="${SCRIPT_NUMBER_END%.sh}"

BIN_NAME="`basename $BIN`"

FUZZING_INSTANCE_NAME="$BIN_NAME-$SCRIPT_NUMBER"

if [ "$SCRIPT_NUMBER" = "001" ]; then
    echo "Oh, I'm the main executable. Let's setup everything then."
    for i in $(seq -f "%03g" 2 $MAX_NUMBER_OF_INSTANCES); do
       echo "Copying myself to run$i.sh"
       cp $0 $SCRIPT_DIR/run$i.sh
    done
    echo "Let's figure out the input folder"
    if [ ! -d $INPUT_OUTPUT_LOC/output-001 ]; then
        if [ ! -d $INPUT_OUTPUT_LOC/$FIRST_TIME_INPUT_DIR ]; then
            echo "Please put the first input files into $INPUT_OUTPUT_LOC/$FIRST_TIME_INPUT_DIR/"
            exit 1
        else
            echo "$FIRST_TIME_INPUT_DIR" > $INPUT_DEFINING_FILE_NAME
            echo "output-001" > $OUTPUT_DEFINING_FILE_NAME
        fi
    else
        INPUT_PATH="`find $INPUT_OUTPUT_LOC -type d -name \"output-*\"|sort|tail -1`"
        INPUT="`basename $INPUT_PATH`"
        NUMBER="${INPUT#output-}"
        NUMBER_PLUS_ONE=$((10#$NUMBER + 1))
        NUMBER_PLUS_ONE_THREE_DIGITS="`printf %03d $NUMBER_PLUS_ONE`"
        OUTPUT="output-$NUMBER_PLUS_ONE_THREE_DIGITS"
        echo "Looks like there is a directory $INPUT, using that as an input."
        echo "Using $OUTPUT as the output directory."
        echo "ATTENTION: Only using input from results of fuzzing instance 1, which might not have synced when you aborted?"
        echo "$INPUT/$BIN_NAME-001" > $SCRIPT_DIR/$INPUT_DEFINING_FILE_NAME
        echo "$OUTPUT" > $SCRIPT_DIR/$OUTPUT_DEFINING_FILE_NAME
    fi
fi

INPUT_DIR="`cat $SCRIPT_DIR/$INPUT_DEFINING_FILE_NAME`"
OUTPUT_DIR="`cat $SCRIPT_DIR/$OUTPUT_DEFINING_FILE_NAME`"

if [ "$SCRIPT_NUMBER" = "001" ] && [ "$DO_DETERMINISTIC" = "true" ];  then
    AFL_FUZZ_ARGS="$AFL_FUZZ_ARGS -M $FUZZING_INSTANCE_NAME"
else
    AFL_FUZZ_ARGS="$AFL_FUZZ_ARGS -S $FUZZING_INSTANCE_NAME"
fi

CMD="afl-fuzz -T $FUZZING_INSTANCE_NAME -i $INPUT_OUTPUT_LOC/$INPUT_DIR -o $INPUT_OUTPUT_LOC/$OUTPUT_DIR $AFL_FUZZ_ARGS $BIN $BIN_ARGS"

echo "Executing the following command now:"
echo "$CMD"
echo
if ! screen -ls|grep -iq "Attached"; then
    echo "You are not running screen. Can't let you do that."
    exit 1
fi
echo "Are you in screen?"
sleep 5
$CMD
