#!/bin/bash

_logger(){
    echo "$(date +"%Y-%m-%d %H:%M:%S") :: ${@}"
}

[[ -z $1 ]] && _logger "No FIFO pipe path provided." && exit 30
[[ -z $2 ]] && _logger "No 'command message' provided." && exit 31

# FIFO pipe path
FIFO="$1"
BUFFER_FILE="${FIFO}.buffer"
LOCK_FILE="/tmp/$(basename "$FIFO").lock"
RETRY_LIMIT=5
WAIT_TIME=1

_check_if_fifo_exist(){
    if [ ! -p "$FIFO" ]; then
        _logger "FIFO $FIFO does not exist. Storing message in temp file."
        return 1
    fi
    return 0
}

_acquire_lock(){
    local lock_attempt=0
    while ! (exec 200>"$LOCK_FILE" && flock -n 200); do
        lock_attempt=$((lock_attempt + 1))
        if [ $lock_attempt -ge $RETRY_LIMIT ]; then
            _logger "Failed to acquire lock after $RETRY_LIMIT attempts. Giving up."
            exit 1
        fi
        _logger "Waiting to acquire lock... Attempt $lock_attempt"
        sleep $WAIT_TIME
    done
}

# Release lock
_release_lock(){
    exec 200>&-
}

# Check if the consumer is running by looking for processes tied to the FIFO
_check_if_consumer_running(){
    if ps aux | grep "rabbitsh $FIFO" > /dev/null; then
        return 0
    else
        return 1
    fi
}

_checks_before_process() {
    local message="$1"

    if ! _check_if_fifo_exist || ! _check_if_consumer_running; then
        _logger "Consumer not running or FIFO unavailable. Storing message in temp file."
        echo "$message" >> "$BUFFER_FILE"
        exit 0
    fi
}

_send_message() {
    local attempt=0
    local success=0

    while [ $attempt -lt $RETRY_LIMIT ]; do
        if { echo "$message"; } > "$FIFO"; then
            success=1
            break
        else
            _logger "Failed to send: '$message'. Retrying in $WAIT_TIME seconds..."
            sleep $WAIT_TIME
        fi
        attempt=$((attempt + 1))
    done

    _release_lock

    if [ $success -eq 0 ]; then
        _logger "Failed to send message after '$RETRY_LIMIT' attempts. Giving up."
        exit 1
    fi

    exit 0
}

# Write message to FIFO or store in temp file if FIFO or consumer is not available
send_to_fifo() {
    local message="$1"

    touch $BUFFER_FILE;

    _checks_before_process $message

    _acquire_lock

    _send_message
}

send_to_fifo "${@:2}"
