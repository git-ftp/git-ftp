#!/bin/sh
#
# Copyright (c) 2010 
# René Moser <mail@renemoser.net>
# Eric Greve <ericgreve@gmail.com>
# Timo Besenreuther <timo.besenreuther@gmail.com>
#

# ------------------------------------------------------------
# Setup Environment
# ------------------------------------------------------------

# General config
DEFAULT_PROTOCOL="ftp"
DEPLOYED_SHA1_FILE=".git-ftp.log"
GIT_BIN="/usr/bin/git"
CURL_BIN="/usr/bin/curl"
LCK_FILE="`basename $0`.lck"

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------
URL=""
REMOTE_PROTOCOL=""
REMOTE_HOST=""
REMOTE_USER=${USER}
REMOTE_PASSWD=""
REMOTE_PATH=""
VERBOSE=0
IGNORE_DEPLOYED=0
DRY_RUN=0
FORCE=0

VERSION='0.0.6'
AUTHORS='Rene Moser <mail@renemoser.net>, Eric Greve <ericgreve@gmail.com>, Timo Besenreuther <timo.besenreuther@gmail.com>'
 
usage_long()
{
cat << EOF
USAGE: 
        git ftp [<options>] <url> [<options>]

DESCRIPTION:
        Uploads all files which have changed since last upload. 

        Version $VERSION
        Authors $AUTHORS

URL:
        .   default     host.example.com[:<port>][/<remote path>]
        .   FTP         ftp://host.example.com[:<port>][/<remote path>]

OPTIONS:
        -h, --help      Show this message
        -u, --user      FTP login name
        -p, --passwd    FTP password
        -D, --dry-run   Dry run: Does not upload anything
        -a, --all       Uploads all files, ignores deployed SHA1 hash
        -f, --force     Force, does not ask questions
        -v, --verbose   Verbose
        
EXAMPLES:
        .   git ftp -u john ftp://ftp.example.com:4445/public_ftp -p -v
        .   git ftp -p -u john -v ftp.example.com:4445:/public_ftp 
EOF
exit 0
}

usage()
{
cat << EOF
git ftp [<options>] <url> [<options>]
EOF
exit 1
}

ask_for_passwd() {
    echo -n "Password: "
    stty -echo
    read REMOTE_PASSWD
    stty echo
    echo ""
}

# Checks if last comand was successful
check_exit_status() {
    if [ $? -ne 0 ]; then
        write_error "$1, exiting..." 
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

upload_file() {
    source_file=${1}
    dest_file=${2}
    if [ -z ${dest_file} ]; then
        dest_file=${source_file}
    fi
    ${CURL_BIN} -T ${source_file} --user ${REMOTE_USER}:${REMOTE_PASSWD} --ftp-create-dirs -# ftp://${REMOTE_HOST}/${REMOTE_PATH}${dest_file}
}

remove_file() {
    file=${1}
    ${CURL_BIN} --user ${REMOTE_USER}:${REMOTE_PASSWD} -Q '-DELE ${REMOTE_PATH}${file}' ftp://${REMOTE_HOST}
}

get_file_content() {
    source_file=${1}
    ${CURL_BIN} -s --user ${REMOTE_USER}:${REMOTE_PASSWD} ftp://${REMOTE_HOST}/${REMOTE_PATH}${source_file}
}

while test $# != 0
do
	case "$1" in
	    -h|--h|--he|--hel|--help)
		    usage_long
		    ;;
        -u|--user*)
            case "$#,$1" in
                *,*=*)
                    REMOTE_USER=`expr "z$1" : 'z-[^=]*=\(.*\)'`
                    ;;
                1,*)
                    usage 
                    ;;
                *)
                    if [ ! `echo "${2}" | egrep '^-' | wc -l` -eq 1 ]; then
                        REMOTE_USER="$2"
                        shift                        
                    fi
                    ;;                      
            esac
            ;;
        -p|--passwd*)
            case "$#,$1" in
                *,*=*)
                    REMOTE_PASSWD=`expr "z$1" : 'z-[^=]*=\(.*\)'`
                    ;;
                1,*)
                    ask_for_passwd 
                    ;;
                *)
                    if [ ! `echo "${2}" | egrep '^-' | wc -l` -eq 1 ]; then
                        REMOTE_PASSWD="$2"
                        shift
                    else 
                        ask_for_passwd
                    fi
                    ;;
            esac
            ;;
        -a|--all)
            IGNORE_DEPLOYED=1
            ;;
        -D|--dry-run)
            DRY_RUN=1
            write_info "Running dry, won't do anything"            
            ;;
        -v|--verbose)
            VERBOSE=1
            ;;
        -f|--force)
            FORCE=1
            write_log "Forced mode enabled"
            ;;		
        *)
            # Pass thru anything that may be meant for fetch.
            URL=${1}
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

if [ ${FORCE} -ne 1 ]; then
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
fi

