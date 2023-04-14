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

# delete config map
oc delete -n ${NAMESPACE} cm example-13-${NAME}-configmap
rm ${NAME}-configmap.yaml

# delete route
oc delete -n ${NAMESPACE} route example-13-${NAME}-route
rm ${NAME}chl-route.yaml

# delete secret
oc delete -n ${NAMESPACE} secret example-13-${NAME}-secret

# delete files
rm ${NAME}.crt ${NAME}.key app1key.* ccdt.json
