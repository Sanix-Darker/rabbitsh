## RABBITSH

>DISCLAIMER:
>This is not a PROD ready stuff... it was made by a random dev after few beers.

This is a basic wrapper over 'named pipe' under unix with buffering and lock.
So it may act like a rabbitMq FIFO queue.

## FEATURES

- Send Messages to a specific queue (linux named pipe).
- No installation needed, only barebone linux needed.
- Buffering in case of indisponibility from queues.
- Locking system to force a "sequential like" writes".

## HOW TO TEST

### WITH DOCKER

- To start the messages consumer :
```bash
$ docker run -u $(id -u):$(id -g) -v ./q:/q -ti sanix-darker/rabbitsh:latest /q/q1

# This will start rabbitsh on queue 'q1',
# with host user having same rights as the one in the container.
# A volume been shared between both ./q/
```

Now, you can send some messages to queues using the `send.sh` script.

### AUTHOR

- [dk](https://github.com/sanix-darker/rabbitsh)
