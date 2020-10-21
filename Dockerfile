FROM ubuntu:18.04

ARG LOCAL_USER=devops
ARG LOCAL_PASS=devops

ENV CONTAINER_USER ${LOCAL_USER}
ENV TERM xterm

# setup apt
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update \
  && apt-get install -yq apt-utils \
  && apt-get upgrade -yq \
  && apt-get install -yq \
    software-properties-common locales iputils-ping net-tools vim uuid-runtime \
    sudo man wget nano curl git gawk zip unzip gzip xterm git git-core gitk \
    rsync repo diffstat zsh chrpath socat fonts-powerline ca-certificates \
    apt-transport-https gnupg-agent \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove

# set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# python (prefer python3)
RUN apt-get update \
  && apt-get install -yq python3 python3-pip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove \
  && update-alternatives --install $(which python) python $(which python2.7) 10 \
  && update-alternatives --install $(which python) python $(which python3.6) 20

# install python libs
RUN pip3 install --upgrade pip
RUN pip3 install --upgrade \
  argcomplete \
  paramiko \
  setuptools \
  requests \
  pyVim \
  PyVmomi \
  pywinrm \
  six \
  boto \
  boto3 \
  botocore \
  docker \
  jsondiff \
  PyYAML
RUN pip3 install --upgrade git+https://github.com/vmware/vsphere-automation-sdk-python.git
RUN pip3 install --upgrade pyvcloud

# install govc
RUN curl -L https://github.com/vmware/govmomi/releases/download/v0.22.1/govc_linux_amd64.gz | gunzip > /usr/local/bin/govc

# install docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  && apt-get update \
  && apt-get install -yq docker-ce docker-ce-cli containerd.io \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove

# install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose

# install k8s tools
ARG K8S_VERSION=1.18.8
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main" \
  && apt-get update \
  && apt-get install -yq \
    kubelet=${K8S_VERSION}-00 \
    kubeadm=${K8S_VERSION}-00 \
    kubectl=${K8S_VERSION}-00 \
  && apt-mark hold kubelet kubeadm kubectl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove

# install terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
  && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  && apt-get update \
  && apt-get install -yq terraform consul nomad packer \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove

# install ansible from pip3
RUN pip3 install --upgrade ansible

# # install tkg
# COPY resources/tkg-linux-amd64-v1.1.3_vmware.1.gz /tmp
# RUN gunzip /tmp/tkg-linux-amd64-v1.1.3_vmware.1.gz \
#   && mv /tmp/tkg-linux-amd64-v1.1.3_vmware.1 /usr/local/bin/tkg \
#   && chmod +x /usr/local/bin/tkg

# install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf ./aws

# enable x11 apps
RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
    dirmngr \
    gnupg \
    apulse \
    ca-certificates \
    ffmpeg \
    hicolor-icon-theme \
    libasound2 \
    libcanberra-gtk* \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libpangox-1.0-0 \
    libpulse0 \
    libv4l-0 \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-symbola \
    xdg-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove
COPY local.conf /etc/fonts/local.conf

# setup firefox
RUN apt-get update \
  && apt-get install -yq --no-install-recommends firefox \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove
RUN echo 'pref("browser.tabs.remote.autostart", false);' >> /etc/firefox/syspref.js

# setup chrome
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && add-apt-repository "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" \
  && apt-get update \
  && apt-get install -yq --no-install-recommends google-chrome-stable \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoremove

# create entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# setup vim preferences for root
RUN echo "syntax on\nset number" > /root/.vimrc

# setup user
RUN groupadd -r ${LOCAL_USER} \
  && useradd --no-log-init -m -s /bin/zsh \
    -g ${LOCAL_USER} \
    -G audio,video \
    ${LOCAL_USER}
RUN mkdir -p /home/${LOCAL_USER} \
  && mkdir -p /home/${LOCAL_USER}/Downloads \
  && chown -R ${LOCAL_USER}:${LOCAL_USER} /home/${LOCAL_USER}

# setup local user password
RUN echo ${LOCAL_USER}:${LOCAL_USER} | chpasswd

# assign user to sudo
RUN adduser ${LOCAL_USER} sudo
RUN echo "${LOCAL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# permit user to run docker
RUN usermod -aG docker ${LOCAL_USER}

# switch to local user
USER ${LOCAL_USER}
WORKDIR /home/${LOCAL_USER}

# setup vim preferences for user
RUN echo "syntax on\nset number" > /home/${LOCAL_USER}/.vimrc

# install ohmyzsh
RUN wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O - | zsh || true

# update ohmyzsh config
RUN sed -i 's/^ZSH_THEME=.*/ZSH_THEME=\"bira\"/g' /home/${LOCAL_USER}/.zshrc
RUN sed -i 's/^plugins=.*/plugins=\(git python ansible terraform\)/g' /home/${LOCAL_USER}/.zshrc

# install terraform autocomplete
RUN /usr/bin/terraform -install-autocomplete

# install ansible plugins (required for ansible 2.10 and newer)
RUN /usr/local/bin/ansible-galaxy collection install \
  community.aws \
  community.azure \
  community.crypto \
  community.general \
  community.kubernetes \
  community.network \
  community.vmware \
  community.windows \
  amazon.aws

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "zsh" ]
