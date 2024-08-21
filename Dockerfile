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

WORKDIR /home/app/.wine/drive_c

# 加载注入器
ADD DllInjector.exe DllInjector.exe
RUN sudo chown app:app DllInjector.exe && sudo chmod a+x DllInjector.exe

COPY faker.exe faker.exe
RUN sudo chown app:app faker.exe && sudo chmod a+x faker.exe

# 下载微信
ADD ${WECHAT_URL} WeChatSetup.exe
RUN sudo chown app:app WeChatSetup.exe  && sudo chmod a+x WeChatSetup.exe

# 下载wxhelper.dll
ADD ${WXHELPER_URL} wxhelper.dll
RUN sudo chown app:app wxhelper.dll

# 安装微信
COPY install-wechat.sh install-wechat.sh

RUN sudo chmod a+x install-wechat.sh && ./install-wechat.sh && rm -rf WeChatSetup.exe && rm -rf install-wechat.sh

COPY --from=builder /app/apiserver.conf /home/app/.wine/drive_c/apiserver.conf

COPY --from=builder /app/apiserverd /home/app/.wine/drive_c/apiserverd

ADD msyh.ttc msyh.ttc
ADD msyhbd.ttc msyhbd.ttc
ADD msyhl.ttc msyhl.ttc
RUN sudo mv msyh* /home/app/.wine/drive_c/windows/Fonts && sudo chown app:app /home/app/.wine/drive_c/windows/Fonts/msyh*

ADD font.reg font.reg
RUN regedit msyh_font.reg

USER app

EXPOSE 5900 19088

COPY cmd.sh /cmd.sh

RUN sudo chmod +x /cmd.sh

CMD ["/cmd.sh"]
