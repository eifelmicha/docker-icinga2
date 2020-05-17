#
# read and handle all needed environment variables
#

HOSTNAMEFQDN=$(hostname -f)
HOSTNAME=${ICINGA2_MASTER:-${HOSTNAMEFQDN}}
HOSTNAME_DNS=$(dig $HOSTNAME +short)
HOSTNAME_IP=${HOSTNAME_IP:-${HOSTNAME_DNS}}

DEBUG=${DEBUG:-0}
DEVELOPMENT_MODUS=${DEVELOPMENT_MODUS:-0}

ICINGA2_CERT_DIRECTORY="/var/lib/icinga2/certs"
ICINGA2_LIB_DIRECTORY="/var/lib/icinga2"

ICINGA2_LOGLEVEL=${ICINGA2_LOGLEVEL:-"warning"}
MAINLOG=${ICINGA2_MAINLOG:-'false'}

ICINGA2_MAJOR_VERSION=$(icinga2 --version | head -n1 | awk -F 'version: ' '{printf $2}' | awk -F \. {'print $1 "." $2'} | sed 's|r||')
[[ "${ICINGA2_MAJOR_VERSION}" = "2.7" ]] && ICINGA2_CERT_DIRECTORY="/etc/icinga2/certs"

DEMO_DATA=${DEMO_DATA:-'false'}
USER=
GROUP=
ICINGA2_MASTER=${ICINGA2_MASTER:-}
ICINGA2_PARENT=${ICINGA2_PARENT:-}

MULTI_MASTER=${MULTI_MASTER:=false}
HA_MASTER2_PORT=${HA_MASTER2_PORT:=5665}
HA_CONFIG_MASTER=${HA_CONFIG_MASTER:=false}
HA_MASTER1=${HA_MASTER1:-}
HA_MASTER1_DNS=$(dig $HA_MASTER1 +short)
HA_MASTER1_IP=${HA_MASTER1_IP:-${HA_MASTER1_DNS}}
HA_MASTER2=${HA_MASTER2:-}
HA_MASTER2_DNS=$(dig $HA_MASTER2 +short)
HA_MASTER2_IP=${HA_MASTER2_IP:-${HA_MASTER2_DNS}}

AGENT_HEALTH_CHECK_SEC=${AGENT_HEALTH_CHECK_SEC:-20s}
AGENT_HEALTH_RETRY_SEC=${AGENT_HEALTH_RETRY_SEC:-5s}

CPU_COUNT=$(grep -c processor /proc/cpuinfo)
CPU_CLOAD1=$(echo "${CPU_COUNT}*3" |bc)
CPU_CLOAD5=$(echo "${CPU_COUNT}*2.5" |bc)
CPU_CLOAD15=$(echo "${CPU_COUNT}*2" |bc)
CPU_WLOAD1=$(echo "${CPU_COUNT}*2" |bc)
CPU_WLOAD5=$(echo "${CPU_COUNT}*1.5" |bc)
CPU_WLOAD15=$(echo "${CPU_COUNT}*1" |bc)

ICINGA2_HOST=${ICINGA2_HOST:-${ICINGA2_MASTER}}
TICKET_SALT=${TICKET_SALT:-$(pwgen -s 40 1)}

BASIC_AUTH_PASS=${BASIC_AUTH_PASS:-}
BASIC_AUTH_USER=${BASIC_AUTH_USER:-}

MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
MYSQL_IDO_HA=${MYSQL_IDO_HA:-${MULTI_MASTER}}
MYSQL_IDOC_DHA=${MYSQL_IDOC_DHA:-48h}
MYSQL_IDOC_CNA=${MYSQL_IDOC_CNA:-31d}
MYSQL_IDOC_ACK=${MYSQL_IDOC_ACK:-0}
MYSQL_IDOC_EVH=${MYSQL_IDOC_EVH:-0}
MYSQL_IDOC_FHA=${MYSQL_IDOC_FHA:-0}
MYSQL_IDOC_HCA=${MYSQL_IDOC_HCA:-0}
MYSQL_IDOC_NA=${MYSQL_IDOC_NA:-0}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}
MYSQL_OPTS=
IDO_USER=${IDO_USER:-"icinga2"}

RESTART_NEEDED="false"
ADD_SATELLITE_TO_MASTER=${ADD_SATELLITE_TO_MASTER:-"true"}

ICINGA2_API_USERS=${ICINGA2_API_USERS:-}
ICINGA2_API_PROM_USER=${ICINGA2_API_PROM_USER:-}
ICINGA2_API_HACHECK_USER=${ICINGA2_API_HACHECK_USER:-}

