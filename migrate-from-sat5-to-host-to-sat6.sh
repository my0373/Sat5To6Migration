#!/usr/bin/bash

################################################################################
## RHN Satellite 5 -> 6 host migration script.
##
## Author:      Matthew York (myork@redhat.com)
## Version:     1.0  - (23/04/2015) - initial release
##
## Description: This script will install attempt to install the
##              "subscription-manager" package on a RHEL6 system.
##
##              It will proceed to download the latest katello package
##              from the new satellite server, with the satellite 6 hostname
##              defined in variable SAT6_HOSTNAME.
##
##              We then remove the systemid '/etc/sysconfig/rhn/systemid' file,
##              which causes the host to become unaware it is registered with
##              satellite 5.
## 
##              We then attampt to register to the new satellite using a
##              pre-defined activation key on the satellite, this key is
##              specified in the DEFAULT_ACTIVATION_KEY variable.
##
## Exit status codes: 0 - Success.
##                    1 - Unable to install the subscription manager package from yum.
##                    2 - Unable to install the rpm from the new satellite.
##                    3 - Unable to delete the /etc/sysconfig/rhn/systemid file.
##                    4 - Unable to find the file/etc/sysconfig/rhn/systemid to remove.
##                    5 - Unable to register with the new satellite.
##
## Script Constants: DEFAULT_ACTIVATION_KEY - The default activation key to use
##                   when registering a system with satellite 6.
##
##                   SAT6_HOSTNAME - The resolvable hostname of the satellite6
##                                   server.
##
################################################################################

################################################################################
## Constants

## The default activation key name.
DEFAULT_ACTIVATION_KEY=“RHEL6_DEV1”

## The hostname of the satellite6 server
SAT6_HOSTNAME="acopua07"


################################################################################
## Install the subscription-manager package to the host.

$(yum install subscription-manager)
if [ $? -gt 0 ]
then
	echo "FATAL: Unable to install subscription manager"
	exit 1
fi

## Install the rpm from the new satellite.
$(rpm -Uvh http://${SAT6_HOSTNAME}/pub/katello-ca-consumer-latest.noarch.rpm)
if [ $? -gt 0 ]
then
	echo "FATAL: Unable to install the RPM for the new satellite."
	exit 2
fi

################################################################################
## Remove the systemid file, this means the system will no longer know about the
## satellite 5 server.

if [ -e /etc/sysconfig/rhn/systemid ]
then
	$(rm /etc/sysconfig/rhn/systemid)
	if [ $? -gt 0 ]
		echo “FATAL: Deletion of the file /etc/sysconfig/rhn/systemid failed.”
		exit 3
	fi
else
	echo “FATAL: Unable to find the file /etc/sysconfig/rhn/systemid”
	exit 4
fi

################################################################################
## Register the host with the default activation key specified.

$(subscription-manager register —org="Default_Organization" —activationkey=${DEFAULT_ACTIVATION_KEY})
if [ $? -gt 0 ]
then
	echo "FATAL: Unable to subscribe to the new satellite ${SAT6_HOSTNAME}"
	exit 5
fi

echo "Successfully Registered $(hostname -f) as a content host on the satellite 6 server ${SAT6_HOSTNAME}"

################################################################################
## Exit with success.
exit 0
