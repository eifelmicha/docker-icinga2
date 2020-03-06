
# docker-icinga2

creates several containers with different icinga2 characteristics:

- icinga2 as master with a certificats service
- icinga2 as satellite

---

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-icinga2.svg?branch)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-icinga2.svg?branch)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-icinga2.svg?branch)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-icinga2/
[microbadger]: https://microbadger.com/images/bodsch/docker-icinga2
[travis]: https://travis-ci.org/bodsch/docker-icinga2

# Base Distribution
After a long time with _alpine_ as the base I had to go back to a _debian based_ distribution. I couldn't run Icinga stable with the musl lib. :(

The current Dockerfiles are structured so that you can use both `debian` (`9-slim`) and/or `ubuntu` (`18.10`).

# Build
You can use the included Makefile.

- To build the Containers: `make`<br>
  bundle following calls:
    * `make build_base` (builds an base container with all needed components)
    * `make build_master`(builds an master container with the icinga certificate service)
    * `make build_satellite` (build also an satellite)
- To build an valid `docker-compose.yml` file: `make compose-file`
- To remove the builded Docker Images: `make clean`
- use a container with login shell:<br>
    * `make base-shell`
    * `make master-shell`
    * `make satellite-shell`
- run tests `make test`
  bundle following calls:
    * `make linter`
    *  `make integration_test`

_You can specify an image version by using the `ICINGA2_VERSION` environment variable (This defaults to the "latest" tag)._

_To change this export an other value for `ICINGA2_VERSION` (e.g. `export ICINGA_VERSION=2.8.4`)_

# Contribution
Please read [Contribution](CONTRIBUTIONG.md)

# Development,  Branches (Github Tags)
The `master` Branch is my *Working Horse* includes the "latest, hot shit" and can be complete broken!

# side-channel / custom scripts
if use need some enhancements, you can add some (bash) scripts and add them via volume to the container:

```bash
--volume=/${PWD}/tmp/test.sh:/init/custom.d/test.sh
```

***This scripts will be started before everything else!***

***YOU SHOULD KNOW WHAT YOU'RE DOING.***

***THIS CAN BREAK THE COMPLETE ICINGA2 CONFIGURATION!***


# Availability
I use the official [Icinga2 packages](http://packages.icinga.com) from Icinga.

# Docker Hub
You can find the Container also at  [DockerHub](https://hub.docker.com/r/michaelsiebertz/docker-icinga2/)

# Notices
The actuall Container Supports a stable MySQL Backend to store all needed Datas into it.

## activated Icinga2 Features
- api
- command
- checker
- mainlog
- notification
- graphite (only available if the environment variables are set)


# supported Environment Vars

**make sure you only use the environment variable you need!**

## icinga2

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `ICINGA2_MAINLOG`                  | `false`              | Wether to write logs to var/log/icinga2/icinga2.log inside container or not |
| `ICINGA2_LOGLEVEL`                 | `warning`            | The minimum severity for the main-log.<br>For more information, see into the [icinga doku](https://www.icinga.com/docs/icinga2/latest/doc/09-object-types/#objecttype-filelogger) |
| `HOSTNAME`                  | `false`              | Hostname for the Icinga Container that will be used |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `ICINGA2_MASTER`                   | -                    | The Icinga2-Master FQDN for a Satellite Node                    |
| `ICINGA2_PARENT`                   | -                    | The Parent Node for an Cluster Setup (not yet implemented)      |
| `MULTI_MASTER`                     | ´false`              | Wether to use HA Setup or not                                   |
| `HA_MASTER1`                       | -                    | IP /DNS of Master1      |
| `HA_MASTER2`                       | -                    | IP /DNS of Master2      |
| `HA_MASTER2_PORT`                  | ´5665`               | Port for active connection from master1 to master2  |
| `HA_CONFIG_MASTER`                 | ´false`              | You can only have one so-called “config master” in a zone which stores the configuration in the zones.d directory. Multiple nodes with configuration files in the zones.d directory are not supported. |


## database support

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `MYSQL_HOST`                       | -                    | MySQL Host                                                      |
| `MYSQL_PORT`                       | `3306`               | MySQL Port                                                      |
| `MYSQL_ROOT_USER`                  | `root`               | MySQL root User                                                 |
| `MYSQL_ROOT_PASS`                  | *randomly generated* | MySQL root password                                             |
| `IDO_USER`                         | `icinga2`            | User  Name for IDO                                              |
| `IDO_DATABASE_NAME`                | `icinga2core`        | Schema Name for IDO                                             |
| `IDO_PASSWORD`                     | *randomly generated* | MySQL password for IDO                                          |
| `MYSQL_IDOC_CNA`                   | `31d`                | Max age for contactnotifications table rows                     |
| `MYSQL_IDOC_DHA`                   | `48h`                | Max age for downtimehistory table rows                          |
| `MYSQL_IDOC_ACK`                   | `0`                  | Max age for acknowledgements table rows                         |
| `MYSQL_IDOC_EVH`                   | `0`                  | Max age for eventhandlers table rows                            |
| `MYSQL_IDOC_FHA`                   | `0`                  | Max age for flappinghistory table rows                          |
| `MYSQL_IDOC_HCA`                   | `0`                  | Max age for hostalives table rows                               |
| `MYSQL_IDOC_NA`                    | `0`                  | Max age for notifications table rows                            |

## create API User

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `ICINGA2_API_USERS`                | -                    | comma separated List to create API Users.<br>The Format are `username:password`<br>(e.g. `admin:admin,dashing:dashing` and so on)                  |
| `ICINGA2_API_PROM_USER`            | -                    | comma separated List to create ReadOnly API Users for e.g. Prometheus |

## support Carbon/Graphite

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
|                                    |                      |                                                                 |
| `CARBON_HOST`                      | -                    | hostname or IP address where Carbon/Graphite daemon is running  |
| `CARBON_PORT`                      | `2003`               | Carbon port for graphite                                        |

## notifications over SMTP

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `ICINGA2_MSMTP_RELAY_SERVER`       | -                    | SMTP Service to send Notifications                              |
| `ICINGA2_MSMTP_REWRITE_DOMAIN`     | -                    |                                                                 |
| `ICINGA2_MSMTP_RELAY_USE_STARTTLS` | -                    |                                                                 |
| `ICINGA2_MSMTP_SENDER_EMAIL`       | -                    |                                                                 |
| `ICINGA2_MSMTP_SMTPAUTH_USER`      | -                    |                                                                 |
| `ICINGA2_MSMTP_SMTPAUTH_PASS`      | -                    |                                                                 |
| `ICINGA2_MSMTP_RECV_ROOT`          | -                    |  Set default recipient                                          |
| `ICINGA2_MSMTP_ACC_NAME`           | -                    |  Set account name for msmtp setup                               |

## InfluxDB Integration

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `INFLUXDB_HOST`                    | -                    | InfluxDB Host |
| `INFLUXDB_PORT`                    | `8086`               | InfluxDB Port |
| `INFLUXDB_DB`                      | `icinga2`            | InfluxDB Database Name |
| `INFLUXDB_USER`                    | -                    | InfluxDB Username |
| `INFLUXDB_PASS`                    | -                    | InfluxDB Password |

![master-satellite](doc/assets/master-satellite.jpg)
