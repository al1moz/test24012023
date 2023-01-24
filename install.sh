#/bin/sh
docker run \
  --restart=always \
  --net=host \
  --name=tydom2mqtt \
  -e TYDOM_MAC='001A25xxxxxx' \
  -e TYDOM_IP='192.168.1.xx' \
  -e TYDOM_PASSWORD='TYDOM_PASSWORD' \
  -e TYDOM_ALARM_PIN = None \
  -e TYDOM_ALARM_HOME_ZONE = 1 \
  -e TYDOM_ALARM_NIGHT_ZONE = 2 \
  -e MQTT_USER='MQTT_USER' \
  -e MQTT_PASSWORD='MQTT_PASSWORD' \
  -e MQTT_PORT='MQTT_PORT' \
  -e MQTT_SSL='MQTT_SSL' \
  mrwiwi/tydom2mqtt_edge

