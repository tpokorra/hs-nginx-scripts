#!/bin/bash

killall nginx
killall monit
sleep 3
~/scripts/start.sh
