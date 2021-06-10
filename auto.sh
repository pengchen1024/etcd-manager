#!/usr/bin/env bash

if [ "$(whoami)" != "root" ];then
  echo "root permission need"
  exit 1
fi

while [[ $# -ge 1 ]]; do
  case $1 in
    -install )
      INSTALL=true
      shift
      ;;
    -uninstall )
      UNINSTALL=true
      shift
      ;;
    -install_path )
      INSTALL_PATH=$2
      shift 2
      ;;
    -cluster )
      CLUSTER=$2
      shift 2
      ;;
    -data_path )
      DATA_PATH=$2
      shift 2
      ;;
    -log_path )
      LOG_PATH=$2
      shift 2
      ;;
    -run_user )
      RUN_USER=$2
      shift 2
      ;;
    -h )
      echo "-install"
      echo "-uninstall"
      echo "-install_path     default:/opt/soft/etcd"
      echo "-cluster          cluster IP1:IP2:IP3 ..."
      echo "-log_path         default:/opt/soft/log/etcd"
      echo "-run_user         default:etcd"
      echo "-h                help info"
      shift
      exit 0
      ;;
    * )
    echo "undefined:$1"
    exit 1
    ;;
  esac
done
THIS_PATH=$(cd "$(dirname "$0")" && pwd)
if [ "$INSTALL_PATH" == "" ];then
  INSTALL_PATH=/opt/soft/etcd
fi
if [ "$DATA_PATH" == "" ];then
  DATA_PATH=/var/lib/etcd
fi
if [ "$LOG_PATH" == "" ];then
  LOG_PATH=/opt/soft/log/etcd
fi

if [ "$RUN_USER" == "" ];then
  RUN_USER="etcd"
fi

SERVICE="etcd"

if [ "$INSTALL" == "true" ];then
  set -e
  if [ -d $INSTALL_PATH/jars/ ];then
      echo "$SERVICE already installed : $INSTALL_PATH"
      exit 1
  fi

  if ! id -u $RUN_USER &>/dev/null; then
    useradd $RUN_USER -M 
  fi

  mkdir -p $INSTALL_PATH
  cp -rf "$THIS_PATH"/* $INSTALL_PATH
  chown -R $RUN_USER:$RUN_USER $INSTALL_PATH
  mkdir -p $DATA_PATH
  chown -R $RUN_USER:$RUN_USER $DATA_PATH
  mkdir -p $LOG_PATH
  chown -R $RUN_USER:$RUN_USER $LOG_PATH

  cat >/usr/lib/systemd/system/$SERVICE.service<< EOF
[Unit]
Description=$SERVICE Daemon
After=network.target

[Service]
User=$RUN_USER
ExecStart=/opt/soft/etcd/bin/etcd --config-file /opt/soft/etcd/conf/etcd.conf 
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
EOF

  cat >$INSTALL_PATH/conf/$SERVICE.conf<< EOF
name: default
data-dir: $DATA_PATH/data
wal-dir:  $DATA_PATH/wal
EOF

  systemctl daemon-reload
  systemctl enable $SERVICE.service > /dev/null  2>&1
  exit 0
fi

if [ "$UNINSTALL" == "true" ];then
  systemctl stop $SERVICE
  systemctl disable $SERVICE.service > /dev/null  2>&1
  rm -rf /usr/lib/systemd/system/$SERVICE.service
  rm -rf $INSTALL_PATH
fi
