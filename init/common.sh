#

version_string() {
  echo "${1}" | sed 's|r||' | awk -F '-' '{print $1}'
}

# compare the version of the Icinga2 Master with the Satellite
#
version_of_icinga_master() {

  [[ "${ICINGA2_TYPE}" = "Master" ]] && return

  log_info "wait for our master '${ICINGA2_MASTER}' to come up"

  . /init/wait_for/icinga_master.sh

  # get the icinga2 version of our master
  #
  # log_info "compare our version with the master '${ICINGA2_MASTER}'"
  code=$(curl \
    --user ${CERT_SERVICE_API_USER}:${CERT_SERVICE_API_PASSWORD} \
    --silent \
    --insecure \
    --header 'Accept: application/json' \
    https://${ICINGA2_MASTER}:5665/v1/status/IcingaApplication )

  if [[ $? -eq 0 ]]
  then
    version=$(echo "${code}" | jq --raw-output '.results[].status.icingaapplication.app.version' 2> /dev/null)

    version=$(version_string ${version})

    vercomp ${version} ${ICINGA2_VERSION}
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac

    if [[ "${op}" != "=" ]]
    then
      if [[ "${op}" = "<" ]]
      then
        log_warn "The version of the master is smaller than that of the satellite!"
      elif [[ "${op}" = ">" ]]
      then
        log_warn "The version of the master is higher than that of the satellite!"
      fi

      log_warn "The version of the master differs from that of the satellite! (master: ${version} / satellite: ${BUILD_VERSION})"
      log_warn "Which can lead to problems!"
    else
      log_info "The versions between Master and Satellite are identical"
    fi
  fi
}


stdbool() {

  if [ -z "${1}" ]
  then
    echo "n"
  else
    echo ${1:0:1} | tr '[:upper:]' '[:lower:]'
  fi
}


# prepare the system and icinga to run in the docker environment
#
prepare() {

  for p in HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy
  do
    unset "${p}"
  done

  [[ -d ${ICINGA2_LIB_DIRECTORY}/backup ]] || mkdir -p ${ICINGA2_LIB_DIRECTORY}/backup
  [[ -d ${ICINGA2_CERT_DIRECTORY} ]] || mkdir -p ${ICINGA2_CERT_DIRECTORY}

  # detect username
  #
  for u in nagios icinga
  do
    if [[ "$(getent passwd ${u})" ]]
    then
      USER="${u}"
      break
    fi
  done

  # detect groupname
  #
  for g in nagios icinga
  do
    if [[ "$(getent group ${g})" ]]
    then
      GROUP="${g}"
      break
    fi
  done

  # read (generated) icinga2.sysconfig and import environment
  # otherwise define variables
  #
  if [[ -f /etc/icinga2/icinga2.sysconfig ]]
  then
    ls -l /etc/icinga2/icinga2.sysconfig
    cat /etc/icinga2/icinga2.sysconfig

    . /etc/icinga2/icinga2.sysconfig

    ICINGA2_RUN_DIRECTORY=${ICINGA2_RUN_DIR}
    ICINGA2_LOG_DIRECTORY=${ICINGA2_LOG}
  fi

  # no entries, also use the icinga2 way
  #
  [[ -z ${ICINGA2_RUN_DIRECTORY} ]] && ICINGA2_RUN_DIRECTORY=$(/usr/sbin/icinga2 variable get RunDir)
  [[ -z ${ICINGA2_RUN_DIRECTORY} ]] && ICINGA2_RUN_DIRECTORY="/var/run"
  [[ -z ${ICINGA2_LOG_DIRECTORY} ]] && ICINGA2_LOG_DIRECTORY="/var/log/icinga2/icinga2.log"

  if [[ "${MULTI_MASTER}" = true && "${HA_CONFIG_MASTER}" = true ]]
  then
    if [[ -f /etc/icinga2/zones.conf ]] && [[ -f /etc/icinga2/zones.conf-master1 ]]
    then
      rm /etc/icinga2/zones.conf  && \
      cp -n ${cp_opts} /etc/icinga2/zones.conf-master1 /etc/icinga2/zones.conf
    fi
  fi

  if [[ "${MULTI_MASTER}" = true && "${HA_CONFIG_MASTER}" = false ]]
  then
    if [[ -f /etc/icinga2/zones.conf ]] && [[ -f /etc/icinga2/zones.conf-master2 ]]
    then
      rm /etc/icinga2/zones.conf  && \
      cp -n ${cp_opts} /etc/icinga2/zones.conf-master2 /etc/icinga2/zones.conf && \
      rm -rf /etc/icinga2/zones.d
    fi
  fi

  if [[ "${MULTI_MASTER}" = false && "${HA_CONFIG_MASTER}" = false ]]
  then
    if [[ -f /etc/icinga2/zones.conf ]] && [[ -f /etc/icinga2/zones.conf-docker ]]
    then
      rm /etc/icinga2/zones.conf  && \
      cp -n ${cp_opts} /etc/icinga2/zones.conf-docker /etc/icinga2/zones.conf
    fi
  fi

  if [[ "${MULTI_MASTER}" = true ]]
  then
    log_info "Multi Node Preparations"
    [[ -f /etc/icinga2/conf.d/hosts.conf ]] && rm /etc/icinga2/conf.d/hosts.conf
    [[ -f /etc/icinga2/conf.d/services.conf ]] && rm /etc/icinga2/conf.d/services.conf
    [[ -f /etc/icinga2/master.d/services.conf.docker ]] && mv /etc/icinga2/master.d/services.conf.docker /etc/icinga2/master.d/docker-services.conf
  fi

  if [[ "${MULTI_MASTER}" = false ]]
  then
    log_info "Single Node Preparations"
    [[ -f /etc/icinga2/master.d/hosts.conf ]] && sed -i -e "s|^.*\ vars.os\ \=\ .*|  vars.os = \"Docker\"|g" /etc/icinga2/master.d/hosts.conf
    [[ -f /etc/icinga2/conf.d/hosts.conf ]] && rm /etc/icinga2/conf.d/hosts.conf
    [[ -f /etc/icinga2/conf.d/services.conf ]] && rm /etc/icinga2/conf.d/services.conf
    [[ -f /etc/icinga2/master.d/services.conf.docker ]] && mv /etc/icinga2/master.d/services.conf.docker /etc/icinga2/master.d/docker-services.conf
  fi

  # set NodeName (important for the cert feature!)
  #
  log_info "setting NodeName, ZoneName and TicketSalt"

  sed -i \
    -e "s|^.*\ NodeName\ \=\ .*|const\ NodeName\ \=\ \"${HOSTNAME}\"|g" \
    -e "s|^.*\ ZoneName\ \=\ .*|const\ ZoneName\ \=\ \"${HOSTNAME}\"|g" \
    -e "s|^.*\ TicketSalt\ \=\ .*|const\ TicketSalt\ \=\ \"${TICKET_SALT}\"|g" \
    /etc/icinga2/constants.conf

  log_info "setting up master zone configuration"

  if [[ "${MULTI_MASTER}" = true && "${HA_CONFIG_MASTER}" = true ]]
  then
    # replace HA_MASTER_* in ha-cluster-hosts.conf
    sed -i \
      -e "s|\<HA_MASTER1\>|${HA_MASTER1}|g" \
      -e "s|\<HA_MASTER2\>|${HA_MASTER2}|g" \
      -e "s|\<HA_MASTER2_PORT\>|${HA_MASTER2_PORT}|g" \
      -e "s|\<HA_MASTER1_IP\>|${HA_MASTER1_IP}|g" \
      -e "s|\<HA_MASTER2_IP\>|${HA_MASTER2_IP}|g" \
      /etc/icinga2/master.d/ha-cluster-hosts.conf
  fi

  if [[ "${MULTI_MASTER}" = true ]]
  then
    # replace HA_MASTER_* in zones.conf
    sed -i \
      -e "s|\<HA_MASTER1\>|${HA_MASTER1}|g" \
      -e "s|\<HA_MASTER2\>|${HA_MASTER2}|g" \
      -e "s|\<HA_MASTER2_PORT\>|${HA_MASTER2_PORT}|g" \
      -e "s|\<HA_MASTER1_IP\>|${HA_MASTER1_IP}|g" \
      -e "s|\<HA_MASTER2_IP\>|${HA_MASTER2_IP}|g" \
      /etc/icinga2/zones.conf
  fi

  if [[ "${MULTI_MASTER}" = false ]]
  then
    # replace HOSTNAME_* in standalone-host.conf
    sed -i \
      -e "s|\<HOSTNAME\>|${HOSTNAME}|g" \
      -e "s|\<HOSTNAME_IP\>|${HOSTNAME_IP}|g" \
      /etc/icinga2/master.d/standalone-host.conf
  fi

  if [[ "${MULTI_MASTER}" = false ]]
  then
    # replace HOSTNAME_* in standalone-host.conf
    sed -i \
      -e "s|\<HOSTNAME\>|${HOSTNAME}|g" \
      -e "s|\<HOSTNAME_IP\>|${HOSTNAME_IP}|g" \
      /etc/icinga2/zones.conf
  fi

  # create directory for the logfile and change rights
  #
  log_info "creating log directory and set permissions"

  LOGDIR=$(dirname ${ICINGA2_LOG_DIRECTORY})

  [[ -d ${LOGDIR} ]] || mkdir -p ${LOGDIR}

  chown  ${USER}:${GROUP} ${LOGDIR}
  chmod  ug+wx ${LOGDIR}
  find ${LOGDIR} -type f -exec chmod ug+rw {} \;

  # icinga2 main log
  #
  if [[ "${ICINGA2_MAINLOG}" = true ]]
  then
    enable_icinga_feature mainlog
  else
    disable_icinga_feature mainlog
  fi

  cat << EOF > /etc/icinga2/features-available/mainlog.conf
#  https://www.icinga.com/docs/icinga2/latest/doc/09-object-types/#objecttype-filelogger
object FileLogger "main-log" {
  severity = "${ICINGA2_LOGLEVEL}"
  path = LocalStateDir + "/log/icinga2/icinga2.log"
}
EOF

}


fix_sys_caps() {

  log_info "setting cap_net_raw+ep for some check scripts"

  local plugindir=/usr/lib/nagios/plugins

  # If we have setcap is installed, try setting cap_net_raw+ep,
  # which allows us to make our binaries working without the
  # setuid bit
  if command -v setcap > /dev/null
  then
    if setcap "cap_net_raw+ep" /bin/ping "cap_net_raw+ep" ${plugindir}/check_icmp "cap_net_bind_service=+ep cap_net_raw=+ep" ${plugindir}/check_dhcp
    then
      log_info "setcap for ping, check_icmp and check_dhcp worked!"
    else
      log_error "setcap for ping, check_icmp and check_dhcp failed, set uid bit."

      chmod +s \
        /bin/ping \
        ${plugindir}/check_icmp \
        ${plugindir}/check_dhcp
    fi
  else
    log_warn "setcap is not installed, set uid bit"

    chmod +s \
      /bin/ping \
      ${plugindir}/check_icmp \
      ${plugindir}/check_dhcp
  fi
}


# enable Icinga2 Feature
#
enable_icinga_feature() {

  local feature="${1}"

  if [[ $(icinga2 feature list | grep Enabled | grep -c ${feature}) -eq 0 ]]
  then
    log_info "feature ${feature} enabled"
    icinga2 feature enable ${feature} > /dev/null
  fi
}

# disable Icinga2 Feature
#
disable_icinga_feature() {

  local feature="${1}"

  if [[ $(icinga2 feature list | grep Enabled | grep -c ${feature}) -eq 1 ]]
  then
    log_info "feature ${feature} disabled"
    icinga2 feature disable ${feature} > /dev/null
  fi
}

# correct rights of files and directories
#
correct_rights() {

  chmod 1777 /tmp

  if ( [[ -z ${USER} ]] || [[ -z ${GROUP} ]] )
  then
    log_error "no nagios or icinga user/group found!"
  else
    [[ -e /var/lib/icinga2/api/log/current ]] && rm -rf /var/lib/icinga2/api/log/current

    chown -R ${USER}:root     /etc/icinga2
    chown -R ${USER}:${GROUP} /var/lib/icinga2
    chown -R ${USER}:${GROUP} ${ICINGA2_RUN_DIRECTORY}/icinga2
    chown -R ${USER}:${GROUP} ${ICINGA2_CERT_DIRECTORY}
  fi
}

random() {
  echo $(shuf -i 5-30 -n 1)
}

curl_opts() {

  opts=""
  opts="${opts} --user ${CERT_SERVICE_API_USER}:${CERT_SERVICE_API_PASSWORD}"
  opts="${opts} --silent"
  opts="${opts} --location"
  opts="${opts} --insecure"

  echo ${opts}
}


validate_certservice_environment() {

  CERT_SERVICE_BA_USER=${CERT_SERVICE_BA_USER:-"admin"}
  CERT_SERVICE_BA_PASSWORD=${CERT_SERVICE_BA_PASSWORD:-"admin"}
  CERT_SERVICE_API_USER=${CERT_SERVICE_API_USER:-""}
  CERT_SERVICE_API_PASSWORD=${CERT_SERVICE_API_PASSWORD:-""}
  CERT_SERVICE_SERVER=${CERT_SERVICE_SERVER:-"localhost"}
  CERT_SERVICE_PORT=${CERT_SERVICE_PORT:-"80"}
  CERT_SERVICE_PATH=${CERT_SERVICE_PATH:-"/"}
  USE_CERT_SERVICE=false

  # use the new Cert Service to create and get a valide certificat for distributed icinga services
  #
  if (
    [[ ! -z ${CERT_SERVICE_BA_USER} ]] &&
    [[ ! -z ${CERT_SERVICE_BA_PASSWORD} ]] &&
    [[ ! -z ${CERT_SERVICE_API_USER} ]] &&
    [[ ! -z ${CERT_SERVICE_API_PASSWORD} ]]
  )
  then
    USE_CERT_SERVICE=true

    export CERT_SERVICE_BA_USER
    export CERT_SERVICE_BA_PASSWORD
    export CERT_SERVICE_API_USER
    export CERT_SERVICE_API_PASSWORD
    export CERT_SERVICE_SERVER
    export CERT_SERVICE_PORT
    export CERT_SERVICE_PATH
    export USE_CERT_SERVICE
  fi
}


validate_icinga_config() {

  log_info "validate our configuration"
  # test the configuration
  #
  /usr/sbin/icinga2 \
    daemon \
    ${ICINGA2_PARAMS} \
    --validate

  # validation are not successful
  #
  if [[ $? -gt 0 ]]
  then
    log_error "the validation of our configuration was not successful."

    # validate again for debugging
    #
    /usr/sbin/icinga2 \
      daemon \
      --log-level debug \
      --validate

#    log_error "remove all files under /var/lib/icinga add restart"
#    cat /var/log/icinga2/crash/*
#    cat /var/log/icinga2/*
#
#    rm -rf /var/lib/icinga2/*
#    exit 1
  fi
}
