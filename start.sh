#!/bin/bash

rm -f $HOME/var/run/monit.id && /usr/bin/monit -c "$HOME/.monitrc"