if [[ "${ICINGA2_TYPE}" = "Master" ]]
then
  IDO_DATABASE_NAME=${IDO_DATABASE_NAME:-"icinga2core"}
  if [[ -z ${IDO_PASSWORD} ]]
  then
    IDO_PASSWORD=$(pwgen -s 15 1)

    log_warn "NO IDO PASSWORD HAS BEEN SET!"
    log_warn "DATABASE CONNECTIONS ARE NOT RESTART SECURE!"
    log_warn "DYNAMICALLY GENERATED PASSWORD: '${IDO_PASSWORD}' (ONLY VALID FOR THIS SESSION)"
  fi

  # graphite service
  CARBON_HOST=${CARBON_HOST:-""}
  CARBON_PORT=${CARBON_PORT:-2003}
  CARBON_TRESHOLDS=${CARBON_TRESHOLDS:-"false"}
  CARBON_METADATA=${CARBON_METADATA:-"false"}

  #influxdb service
  INFLUXDB_HOST=${INFLUXDB_HOST:-""}
  INFLUXDB_PORT=${INFLUXDB_PORT:-8086}
  INFLUXDB_DB=${INFLUXDB_DB:-icinga2}
  INFLUXDB_USER=${INFLUXDB_USER:-}
  INFLUXDB_PASS=${INFLUXDB_PASS:-}
  INFLUXDB_SSL=${INFLUXDB_SSL:-"false"}
  INFLUXDB_SSLCACERT=${INFLUXDB_SSLCACERT:-}
  INFLUXDB_SSLCERT=${INFLUXDB_SSLCERT:-}
  INFLUXDB_SSLKEY=${INFLUXDB_SSLKEY:-}
  INFLUXDB_TRESHOLDS=${INFLUXDB_TRESHOLDS:-"false"}
  INFLUXDB_METADATA=${INFLUXDB_METADATA:-"false"}

  # msmtp
  ICINGA2_MSMTP_RELAY_SERVER=${ICINGA2_MSMTP_RELAY_SERVER:-}
  ICINGA2_MSMTP_REWRITE_DOMAIN=${ICINGA2_MSMTP_REWRITE_DOMAIN:-}
  ICINGA2_MSMTP_RELAY_USE_STARTTLS=${ICINGA2_MSMTP_RELAY_USE_STARTTLS:-"false"}

  ICINGA2_MSMTP_SENDER_EMAIL=${ICINGA2_MSMTP_SENDER_EMAIL:-}
  ICINGA2_MSMTP_SMTPAUTH_USER=${ICINGA2_MSMTP_SMTPAUTH_USER:-}
  ICINGA2_MSMTP_SMTPAUTH_PASS=${ICINGA2_MSMTP_SMTPAUTH_PASS:-}
  ICINGA2_MSMTP_ALIASES=${ICINGA2_MSMTP_ALIASES:-}
  ICINGA2_MSMTP_RECV_ROOT=${ICINGA2_MSMTP_RECV_ROOT:-}
  ICINGA2_MSMTP_ACC_NAME=${ICINGA2_MSMTP_ACC_NAME:-}

  ADD_SATELLITE_TO_MASTER="false"
fi


# cert-service
USE_CERT_SERVICE=${USE_CERT_SERVICE:-false}
if [[ "${USE_CERT_SERVICE}" = "true" ]]
then
  export CERT_SERVICE_BA_USER=${CERT_SERVICE_BA_USER:-"admin"}
  export CERT_SERVICE_BA_PASSWORD=${CERT_SERVICE_BA_PASSWORD:-"admin"}
  export CERT_SERVICE_API_USER=${CERT_SERVICE_API_USER:-""}
  export CERT_SERVICE_API_PASSWORD=${CERT_SERVICE_API_PASSWORD:-""}
  export CERT_SERVICE_SERVER=${CERT_SERVICE_SERVER:-"localhost"}
  export CERT_SERVICE_PORT=${CERT_SERVICE_PORT:-"80"}
  export CERT_SERVICE_PATH=${CERT_SERVICE_PATH:-"/"}
fi

[[ ${CERT_SERVICE_PORT} = *443 ]] && protocol=https || protocol=http
export CERT_SERVICE_PROTOCOL=${protocol}

export PKI_CMD="icinga2 pki"
export PKI_KEY_FILE="${ICINGA2_CERT_DIRECTORY}/${HOSTNAME}.key"
export PKI_CSR_FILE="${ICINGA2_CERT_DIRECTORY}/${HOSTNAME}.csr"
export PKI_CRT_FILE="${ICINGA2_CERT_DIRECTORY}/${HOSTNAME}.crt"


NEEDED_SERVICES="database"

# -----------------------------------------------------------------------------------

# if [[ ! -z "${CONFIG_BACKEND}" ]] || [[ "${CONFIG_BACKEND}" = "consul" ]]
# then
#   . /init/consul.sh
#   wait_for_consul
# fi
#
# if [[ ! -z "${CONSUL}" ]] || [[ "${CONFIG_BACKEND}" = "consul" ]]
# then
#   DATABASE_PASSWORD=$(get_consul_var "database/root/password")
#
#   echo "database password: '${DATABASE_PASSWORD}'"
# fi

export ICINGA2_MAJOR_VERSION
export ICINGA2_CERT_DIRECTORY
export ICINGA2_LIB_DIRECTORY
export HOSTNAME

# -----------------------------------------------------------------------------------