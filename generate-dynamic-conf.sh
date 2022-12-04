#!/usr/bin/env bash

set -e

TEMP_CONFIG_FILE="/tmp/treafik-conf-$(date +%s%N).yaml"
TRAEFIK_CONFIG_FILE=dynamic/conf.yaml
echo -n "" > ${TEMP_CONFIG_FILE}

while read line; do
  # If the line is empty, skip it
  [ -z "${line}" ] && continue

  IP=$(echo ${line} | awk '{print $1}')
  DOMAIN=$(echo ${line} | awk '{print $2}')
  ROUTER=router-${DOMAIN//./-}
  SERVICE=service-${IP//./-}

  # http and tcp - entryPoints
  YQ_CMD="yq e '.http.routers.${ROUTER}.entryPoints[0] = \"web\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.entryPoints.[0] = \"websecure\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}

  # http and tcp - rule
  if [ "${DOMAIN:0:1}" == "*" ]; then
    DOMAIN=${DOMAIN:2}
    YQ_CMD="yq e '.http.routers.${ROUTER}.rule = \"HostRegexp(\`{subdomain:.+}.${DOMAIN}\`)\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}
    YQ_CMD="yq e '.tcp.routers.${ROUTER}.rule = \"HostSNIRegexp(\`{subdomain:.+}.${DOMAIN}\`)\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}
  else
    YQ_CMD="yq e '.http.routers.${ROUTER}.rule = \"Host(\`${DOMAIN}\`)\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}
    YQ_CMD="yq e '.tcp.routers.${ROUTER}.rule = \"HostSNI(\`${DOMAIN}\`)\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}
  fi

  # http and tcp - service
  YQ_CMD="yq e '.http.routers.${ROUTER}.service = \"${SERVICE}\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.service = \"${SERVICE}\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}

  # http and tcp - url and address
  YQ_CMD="yq e '.http.services.${SERVICE}.loadBalancer.servers[0].url = \"http://${IP}\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.services.${SERVICE}.loadBalancer.servers[0].address = \"${IP}:443\"' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}

  # tcp - tls passthrough
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.tls.passthrough = true' -i ${TEMP_CONFIG_FILE}"; eval ${YQ_CMD}

done < hosts

mv ${TEMP_CONFIG_FILE} ${TRAEFIK_CONFIG_FILE}
