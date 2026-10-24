#!/usr/bin/env bash
# ssh into the emulated iOS (root / alpine) through Aleph's tcp-tunnel (host port 2222)
exec sshpass -p alpine ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=60 root@127.0.0.1 "$@"