# Split host from url
REMOTE_HOST=`echo "${URL}" | sed "s/.*:\/\/\([a-z0-9\.:-]*\).*/\1/"`
if [ -z ${REMOTE_HOST} ]; then
    REMOTE_HOST=`echo "${URL}" | sed "s/^\([a-z0-9\.:-]*\).*/\1/"`
fi

# Some error checks
HAS_ERROR=0
if [ -z ${REMOTE_HOST} ]; then
    write_error "FTP host not set"
    HAS_ERROR=1
fi

if [ -z ${REMOTE_USER} ]; then
    write_error "FTP user not set"
    HAS_ERROR=1
fi

if [ ${HAS_ERROR} -ne 0 ]; then
    usage
    release_lock
    exit 1
fi

# Split protocol from url 
REMOTE_PROTOCOL=`echo "${URL}" | sed "s/\(ftp\).*/\1/"`

# Check supported protocol
if [ -z ${REMOTE_PROTOCOL} ]; then
    write_info "Protocol unknown or not set, using default protocol '${DEFAULT_PROTOCOL}'"
    REMOTE_PROTOCOL=${DEFAULT_PROTOCOL}
fi

# Split remote path from url
REMOTE_PATH=`echo "${URL}" | sed "s/.*\.[a-z0-9:]*\/\(.*\)/\1/"`

# Add trailing slash if missing 
if [ ! -z ${REMOTE_PATH} ] && [ `echo "${REMOTE_PATH}" | egrep "*/$" | wc -l` -ne 1 ]; then
    write_log "Added missing trailing / in path"
    REMOTE_PATH="${REMOTE_PATH}/"  
fi

write_log "Host is '${REMOTE_HOST}'"
write_log "User is '${REMOTE_USER}'"
write_log "Path is '${REMOTE_PATH}'"

DEPLOYED_SHA1=""
if [ ${IGNORE_DEPLOYED} -ne 1 ]; then
    # Get the last commit (SHA) we deployed if not ignored or not found
    write_log "Retrieving last commit from ftp://${REMOTE_HOST}/${REMOTE_PATH}"
    DEPLOYED_SHA1="`get_file_content ${DEPLOYED_SHA1_FILE}`"
    if [ $? -ne 0 ]; then
        write_info "Could not get last commit or it does not exist"
        DEPLOYED_SHA1=""
    fi
fi

if [ "${DEPLOYED_SHA1}" != "" ]; then
    write_log "Last deployed SHA1 for ${REMOTE_HOST} is ${DEPLOYED_SHA1}"

    # Get the files changed since then
    FILES_CHANGED="`${GIT_BIN} diff --name-only ${DEPLOYED_SHA1} 2>/dev/null`" 
    if [ $? -ne 0 ]; then
        if [ ${FORCE} -ne 1 ]; then
        write_info "Unknown SHA1 object, make sure you are deploying the right branch and it is up-to-date. 
Do you want to ignore and upload all files again? [y/N]"
        read answer_state
        if [ "${answer_state}" != "y" ] && [ "${answer_state}" != "Y" ]; then
            write_info "Aborting..."
            release_lock
            exit 0
        else
            write_log "Taking all files";
            FILES_CHANGED="`${GIT_BIN} ls-files`"
        fi
        else 
            write_info "Unknown SHA1 object, could not determine changed filed, taking all files"
            FILES_CHANGED="`${GIT_BIN} ls-files`"
        fi    
    elif [ "${FILES_CHANGED}" != "" ]; then 
        write_log "Having changed files";
    else 
        write_info "No changed files for ${REMOTE_HOST}. Everything up-to-date."
        release_lock
        exit 0
    fi
else 
    write_log "No last deployed SHA1 for ${REMOTE_HOST} found or forced to take all files"
    FILES_CHANGED="`${GIT_BIN} ls-files`"
fi

# Upload to ftp
for file in ${FILES_CHANGED}; do
    # File exits?
    if [ -f ${file} ]; then 
        # Uploading file
        write_info "Uploading ${file} to ftp://${REMOTE_HOST}/${REMOTE_PATH}${file}"
        if [ ${DRY_RUN} -ne 1 ]; then
            upload_file ${file}
            check_exit_status "Could not upload"
        fi
    else
        # Removing file
        write_info "Not existing file ${REMOTE_PATH}${file}, removing..."
        if [ ${DRY_RUN} -ne 1 ]; then
            remove_file ${file}             
            check_exit_status "Could not remove file ${REMOTE_PATH}${file}"
        fi
    fi
done
 
# if successful, remember the SHA1 of last commit
DEPLOYED_SHA1=`${GIT_BIN} log -n 1 --pretty=%H`
write_info "Uploading commit log to ftp://${REMOTE_HOST}/${REMOTE_PATH}${DEPLOYED_SHA1_FILE}"
if [ ${DRY_RUN} -ne 1 ]; then
    echo "${DEPLOYED_SHA1}" | upload_file - ${DEPLOYED_SHA1_FILE}
    check_exit_status "Could not upload"
fi
write_log "Last deployment changed to ${DEPLOYED_SHA1}";

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------
release_lock

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
exit 0
