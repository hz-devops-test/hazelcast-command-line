#!/usr/bin/env bash

# templates meant to be resolved at build or install time
HAZELCAST_VERSION=${hazelcast_version}

# display help for this command
function helper() {
    echo "Usage:  $CMD start [-v | --verbose] [-j <path> | --jar <path>]"
    echo
    echo "Start a Hazelcast member."
    echo
    echo "Options:"
    echo "  -v or --verbose"
    echo "        Show extra info about running environment."
    echo
    echo "  -j or --jar <path>"
    echo "        Add <path> to Hazelcast class path."
}

# echo available options
function optionlist() {
    echo -v --verbose -j --jar
}

# echo available commands; ID for Hazelcast member IDs
function commandlist() {
    :
}

#
. $(dirname "$0")/utils.sh

#
mkdir -p "${PID_BASE_DIR}"
mkdir -p "${LOG_BASE_DIR}"

# parse options
declare VERBOSE CP
while (( "$#" ))
do
    case "$1" in
        -v | --verbose)
            VERBOSE=1
            shift
            ;;
        -j | --jar)
            CP="$2"
            if [[ -z ${CP} ]] ; then
                printf "Error: missing <path> after %s\n\n" "$1"
                helper && exit 1
            fi
            shift 2
            ;;
        *)
            printf "Invalid argument: %s\n\n" "$1"
            helper && exit 1
    esac
done

if [ $JAVA_HOME ]
then
	RUN_JAVA=$JAVA_HOME/bin/java
else
    RUN_JAVA=`which java 2>/dev/null`
fi

if [ -z $RUN_JAVA ]
then
    echo "Error: Java not found. Please install Java 1.6 or higher in your PATH or set JAVA_HOME appropriately"
    exit 1
fi

#### you can enable following variables by uncommenting them

#### minimum heap size
# MIN_HEAP_SIZE=1G

#### maximum heap size
# MAX_HEAP_SIZE=1G


if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

export CLASSPATH="$HAZELCAST_HOME/lib/hazelcast-all-${HAZELCAST_VERSION}.jar"
if [ ${CP} ]; then
	CLASSPATH="$CLASSPATH:$CP"
fi

if [ ${VERBOSE} ] ; then
    echo "RUN_JAVA=$RUN_JAVA"
    echo "JAVA_OPTS=$JAVA_OPTS"
    echo "CLASSPATH=$CLASSPATH"
fi

make_HID

PID=$(cat "${PID_FILE}" 2>/dev/null);
if [ -z "${PID}" ]; then
    [ ${VERBOSE} ] && echo "PID file for this Hazelcast member: $PID_FILE"
    [ ${VERBOSE} ] && echo "Permanent logfile for this Hazelcast member: $LOG_FILE"
    nohup $RUN_JAVA -server $JAVA_OPTS com.hazelcast.core.server.StartServer >>"${LOG_FILE}" 2>&1 &
    HZ_PID=$!
    echo ${HZ_PID} > ${PID_FILE}
    echo "ID:  ${HID}"
    [ ${VERBOSE} ] && echo "PID: ${HZ_PID}"
else
    echo "Error: Another Hazelcast instance (PID=${PID}) is already started in this folder"
    exit 1
fi