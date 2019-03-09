#
# read and handle all needed environment variables
#

HOSTNAME=$(hostname -f)

DEBUG=${DEBUG:-0}
DEVELOPMENT_MODUS=${DEVELOPMENT_MODUS:-0}

ICINGA2_CERT_DIRECTORY="/var/lib/icinga2/certs"
ICINGA2_LIB_DIRECTORY="/var/lib/icinga2"

ICINGA2_LOGLEVEL=${ICINGA2_LOGLEVEL:-"warning"}

ICINGA2_MAJOR_VERSION=$(icinga2 --version | head -n1 | awk -F 'version: ' '{printf $2}' | awk -F \. {'print $1 "." $2'} | sed 's|r||')
[[ "${ICINGA2_MAJOR_VERSION}" = "2.7" ]] && ICINGA2_CERT_DIRECTORY="/etc/icinga2/certs"

DEMO_DATA=${DEMO_DATA:-'false'}
USER=
GROUP=
ICINGA2_MASTER=${ICINGA2_MASTER:-}
ICINGA2_PARENT=${ICINGA2_PARENT:-}

ICINGA2_HOST=${ICINGA2_HOST:-${ICINGA2_MASTER}}
TICKET_SALT=${TICKET_SALT:-$(pwgen -s 40 1)}

BASIC_AUTH_PASS=${BASIC_AUTH_PASS:-}
BASIC_AUTH_USER=${BASIC_AUTH_USER:-}

MYSQL_HOST=${MYSQL_HOST:-""}
MYSQL_PORT=${MYSQL_PORT:-"3306"}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}
MYSQL_OPTS=

RESTART_NEEDED="false"
ADD_SATELLITE_TO_MASTER=${ADD_SATELLITE_TO_MASTER:-"true"}

ICINGA2_API_USERS=${ICINGA2_API_USERS:-}

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

  #influxdb service
  INFLUXDB_HOST=${INFLUXDB_HOST:-""}
  INFLUXDB_PORT=${INFLUXDB_PORT:-8086}
  INFLUXDB_DB=${INFLUXDB_DB:-icinga2}
  INFLUXDB_USER=${INFLUXDB_USER:-}
  INFLUXDB_PASS=${INFLUXDB_PASS:-}

  # ssmtp
  ICINGA2_SSMTP_RELAY_SERVER=${ICINGA2_SSMTP_RELAY_SERVER:-}
  ICINGA2_SSMTP_REWRITE_DOMAIN=${ICINGA2_SSMTP_REWRITE_DOMAIN:-}
  ICINGA2_SSMTP_RELAY_USE_STARTTLS=${ICINGA2_SSMTP_RELAY_USE_STARTTLS:-"false"}

  ICINGA2_SSMTP_SENDER_EMAIL=${ICINGA2_SSMTP_SENDER_EMAIL:-}
  ICINGA2_SSMTP_SMTPAUTH_USER=${ICINGA2_SSMTP_SMTPAUTH_USER:-}
  ICINGA2_SSMTP_SMTPAUTH_PASS=${ICINGA2_SSMTP_SMTPAUTH_PASS:-}
  ICINGA2_SSMTP_ALIASES=${ICINGA2_SSMTP_ALIASES:-}

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

test () {
  # Convert all environment variables with names ending in __FILE into the content of
  # the file that they point at and use the name without the trailing __FILE.
  # This can be used to carry in Docker secrets.

  for VAR_NAME in $(env | grep '^GRAYLOG_[^=]\+__FILE=.\+' | sed -r 's/^(GRAYLOG_[^=]*)__FILE=.*/\1/g'); do

    VAR_NAME_FILE="${VAR_NAME}__FILE"

    if [ "${!VAR_NAME}" ]; then

      echo >&2 "ERROR: Both ${VAR_NAME} and ${VAR_NAME_FILE} are set but are exclusive"

      exit 1

    fi

    VAR_FILENAME="${!VAR_NAME_FILE}"

    echo "Getting secret ${VAR_NAME} from ${VAR_FILENAME}"

    if [ ! -r "${VAR_FILENAME}" ]; then
      echo >&2 "ERROR: ${VAR_FILENAME} does not exist or is not readable"

      exit 1
    fi

    export "${VAR_NAME}"="$(< "${VAR_FILENAME}")"

    unset "${VAR_NAME_FILE}"
  done
}

