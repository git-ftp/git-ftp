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
DEPLOYED_DIR="deployed-sha1s"
GIT_BIN="/usr/bin/git"
CURL_BIN="/usr/bin/curl"
LCK_FILE="`basename $0`.lck"

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------
FTP_HOST=""
FTP_USER=${USER}
FTP_PASSWD=""
FTP_REMOTE_PATH=""
VERBOSE=0
IGNORE_DEPLOYED=0
DRY_RUN=0

VERSION='0.0.4'
AUTHOR='Rene Moser <mail@renemoser.net>'
 
usage_long()
{
cat << EOF
Usage: git ftp -H <ftp_host> -u <ftp_login> [-p [<ftp_passwd>]]

Uploads all files which have changed since last upload. 

Version $VERSION
Author $AUTHOR
 
OPTIONS:
        -h, --help      Show this message
        -u, --user      FTP login name
        -p, --passwd    FTP password
        -H, --host      FTP host URL p.e. ftp.example.com
        -P, --path      FTP remote path p.e. public_ftp/
        -D, --dry-run   Dry run: Does not upload anything
        -f              Forces to upload all files
        -v              Verbose
        
EOF
exit 0
}

usage()
{
cat << EOF
Usage: git ftp -H <ftp_host> -u <ftp_login> [-p [<ftp_passwd>]]
EOF
exit 1
}

ask_for_passwd() {
    echo -n "Password: "
    stty -echo
    read FTP_PASSWD
    stty echo
    echo ""
}

# Checks if last comand was successful
check_exit_status() {
    if [ $? -ne 0 ]; then
        write_error "Error detected, exiting..." 
        exit 1
    fi
}

# Simple log func
write_log() {
    if [ $VERBOSE -eq 1 ]; then
        echo "`date`: $1"
    fi
}

# Simple error writer
write_error() {
    if [ $VERBOSE -eq 0 ]; then
        echo "Fatal: $1"
    else
        write_log "Fatal: $1"
    fi
}

# Simple info writer
write_info() {
    if [ $VERBOSE -eq 0 ]; then
        echo "Info: $1"
    else
        write_log "Info: $1"
    fi
}

while test $# != 0
do
	case "$1" in
	    -h|--h|--he|--hel|--help)
		    usage_long
		    ;;
        -H|--host*)
            case "$#,$1" in
                *,*=*)
                    FTP_HOST=`expr "z$1" : 'z-[^=]*=\(.*\)'`
                    ;;
                1,*)
                    usage 
                    ;;
                *)
                    if [ ! `echo "${2}" | egrep '^-' | wc -l` -eq 1 ]; then
                        FTP_HOST="$2"
                        shift
                    fi
                    ;;
            esac
            ;;
        -u|--user*)
            case "$#,$1" in
                *,*=*)
                    FTP_USER=`expr "z$1" : 'z-[^=]*=\(.*\)'`
                    ;;
                1,*)
                    usage 
                    ;;
                *)
                    if [ ! `echo "${2}" | egrep '^-' | wc -l` -eq 1 ]; then
                        FTP_USER="$2"
                        shift                        
                    fi
                    ;;                      
            esac
            ;;
        -p|--passwd*)
            case "$#,$1" in
                *,*=*)
                    FTP_PASSWD=`expr "z$1" : 'z-[^=]*=\(.*\)'`
                    ;;
                1,*)
                    ask_for_passwd 
                    ;;
                *)
                    if [ ! `echo "${2}" | egrep '^-' | wc -l` -eq 1 ]; then
                        FTP_PASSWD="$2"
                        shift
                    else 
                        ask_for_passwd
                    fi
                    ;;
            esac
            ;;
        -P|--path*)
            case "$#,$1" in
                *,*=*)
                    FTP_REMOTE_PATH==`expr "z$1" : 'z-[^=]*=\(.*\)'`
                    ;;
                1,*)
                    usage
                    ;;
                *)
                    if [ ! `echo "${2}" | egrep '^-' | wc -l` -eq 1 ]; then
                        FTP_REMOTE_PATH="$2"
                        shift
                    fi
                    ;;
            esac
            ;;
        -f)
            IGNORE_DEPLOYED=1
            ;;
        -D|--dry-run)
            DRY_RUN=1
            write_info "Running dry, won't do anything"            
            ;;
        -v)
            VERBOSE=1
            ;;		
        *)
            # Pass thru anything that may be meant for fetch.
            break
            ;;
    esac
    shift
done

# Release lock func
release_lock() {
    write_log "Releasing lock"
    rm -f "${LCK_FILE}"
}

# Checks locking, make sure this only run once a time
if [ -f "${LCK_FILE}" ]; then

    # The file exists so read the PID to see if it is still running
    MYPID=`head -n 1 "${LCK_FILE}"`

    TEST_RUNNING=`ps -p ${MYPID} | grep ${MYPID}`

    if [ -z "${TEST_RUNNING}" ]; then
        # The process is not running echo current PID into lock file
        write_log "Not running"
        echo $$ > "${LCK_FILE}"
    else
        write_log "`basename $0` is already running [${MYPID}]"
        exit 0
    fi
else
    write_log "Not running"
    echo $$ > "${LCK_FILE}"
fi

# ------------------------------------------------------------
# Main part
# ------------------------------------------------------------

