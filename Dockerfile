FROM ubuntu:22.04

# Make REAL Ubuntu
ENV DEBIAN_FRONTEND noninteractive
RUN apt update
RUN apt install -y ubuntu-server
#RUN echo y | unminimize

# Basic tools
RUN apt update
RUN apt install -y net-tools sudo

# Install user system
RUN yes | /usr/local/sbin/unminimize

# Setup user
RUN useradd -ms /bin/bash apowers
WORKDIR /home/apowers
RUN mkdir /home/apowers/Projects
RUN mkdir /home/apowers/Projects/jupyter
RUN chown apowers:apowers /home/apowers/Projects
RUN echo "apowers ALL=(ALL:All) NOPASSWD:ALL" >> /etc/sudoers

# Python
RUN apt install -y python3 python3-pip

# Node
#RUN apt install -y nodejs

# VS Code
RUN apt install -y jq libatomic1 nano netcat
RUN curl -fsSL https://code-server.dev/install.sh |  sh
EXPOSE 8004

# JupyterLab
RUN pip3 install jupyterlab notebook
COPY ./jupyter_lab_config.py /home/apowers/.jupyter/jupyter_lab_config.py
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
#ENV PASSWORD password
RUN git config --global user.email "apowers@ato.ms"
RUN git config --global user.name "Adam Powers"
RUN sudo chown apowers:apowers -R /home/apowers
RUN unset DEBIAN_FRONTEND

# Install OpenSSH server
USER root
RUN apt install -y openssh-server
# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN mkdir /var/run/sshd
RUN bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d'
RUN ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config
RUN ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config
RUN RUNLEVEL=1 dpkg-reconfigure openssh-server
RUN ssh-keygen -A -v
RUN update-rc.d ssh defaults
USER apowers

EXPOSE 22

# for development purposes
EXPOSE 9000-9099

# Run Server
CMD ["sudo", "-E", "supervisord", "-c", "/usr/local/etc/supervisord.base.conf"]
