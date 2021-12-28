#!/bin/bash

TRAEFIK_DYNAMIC_CONFIG_FILE=dynamic-conf.yaml
rm ${TRAEFIK_DYNAMIC_CONFIG_FILE}
touch ${TRAEFIK_DYNAMIC_CONFIG_FILE}

while IFS= read -r line; do
  IP=$(echo ${line} | awk '{print $1}')
  DOMAIN=$(echo ${line} | awk '{print $2}')
  ROUTER=router-${IP//./-}
  SERVICE=service-${IP//./-}

  #  http - router
  YQ_CMD="yq e '.http.routers.${ROUTER}.entryPoints[0] = \"web\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.http.routers.${ROUTER}.rule = \"Host(\`${DOMAIN}\`)\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.http.routers.${ROUTER}.service = \"${SERVICE}\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

  # http - service
  YQ_CMD="yq e '.http.services.${SERVICE}.loadBalancer.servers[0].url = \"http://${IP}\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

  # tcp - router
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.entryPoints.[0] = \"websecure\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.rule = \"HostSNI(\`${DOMAIN}\`)\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}
  YQ_CMD="yq e '.tcp.routers.${ROUTER}.service = \"${SERVICE}\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

  # tcp - service
  YQ_CMD="yq e '.tcp.services.${SERVICE}.loadBalancer.servers[0].address = \"${IP}:443\"' -i ${TRAEFIK_DYNAMIC_CONFIG_FILE}"; eval ${YQ_CMD}

done < hosts
