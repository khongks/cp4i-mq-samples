#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#

. ./env.vars

# delete queue manager
oc delete -n ${NAMESPACE} qmgr ${NAME}
rm ${NAME}-qmgr.yaml

# delete persistent volume claim
oc delete -n ${NAMESPACE} pvc data-${NAME}-ibm-mq-0

# delete config map
oc delete -n ${NAMESPACE} cm example-05-${NAME}-configmap
rm ${NAME}-configmap.yaml

# delete route
oc delete -n ${NAMESPACE} route example-05-${NAME}-route
rm ${NAME}chl-route.yaml

# delete secrets
oc delete -n ${NAMESPACE} secret example-05-${NAME}-secret
oc delete -n ${NAMESPACE} secret example-05-app1-secret
oc delete -n ${NAMESPACE} secret example-05-app2-secret

# delete files
rm ${NAME}.crt ${NAME}.key app1key.* app1.* app2key.* app2.* ccdt.json 
