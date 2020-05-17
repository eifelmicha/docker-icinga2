
# configure the InfluxDB Support
#

if ( [[ -z ${INFLUXDB_HOST} ]] || [[ -z ${INFLUXDB_PORT} ]] )
then
  log_info "no settings for influxdb feature found"
  unset INFLUXDB_HOST
  unset INFLUXDB_PORT
  return
fi

configure_influxdb() {

  enable_icinga_feature influxdb

  config_file="/etc/icinga2/features-enabled/influxdb.conf"

  # create (overwrite existing) configuration
  #
  if [[ -e "${config_file}" ]]
  then
    cat > "${config_file}" <<-EOF

object InfluxdbWriter "influxdb" {
  host = "${INFLUXDB_HOST}"
  port = ${INFLUXDB_PORT}
  database = "${INFLUXDB_DB}"
  username = "${INFLUXDB_USER}"
  password = "${INFLUXDB_PASS}"
  ssl_enable= ${INFLUXDB_SSL}
  ssl_ca_cert = "${INFLUXDB_SSLCACERT}"
  ssl_cert = "${INFLUXDB_SSLCERT}"
  ssl_key = "${INFLUXDB_SSLKEY}"
  enable_send_thresholds = ${INFLUXDB_TRESHOLDS}
  enable_send_metadata = ${INFLUXDB_METADATA}
  enable_ha = ${MULTI_MASTER}
  flush_threshold = 1024
  flush_interval  = 10s

  host_template = {
    measurement = "\$host.check_command$"
    tags = {
      hostname = "\$host.name$"
    }
  }
  service_template = {
    measurement = "\$service.check_command$"
    tags = {
      hostname = "\$host.name$"
      service = "\$service.name$"
    }
  }
}

EOF

  fi
}

configure_influxdb
