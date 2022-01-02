#!/bin/bash

TRAEFIK_DYNAMIC_CONFIG_FILE=dynamic/conf.yaml
echo -n "" > ${TRAEFIK_DYNAMIC_CONFIG_FILE}

while read line; do
  # If the line is empty, skip it
  [ -z "${line}" ] && continue

  IP=$(echo ${line} | awk '{print $1}')
  DOMAIN=$(echo ${line} | awk '{print $2}')
  ROUTER=router-${DOMAIN//./-}
  SERVICE=service-${IP//./-}

  # http - router
  YQ_CMD="yq e '.http.routers.${ROUTER}.entryPoints[0] = \"web\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.http.routers.${ROUTER}.rule = \"Host(\`${DOMAIN}\`)\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.http.routers.${ROUTER}.service = \"${SERVICE}\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

  # http - service
  YQ_CMD="yq e '.http.services.${SERVICE}.loadBalancer.servers[0].url = \"http://${IP}\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

  # tcp - router
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.entryPoints.[0] = \"websecure\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.rule = \"HostSNI(\`${DOMAIN}\`)\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.service = \"${SERVICE}\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.tls.passthrough = true' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

  # tcp - service
  YQ_CMD="yq e '.tcp.services.${SERVICE}.loadBalancer.servers[0].address = \"${IP}:443\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

done < hosts
