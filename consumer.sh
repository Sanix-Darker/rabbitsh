#!/bin/bash

_logger(){
    echo "$(date +"%Y-%m-%d %H:%M:%S") :: ${@}";
}

if [ -z $1 ]; then
    _logger "No FIFO pipe path provided."
    exit 30
fi

# /tmp/fifo-pipes/job-xxxx
FIFO="$1"
DIRNAME=$(dirname "$FIFO")
BUFFER_FILE="${FIFO}.buffer"
WAIT_TIME_IN_SECONDS_PER_ITERATION=0.5

# Create FIFO if it doesn't exist
_create_fifo_if_not_exist(){
    if [ ! -d "$DIRNAME" ]; then
        mkdir -p "$DIRNAME"
    fi

    if [ ! -p "$FIFO" ]; then
        _logger "FIFO $FIFO does not exist."
        mkfifo "$FIFO"
        _logger "$FIFO pipe created..."
    fi
}

# Read and process commands from the buffer
_process_buffer_file(){
    if [ -f "$BUFFER_FILE" ]; then
        while IFS= read -r line; do
            _logger "<buf> get: $line"
        done < "$BUFFER_FILE"
        # Clear buffer after processing
        > "$BUFFER_FILE"
    fi
}

# Read and process commands from the FIFO
_read_from_fifo(){
    while true; do
        if read -t 1 line < "$FIFO"; then
            _logger "Received: $line"

            if [[ $line == *"exit"* ]]; then
                _logger "Stop request captured, shutting down."
                wait
                exit 0
            fi
        fi

        sleep "$WAIT_TIME_IN_SECONDS_PER_ITERATION"
    done
}

_main(){
    _create_fifo_if_not_exist

    # Process any commands that were buffered while the consumer was down
    _process_buffer_file

    # Trap signals for proper shutdown
    trap '_logger "Broken pipe, ignoring..."' PIPE
    trap '_logger "Received signal, shutting down..."; wait; exit 0;' HUP INT TERM

    _logger "Starting rabbitsh..."
    _read_from_fifo
}

_main
