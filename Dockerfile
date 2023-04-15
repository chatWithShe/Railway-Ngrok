#FROM ubuntu
#RUN apt update && apt install -y \
#     ssh wget unzip vim curl
# RUN apt install -y tmux
#RUN apt install -y python3
#RUN apt install -y python3-pip
#RUN pip3 install requests

FROM curlimages/curl:7.82.0


ARG NGROK_TOKEN=tokenFrom_http_dashboard.ngrok.com/auth
ARG REGION=jp
ARG FRP_IP=frps.xxx.com
ARG PORT_SSH=52030
ARG PORT_SOCKS_PROXY=52031
ARG PORT_HTTP_PROXY=52032
# ENV NGROK_TOKEN=${NGROK_TOKEN:-iamtoken}
# ENV REGION=${REGION:-jp}
# ENV FRP_IP=${FRP_IP:-frps.xxx.com}
# ENV PORT_SSH=${PORT_SSH:-52030}
# ENV PORT_SOCKS_PROXY=${PORT_SOCKS_PROXY:-52031}
# ENV PORT_HTTP_PROXY=${PORT_HTTP_PROXY:-52032}
# ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /tmp/gost \
    && cd /tmp/gost \
#    && wget -q https://github.com/36304099/Railway-Ngrok/releases/download/v1/gost_3.0.0-rc7_linux_amd64.tar.gz -O gost.tgz\
#    && curl -x socks5://192.168.2.46:20170  -JLo gost.tgz https://github.com/36304099/Railway-Ngrok/releases/download/v1/gost_3.0.0-rc7_linux_amd64.tar.gz \
    && curl -JLo gost.tgz https://github.com/36304099/Railway-Ngrok/releases/download/v1/gost_3.0.0-rc7_linux_amd64.tar.gz \
    && tar -xvzf gost.tgz -C /tmp/gost

RUN echo "<div style='text-align:center;font-size:100px;margin-top:100px;'>chatGPT is NB!</div>" >/tmp/gost/index.html \ 
    && echo "./tmp/gost/gost -L socks://:2023 -L http://:2024 -L=http://gost:gost@:80?probeResistance=file:/tmp/gost/index.html" >/tmp/gost/run.sh \
    && chmod +x /tmp/gost/run.sh \
    && chmod +x /tmp/gost/gost
# ./tmp/gost/run.sh
# ./tmp/gost/run_http.sh

RUN mkdir /tmp/frp \
    && cd /tmp/frp \
#    && wget -q https://github.com/36304099/Railway-Ngrok/releases/download/v1/frp_0.48.0_linux_amd64.tar.gz -O frp.tar.gz\
#    && curl -x socks5://192.168.2.46:20170  -JLo frp.tar.gz https://github.com/36304099/Railway-Ngrok/releases/download/v1/frp_0.48.0_linux_amd64.tar.gz \
    && curl -JLo frp.tar.gz https://github.com/36304099/Railway-Ngrok/releases/download/v1/frp_0.48.0_linux_amd64.tar.gz \
    && tar -xvzf frp.tar.gz -C /tmp/frp \
    && cp /tmp/frp/frp_0.48.0_linux_amd64/frpc /tmp/frp/frpc 

RUN echo "[common]" >/tmp/frp/frpc.ini \
    && echo "server_addr = ${FRP_IP}" >>/tmp/frp/frpc.ini \
    && echo "server_port = 57500" >>/tmp/frp/frpc.ini \
    && echo "[ssh]" >>/tmp/frp/frpc.ini \
    && echo "type = tcp" >>/tmp/frp/frpc.ini \
    && echo "local_ip = 127.0.0.1" >>/tmp/frp/frpc.ini \
    && echo "local_port = 22" >>/tmp/frp/frpc.ini \
    && echo "remote_port = ${PORT_SSH}" >>/tmp/frp/frpc.ini \
    && echo "[socks_proxy]" >>/tmp/frp/frpc.ini \
    && echo "type = tcp" >>/tmp/frp/frpc.ini \
    && echo "local_ip = 127.0.0.1 " >>/tmp/frp/frpc.ini \
    && echo "local_port = 2023" >>/tmp/frp/frpc.ini  \
    && echo "remote_port = ${PORT_SOCKS_PROXY}" >>/tmp/frp/frpc.ini \
    && echo "[http_proxy]" >>/tmp/frp/frpc.ini \
    && echo "type = tcp" >>/tmp/frp/frpc.ini \
    && echo "local_ip = 127.0.0.1 " >>/tmp/frp/frpc.ini \
    && echo "local_port = 2024" >>/tmp/frp/frpc.ini  \
    && echo "remote_port = ${PORT_HTTP_PROXY}" >>/tmp/frp/frpc.ini \
    && echo "cd /tmp/frp && ./frpc -c frpc.ini" >/tmp/frp/run.sh \
    && chmod +x /tmp/frp/frpc \
    && chmod +x /tmp/frp/run.sh
# ./tmp/frp/run.sh



RUN mkdir /tmp/ngrok \
    && cd /tmp/ngrok \
#    && wget -q https://github.com/36304099/Railway-Ngrok/releases/download/v1/ngrok-v3-stable-linux-amd64.tgz -O ngrok.zip\
#    && curl -x socks5://192.168.2.46:20170  -JLo ngrok.tgz https://github.com/36304099/Railway-Ngrok/releases/download/v1/ngrok-v3-stable-linux-amd64.tgz \
    && curl -JLo ngrok.tgz https://github.com/36304099/Railway-Ngrok/releases/download/v1/ngrok-v3-stable-linux-amd64.tgz \
    && tar -xvzf ngrok.tgz -C /tmp/ngrok 

RUN echo nothing \ 
#mkdir /run/sshd \
    && echo "./tmp/ngrok/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &" >>/tmp/openssh.sh \
    && echo "sleep 5" >> /tmp/openssh.sh \
#    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"ssh连接命令:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT默认密码:wangwang\\\")\" || echo \"\nError：请检查NGROK_TOKEN变量是否存在，或Ngrok节点已被占用\n\"" >> /tmp/openssh.sh \
    && echo "curl -o /tmp/ngrok.txt -s http://localhost:4040/api/tunnels && cat /tmp/ngrok.txt" >>/tmp/openssh.sh \
    && echo "./tmp/gost/run.sh &" >> /tmp/openssh.sh \
    && echo "./tmp/gost/run_http.sh &" >> /tmp/openssh.sh \
    && echo "./tmp/frp/run.sh &" >> /tmp/openssh.sh \
    && echo "while :; do echo 'Hit CTRL+C'; sleep 1; done" >> /tmp/openssh.sh \
#    && echo '/usr/sbin/sshd -D' >>/tmp/openssh.sh \
#    && echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config  \
#    && echo root:wakaka|chpasswd \
    && chmod 755 /tmp/openssh.sh
# /tmp/openssh.sh

EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000
CMD /tmp/openssh.sh
