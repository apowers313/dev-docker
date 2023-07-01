FROM ubuntu:22.04

ARG DEV_PASSWORD
RUN test -n "$DEV_PASSWORD"

# Make REAL Ubuntu
ENV DEBIAN_FRONTEND noninteractive
RUN apt update
RUN apt install -y ubuntu-server

# Basic tools
RUN apt install -y net-tools sudo

# Setup user
RUN useradd -ms /bin/bash apowers
WORKDIR /home/apowers
RUN mkdir /home/apowers/Projects
RUN chown apowers:apowers /home/apowers/Projects
RUN echo "export PASSWORD=$VSCODE_PASSWORD" >> /home/apowers/.profile
RUN echo "apowers ALL=(ALL:All) NOPASSWD:ALL" >> /etc/sudoers

# Python
RUN apt install -y python3 python3-pip

# VS Code
RUN apt install -y jq libatomic1 nano netcat
RUN curl -fsSL https://code-server.dev/install.sh |  sh
COPY ./vscode-config.yaml /home/apowers/.config/code-server/config.yaml
RUN sed -i.bak "s/password: passwd/password: ${DEV_PASSWORD}/" /home/apowers/.config/code-server/config.yaml
EXPOSE 8004

# Nginx
#RUN apt install -y nginx
#COPY ./code-server /etc/nginx/sites-available/code-server
#RUN ln -s /etc/nginx/sites-available/code-server /etc/nginx/sites-enabled/code-server
#RUN rm /etc/nginx/sites-enabled/default
#EXPOSE 8003

# JupyterLab
RUN pip3 install jupyterlab notebook
RUN sudo -u apowers jupyter lab --generate-config
RUN echo $(echo ${DEV_PASSWORD} | python3 -c "from notebook.auth import passwd; print(f'c.ServerApp.password=\'{passwd(input())}\'')") >>/home/apowers/.jupyter/jupyter_lab_config.py
EXPOSE 8002

# http index of running services
COPY index.html /var/run/indexserver/index.html
EXPOSE 80

# Supervisor
RUN pip3 install supervisor
RUN mkdir -p /var/log/supervisord
COPY ./supervisord.base.conf /usr/local/etc/supervisord.base.conf
EXPOSE 8001

USER apowers

# Run Server
CMD ["sudo", "supervisord", "-c", "/usr/local/etc/supervisord.base.conf"]
