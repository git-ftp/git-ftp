#!/bin/sh
#
# Copyright (c) 2010 René Moser
#

# ------------------------------------------------------------
# Setup Environment
# ------------------------------------------------------------

# General config
GIT_FTP_HOME=".git/git-ftp"
DEPLOYED_FILE="deployed-sha1"
GIT_BIN="/usr/bin/git"
CURL_BIN="/usr/bin/curl"
LCK_FILE="`basename $0`.lck"

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------
FTP_HOST=""
FTP_USER=""
FTP_PASSWD=""
FTP_REMOTE_PATH=""
VERBOSE=0
IGNORE_DEPLOYED=0

VERSION='0.0.2'
AUTHOR='Rene Moser <mail@renemoser.net>'
 
usage()
{
cat << EOF
Usage: $0 -H <ftp_host> -u <ftp_login> -p <ftp_password>

Version $VERSION
Author $AUTHOR

Uploads all files in master branch which have changed since last FTP upload. 
 
OPTIONS:
        -h      Show this message
        -u      FTP login name
        -p      FTP password
        -H      FTP host URL p.e. ftp.example.com
        -P      FTP remote path p.e. public_ftp/
        -v      Verbose
        
EOF
}

while getopts haH:u:p:v OPTION
do
    if [ `echo "$OPTARG" | egrep '^-' | wc -l` -eq 1 ]
    then
        echo "options value are not allowed to begin with -"
        exit 1
     fi
 
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        H)
            FTP_HOST=$OPTARG
            ;;
        u)
            FTP_USER=$OPTARG
            ;;
        p)
            FTP_PASSWD=$OPTARG
            ;;
        P)
            FTP_REMOTE_PATH=$OPTARG
            ;;
        a)
            IGNORE_DEPLOYED=1
            ;;
        v)
            VERBOSE=1
            ;;
        ?)
            usage
            exit 1
            ;;
     esac
done


# Simple log func
writeLog() {
    if [ $VERBOSE -eq 1 ]; then
        echo "`date`: $1"
    fi
}

# Simple error writer
writeError() {
    echo "fatal: $1"
}

# Release lock func
releaseLock() {
    writeLog "Releasing lock"
    rm -f "${LCK_FILE}"
}

# Checks locking, make sure this only run once a time
if [ -f "${LCK_FILE}" ]; then

    # The file exists so read the PID to see if it is still running
    MYPID=`head -n 1 "${LCK_FILE}"`

    TEST_RUNNING=`ps -p ${MYPID} | grep ${MYPID}`

    if [ -z "${TEST_RUNNING}" ]; then
        # The process is not running echo current PID into lock file
        writeLog "Not running"
        echo $$ > "${LCK_FILE}"
    else
        writeLog "`basename $0` is already running [${MYPID}]"
        exit 0
    fi
else
    writeLog "Not running"
    echo $$ > "${LCK_FILE}"
fi

# ------------------------------------------------------------
# Main part
# ------------------------------------------------------------

# Check if this is a git project here
if [ ! -d ".git" ]; then
    writeError "Not a git project? Exiting..."
    releaseLock
    exit 0
fi 

# Check if the git working dir is dirty
DIRTY_REPO=`${GIT_BIN} update-index --refresh | wc -l ` 
if [ ${DIRTY_REPO} -eq 1 ]; then 
    writeError "Dirty Repo? Exiting..."
    releaseLock
    exit 0
fi 

# Check if are at master branch (temp solution)
CURRENT_BRANCH="`${GIT_BIN} branch | grep '*' | cut -d ' ' -f 2`" 
if [ "${CURRENT_BRANCH}" != "master" ]; then 
    writeError "Not master branch? Exiting..."
    releaseLock
    exit 0
fi 

# create home if not exists
mkdir -p ${GIT_FTP_HOME}

# Check if there is a config file containing FTP stuff   
HAS_ERROR=0
if [ -z ${FTP_HOST} ]; then
    writeError "FTP host not set"
    HAS_ERROR=1
fi

if [ -z ${FTP_USER} ]; then
    writeError "FTP user not set in config file"
    HAS_ERROR=1
fi

if [ ${HAS_ERROR} != 0 ]; then
    usage
    releaseLock
    exit 0
fi

# Check if we already deployed by FTP
if [ ! -f "${GIT_FTP_HOME}/${DEPLOYED_FILE}" ]; then
    touch ${GIT_FTP_HOME}/${DEPLOYED_FILE}
    writeLog "Created empty file ${GIT_FTP_HOME}/${DEPLOYED_FILE}"
fi 

# Get the last commit (SHA) we deployed if not ignored or not found
DEPLOYED_SHA1="`head -n 1 ${GIT_FTP_HOME}/${DEPLOYED_FILE} | cut -d ' ' -f 2`"
if [ ${IGNORE_DEPLOYED} -ne 1 ] && [ "${DEPLOYED_SHA1}" != "" ]; then
    writeLog "Last deployed SHA1 is ${DEPLOYED_SHA1}"

    # Get the files changed since then
    FILES_CHANGED="`${GIT_BIN} diff --name-only ${DEPLOYED_SHA1}`"
    if [ "${FILES_CHANGED}" != "" ]; then 
        writeLog "Having changed files";
    else 
        writeLog "No changed files. Giving up..."
        releaseLock
        exit 0
    fi
else 
    writeLog "No last deployed SHA1 found or ignoring it"
    FILES_CHANGED="`${GIT_BIN} ls-files`"
    writeLog "Taking all files"
fi

# Upload to ftp
for file in ${FILES_CHANGED}; do 
    
    # File exits?
    if [ -f ${file} ]; then 
        # Uploading file
        writeLog "Uploading ${file} to ftp://${FTP_HOST}/${file}"
        ${CURL_BIN} -T ${file} --user ${FTP_USER}:${FTP_PASSWD} --ftp-create-dirs -# ftp://${FTP_HOST}/${FTP_REMOTE_PATH}${file}
    else
        writeLog "Not existing file ${file}"
        # Removing file
        writeLog "Removing ${file}"
        ${CURL_BIN} --user ${FTP_USER}:${FTP_PASSWD} -Q '-DELE ${FTP_REMOTE_PATH}${file}' ftp://${FTP_HOST} > /dev/null 2>&1
    fi
done
 
# if successful, remember the SHA1 of last commit
${GIT_BIN} log -n 1 > ${GIT_FTP_HOME}/${DEPLOYED_FILE}
writeLog "Last deployment changed to `cat ${GIT_FTP_HOME}/${DEPLOYED_FILE}`";

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------
releaseLock

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
exit 0
