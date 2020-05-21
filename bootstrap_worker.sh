#!/bin/bash

MYIPS=$(hostname --all-ip-addresses)
MYIP=$(echo "${MYIPS}" | grep "${MYSUBNET}.[0-9]*" --only-matching)
MYHOSTNAME=$(hostname --short)
MYAPI="${MYSUBNET}.254"

$(cat /vagrant/joinworker.sh) --apiserver-advertise-address="${MYIP}"
