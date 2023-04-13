#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#

. ./env.vars

QUEUE_NAME=${1:-"Q1"}

# Find the queue manager host name

qmhostname=`oc get route -n ${NAMESPACE} ${NAME}-ibm-mq-qm -o jsonpath="{.spec.host}"`
echo $qmhostname


# Test:

ping -c 2 $qmhostname

# Create ccdt.json

cat > ccdt.json << EOF
{
    "channel":
    [
        {
            "name": "${QMGR_NAME}CHL",
            "clientConnection":
            {
                "connection":
                [
                    {
                        "host": "$qmhostname",
                        "port": 443
                    }
                ],
                "queueManager": "${QMGR_NAME}"
            },
            "transmissionSecurity":
            {
              "cipherSpecification": "ANY_TLS12_OR_HIGHER"
            },
            "type": "clientConnection"
        }
   ]
}
EOF

# Set environment variables for the client

export MQCCDTURL=ccdt.json
export MQSSLKEYR=app2key
# check:
echo MQCCDTURL=$MQCCDTURL
ls -l $MQCCDTURL
echo MQSSLKEYR=$MQSSLKEYR
ls -l $MQSSLKEYR.*

# Get messages from the queue

amqsbcgc ${QUEUE_NAME} ${QMGR_NAME}
