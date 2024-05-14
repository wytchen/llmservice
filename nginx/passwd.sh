#!/bin/bash
user=$1
htpasswd htpasswd.txt $user
# new file
#htpasswd -c htpasswd.txt $user