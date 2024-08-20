#!/usr/bin/env bash

export DISPLAY_WIDTH=1280
export DISPLAY_HEIGHT=720
export DISPLAY=:0.0
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export WINEPREFIX=/home/app/.wine

sudo mv /home/app/.wine/drive_c/apiserver.conf /etc/supervisord.d/apiserver.conf

exec sudo -E bash -c 'supervisord -c /etc/supervisord.conf -l /var/log/supervisord.log' &

sleep 30

if [ -d "/home/app/.wine/drive_c/Program Files/Tencent" ]; then
  echo '启动64位微信'
  wine 'C:\Program Files\Tencent\WeChat\WeChat.exe' &
else
  echo '启动32位微信'
  wine 'C:\Program Files (x86)\Tencent\WeChat\WeChat.exe' &
fi

wine 'C:\DllInjector.exe' 'C:\wxhelper.dll' WeChat.exe 2>&1

echo 'DllInjector wxhelper.dll end.'

inject_fake_wechat_version() {
  while true; do
      pid=$(lsof -i :19088 | grep "LISTEN" | awk '{print $2}')
      if [ -n "$pid" ]; then
          echo "WeChat is running, pid: $pid"
          wine 'C:\faker.exe' "$pid" '3.9.5.81' '3.9.11.25'
          echo "inject process done"
          break
      else
          echo "inject process not ready, retry in 1s..."
          sleep 1
      fi
  done
}

inject_fake_wechat_version &

wait
