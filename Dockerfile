FROM golang:1.22 AS builder

WORKDIR /app

COPY . .

ENV GOPROXY=https://goproxy.cn,direct

RUN go mod tidy

RUN CGO_ENABLED=0 GOOS=linux go build --ldflags="-s -w" -o apiserverd main.go

FROM zlsdzh001/wine-vnc-box:latest

# 清理环境
RUN sudo rm -rf /tmp/.X0-lock

# install lsof
RUN sudo apt-get install -y lsof

# 根据传入参数安装微信和wxhelper.dll
ARG WECHAT_URL=https://github.com/tom-snow/wechat-windows-versions/releases/download/v3.9.5.81/WeChatSetup-3.9.5.81.exe
ARG WXHELPER_URL=https://github.com/ttttupup/wxhelper/releases/download/3.9.5.81-v11/wxhelper.dll
ARG MSYH_URL=https://raw.githubusercontent.com/SangYuhiter/StudyForYourself/main/Fonts/MSYH/MSYH.TTC
ARG MSYHBD_URL=https://raw.githubusercontent.com/SangYuhiter/StudyForYourself/main/Fonts/MSYH/MSYHBD.TTC
ARG MSYHL_URL=https://raw.githubusercontent.com/SangYuhiter/StudyForYourself/main/Fonts/MSYH/MSYHL.TTC

WORKDIR /home/app/.wine/drive_c

# 加载注入器
ADD DllInjector.exe DllInjector.exe
RUN sudo chown app:app DllInjector.exe && sudo chmod a+x DllInjector.exe

COPY faker.exe faker.exe
RUN sudo chown app:app faker.exe && sudo chmod a+x faker.exe

# 下载微信
ADD ${WECHAT_URL} WeChatSetup.exe
RUN sudo chown app:app WeChatSetup.exe  && sudo chmod a+x WeChatSetup.exe

ADD ${MSYH_URL} Fonts/MSYH.TTC
ADD ${MSYHBD_URL} Fonts/MSYHBD.TTC
ADD ${MSYHL_URL} Fonts/MSYHL.TTC
RUN sudo chown app:app Fonts/MSYH*

# 下载wxhelper.dll
ADD ${WXHELPER_URL} wxhelper.dll
RUN sudo chown app:app wxhelper.dll

# 安装微信
COPY install-wechat.sh install-wechat.sh

RUN sudo chmod a+x install-wechat.sh && ./install-wechat.sh && rm -rf WeChatSetup.exe && rm -rf install-wechat.sh



COPY --from=builder /app/apiserver.conf /home/app/.wine/drive_c/apiserver.conf

COPY --from=builder /app/apiserverd /home/app/.wine/drive_c/apiserverd

USER app

EXPOSE 5900 19088

COPY cmd.sh /cmd.sh

RUN sudo chmod +x /cmd.sh



CMD ["/cmd.sh"]
