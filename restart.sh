#!/bin/bash

killall supervisord
killall nginx
sleep 3
~/scripts/start.sh
