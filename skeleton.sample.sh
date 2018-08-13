#!/bin/bash 


#########################
# IMPORT ENV VARS HERE ##
#########################



#########################
# ENV SETTINGS ##########
#########################
set -e                      # exit all shells if script fails
set -u                      # exit script if uninitialized variable is used
set -o pipefail             # exit script if anything fails in pipe
# set -x;                   # debug mode



#########################
# GLOBALS ###############
#########################
declare -ra ARGS=("$@")

CALLING_DIRPATH="$(pwd)"; declare -r CALLING_DIRPATH
SCRIPT_FILENAME="$(basename "${0}")"; declare -r SCRIPT_FILENAME
SCRIPT_DIRPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; declare -r SCRIPT_DIRPATH
declare -r SCRIPT_FILEPATH="${SCRIPT_DIRPATH}/${SCRIPT_FILENAME}"

LOG_FILE="/tmp/$(date +%s).log"; declare -r LOG_FILE


#########################
# UTILITY FUNCTIONS  ####
#########################

function log(){
    local -r msg="${1}"
    local -r full_msg="${SCRIPT_FILENAME}: ${msg}"

    echo "${full_msg}" >&2
    echo "${full_msg}" >> "${LOG_FILE}"
}


function error_log(){
    local -r msg="${1}"
    log "ERROR: ${msg}"
    exit 1
}


function warning_log(){
    local -r msg="${1}"
    log "WARNING (1/2): ${msg}"
    log "WARNING (2/2): continuing"
}


function log_func(){
    local -r function_name="${1}"
    log "${function_name}()"
}


function usage(){
    log_func "${FUNCNAME[0]}"
}




#########################
# FUNCTIONS #############
#########################


#########################
# INIT ##################
#########################

function initialize_input(){
    log_func "${FUNCNAME[0]}"

    local -ra args=( "${@}" )

    local is_help='false'
    local is_flags='true'

    local -r opts=$( getopt -o dish --long ,help -- "${args[@]}" );
    eval set -- "${opts}";
    while true ; do
        case "${1}" in
            --help)
                is_help='true'
                is_flags='true'
                shift 1;
                ;;
            *)
                break;
                ;;
        esac
    done;

    ###########################
    # CREATES GLOBAL VARIABLES
    readonly IS_HELP="${is_help}"
    readonly IS_FLAGS="${is_flags}"
    # CREATES GLOBAL VARIABLES
    ###########################
}


function validate_input(){
    log_func "${FUNCNAME[0]}"
}


function initialize(){
    log_func "${FUNCNAME[0]}"
    
    initialize_input "${ARGS[@]-}"
}


#########################
# MAIN ##################
#########################

function main(){
    log_func "${FUNCNAME[0]}"

    initialize
    
    exit 0
}
main