# Check if this is a git project here
if [ ! -d ".git" ]; then
    write_error "Not a git project? Exiting..."
    release_lock
    exit 1
fi 

# Check if the git working dir is dirty
DIRTY_REPO=`${GIT_BIN} update-index --refresh | wc -l ` 
if [ ${DIRTY_REPO} -eq 1 ]; then 
    write_error "Dirty Repo? Exiting..."
    release_lock
    exit 1
fi 

# Check if are at master branch
CURRENT_BRANCH="`${GIT_BIN} branch | grep '*' | cut -d ' ' -f 2`" 
if [ "${CURRENT_BRANCH}" != "master" ]; then 
    write_info "You are not on master branch.
Are you sure deploying branch '${CURRENT_BRANCH}'? [Y/n]"
    read answer_branch
    if [ "${answer_branch}" = "n" ] || [ "${answer_branch}" = "N" ]; then
        write_info "Aborting..."
        release_lock
        exit 0
    fi
fi 

# create home if not exists
mkdir -p ${GIT_FTP_HOME}

# Some error checks
HAS_ERROR=0
if [ -z ${FTP_HOST} ]; then
    write_error "FTP host not set"
    HAS_ERROR=1
fi

if [ -z ${FTP_USER} ]; then
    write_error "FTP user not set"
    HAS_ERROR=1
fi

if [ ! -z ${FTP_REMOTE_PATH} ] && [ `echo "${FTP_REMOTE_PATH}" | egrep "*/$" | wc -l` -ne 1 ]; then
    write_error "Missing trailing / in --path, -P"
    HAS_ERROR=1  
fi

if [ ${HAS_ERROR} -ne 0 ]; then
    usage
    release_lock
    exit 1
fi

write_info "Host is '${FTP_HOST}'"
write_info "User is '${FTP_USER}'"
write_info "Paht is '${FTP_REMOTE_PATH}'"

# Check if we already deployed by FTP
if [ ! -f "${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST}" ]; then
    mkdir -p ${GIT_FTP_HOME}/${DEPLOYED_DIR}
    touch ${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST}
    write_log "Created empty file ${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST}"

    # For backward compatibility
    if [ -f "${GIT_FTP_HOME}/${DEPLOYED_FILE}" ]; then
        write_info "Multi FTP host exsisting sha1 backward compatibility
Should existing sha1 be marked as used for ${FTP_HOST}? [Y/n]"
        read answer_convert
        if [ "${answer_convert}" = "n" ] || [ "${answer_convert}" = "N" ]; then
            write_info "Was not ${FTP_HOST}, continuing..."
        else
            write_info "Converting ${GIT_FTP_HOME}/${DEPLOYED_FILE} to ${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST}"
            cat ${GIT_FTP_HOME}/${DEPLOYED_FILE} > ${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST}
            write_info "Removing old unneeded file ${GIT_FTP_HOME}/${DEPLOYED_FILE}"
            rm  ${GIT_FTP_HOME}/${DEPLOYED_FILE}
        fi
    fi
fi 

# Get the last commit (SHA) we deployed if not ignored or not found
DEPLOYED_SHA1="`head -n 1 ${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST} | cut -d ' ' -f 2`"
if [ ${IGNORE_DEPLOYED} -ne 1 ] && [ "${DEPLOYED_SHA1}" != "" ]; then
    write_log "Last deployed SHA1 for ${FTP_HOST} is ${DEPLOYED_SHA1}"

    # Get the files changed since then
    FILES_CHANGED="`${GIT_BIN} diff --name-only ${DEPLOYED_SHA1}`"
    if [ "${FILES_CHANGED}" != "" ]; then 
        write_log "Having changed files";
    else 
        write_info "No changed files for ${FTP_HOST}. Everything up-to-date."
        release_lock
        exit 0
    fi
else 
    write_log "No last deployed SHA1 for ${FTP_HOST} found or forced to take all files"
    FILES_CHANGED="`${GIT_BIN} ls-files`"
fi

# Upload to ftp
for file in ${FILES_CHANGED}; do
    # File exits?
    if [ -f ${file} ]; then 
        # Uploading file
        write_info "Uploading ${file} to ftp://${FTP_HOST}/${FTP_REMOTE_PATH}${file}"
        if [ ${DRY_RUN} -ne 1 ]; then
            ${CURL_BIN} -T ${file} --user ${FTP_USER}:${FTP_PASSWD} --ftp-create-dirs -# ftp://${FTP_HOST}/${FTP_REMOTE_PATH}${file}
            check_exit_status
        fi
    else
        # Removing file
        write_info "Not existing file ${FTP_REMOTE_PATH}${file}, removing..."
        if [ ${DRY_RUN} -ne 1 ]; then
            ${CURL_BIN} --user ${FTP_USER}:${FTP_PASSWD} -Q '-DELE ${FTP_REMOTE_PATH}${file}' ftp://${FTP_HOST}             
            check_exit_status
        fi
    fi
done
 
# if successful, remember the SHA1 of last commit
if [ ${DRY_RUN} -ne 1 ]; then
    ${GIT_BIN} log -n 1 > ${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST}
fi
write_log "Last deployment changed to `cat ${GIT_FTP_HOME}/${DEPLOYED_DIR}/${FTP_HOST}`";

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------
release_lock

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
exit 0
