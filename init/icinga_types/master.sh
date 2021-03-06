
# restore a old zone file for automatic generated satellites
#
restore_backup() {

  cp_opts="--archive --force --recursive"
  [[ "${DEBUG}" = "true" ]] && cp_opts="${cp_opts} --verbose"

  # backwards compatibility
  # in an older version, we create all zone config files in an seperate directory
  #
  [[ -d ${ICINGA2_LIB_DIRECTORY}/backup/automatic-zones.d ]] && mv ${ICINGA2_LIB_DIRECTORY}/backup/automatic-zones.d ${ICINGA2_LIB_DIRECTORY}/backup/zones.d

  if [[ -d ${ICINGA2_LIB_DIRECTORY}/backup ]]
  then
    log_info "restore backup"

    if [[ "${DEBUG}" = "true" ]]; then
      if [[ -e ${ICINGA2_LIB_DIRECTORY}/backup/zones.conf ]]
      then
        grep -nrB2 "object Endpoint" ${ICINGA2_LIB_DIRECTORY}/backup/zones.conf
      fi

      if [[ -e ${ICINGA2_LIB_DIRECTORY}/backup/zones.d ]]
      then
        grep -nrB2 "object Endpoint" ${ICINGA2_LIB_DIRECTORY}/backup/zones.d/*
      fi
    fi

    if [[ -f ${ICINGA2_LIB_DIRECTORY}/backup/zones.conf ]]
    then
      [[ "${DEBUG}" = "true" ]] && log_debug "  - zones.conf"
      cp ${cp_opts} ${ICINGA2_LIB_DIRECTORY}/backup/zones.conf /etc/icinga2/zones.conf
    fi

    if [[ -d ${ICINGA2_LIB_DIRECTORY}/backup/zones.d ]]
    then
      cp ${cp_opts} ${ICINGA2_LIB_DIRECTORY}/backup/zones.d/* /etc/icinga2/zones.d/
    fi

    if [[ -f ${ICINGA2_LIB_DIRECTORY}/backup/conf.d/api-users.conf ]]
    then
      [[ "${DEBUG}" = "true" ]] && log_debug "  - api-users.conf"
      cp ${cp_opts} ${ICINGA2_LIB_DIRECTORY}/backup/conf.d/api-users.conf /etc/icinga2/conf.d/api-users.conf
    fi

  fi
}

# copy master specific configurations
#
copy_master_specific_configurations() {

  if [[ -d /etc/icinga2/zones.d/global-templates ]]; then
    [[ "${DEBUG}" = "true" ]] && log_debug "copy global-templates"

    if [[ -f /etc/icinga2/master.d/templates_services.conf ]]; then
      [[ "${DEBUG}" = "true" ]] && log_debug "  - templates_services.conf"
      cp ${cp_opts} /etc/icinga2/master.d/templates_services.conf /etc/icinga2/zones.d/global-templates/
    fi

    if [[ ("${MULTI_MASTER}" = true && "${HA_CONFIG_MASTER}" = true) ]]; then
      [[ "${DEBUG}" = "true" ]] && log_debug "  - moving master.d files to global-templates for multi setup"
      for file in checkcommands_linux_memory.conf docker-services.conf functions.conf \
      groups.conf matrix-commands.conf templates_services.conf
      do
        [[ -f /etc/icinga2/master.d/${file} ]] && mv /etc/icinga2/master.d/${file} /etc/icinga2/zones.d/global-templates/${file}
      done
    fi

    if [[ ("${MULTI_MASTER}" = false && "${HA_CONFIG_MASTER}" = false) ]]; then
      [[ "${DEBUG}" = "true" ]] && log_debug "  - moving master.d files to global-templatesfor single setup"
      for file in checkcommands_linux_memory.conf docker-services.conf functions.conf \
      groups.conf matrix-commands.conf templates_services.conf
      do
        [[ -f /etc/icinga2/master.d/${file} ]] && mv /etc/icinga2/master.d/${file} /etc/icinga2/zones.d/global-templates/${file}
      done
    fi

    if [[ -f /etc/icinga2/satellite.d/services.conf ]]; then
      [[ "${DEBUG}" = "true" ]] && log_debug "  - satellite services.conf"
      [[ -d /etc/icinga2/zones.d/satellite ]] || mkdir -p /etc/icinga2/zones.d/satellite
      cp ${cp_opts} /etc/icinga2/satellite.d/services.conf /etc/icinga2/zones.d/satellite
    fi
  fi

  if [[ -f /etc/icinga2/master.d/master-service-apply.conf ]]; then
    sed -i \
      -e "s|\<AGENT_HEALTH_CHECK_SEC\>|${AGENT_HEALTH_CHECK_SEC}|g" \
      -e "s|\<AGENT_HEALTH_RETRY_SEC\>|${AGENT_HEALTH_RETRY_SEC}|g" \
      -e "s|\<CPU_WLOAD1\>|${CPU_WLOAD1}|g" \
      -e "s|\<CPU_WLOAD5\>|${CPU_WLOAD5}|g" \
      -e "s|\<CPU_WLOAD15\>|${CPU_WLOAD15}|g" \
      -e "s|\<CPU_CLOAD1\>|${CPU_CLOAD1}|g" \
      -e "s|\<CPU_CLOAD5\>|${CPU_CLOAD5}|g" \
      -e "s|\<CPU_CLOAD15\>|${CPU_CLOAD15}|g" \
      /etc/icinga2/master.d/master-service-apply.conf
  fi

  if [[ ("${MULTI_MASTER}" = true && "${HA_CONFIG_MASTER}" = true) ]] ; then
    [[ "${DEBUG}" = "true" ]] && log_debug "  - creating master zone directory for multi master"
    [[ -d /etc/icinga2/zones.d/master/ ]] || mkdir -p /etc/icinga2/zones.d/master/
    for file in dependencies.conf ha-cluster-hosts.conf master-service-apply.conf
    do
      [[ -f /etc/icinga2/master.d/${file} ]] && mv /etc/icinga2/master.d/${file} /etc/icinga2/zones.d/master/${file}
    done
  fi

  if [[ "${MULTI_MASTER}" = false ]]; then
    [[ "${DEBUG}" = "true" ]] && log_debug "  - creating master zone directory for single master"
    [[ -d /etc/icinga2/zones.d/master/ ]] || mkdir -p /etc/icinga2/zones.d/master/
    for file in dependencies.conf standalone-host.conf master-service-apply.conf
    do
      [[ -f /etc/icinga2/master.d/${file} ]] && mv /etc/icinga2/master.d/${file} /etc/icinga2/zones.d/master/${file}
    done
  fi
}

# configure a icinga2 master instance
#
configure_icinga2_master() {

  enable_icinga_feature api

  create_ca

  restore_backup

  copy_master_specific_configurations
}

configure_icinga2_master
