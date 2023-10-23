FROM mcr.microsoft.com/dotnet/sdk:7.0-jammy
USER root

ARG USERNAME
ARG USER_UID
ARG USER_GID

ARG LAZY_DOCKER_VERSION=0.21.1
ARG LAZY_DOCKER_VERSION_NUMERIC=0211
ARG LAZY_GIT_VERSION=0.40.2
ARG LAZY_GIT_VERSION_NUMERIC=0402
ARG NODE_VERSION="20.8.0"
ARG NODE_VERSION_NUMERIC="2080"
ARG PYTHON_VERSION=3.11
ARG SASS_VERSION=1.67.0
ARG SASS_VERSION_NUMERIC=1670

# Install apt packages
RUN apt-get update -y && \
	apt-get install -y \
		curl \
		git \
		locales \
		libcairo2-dev \
		pkg-config \
		python${PYTHON_VERSION} \
		python${PYTHON_VERSION}-dev \
		python3-pip \
		ssh \
		sudo \
		tar \
		tmux \
		tree \
		unzip \
		vim \
		wget \
		zip && \
	update-alternatives --install \
		/usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 3

# Install pip packages
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install -r /tmp/requirements.txt

# Download Node + NPM
RUN wget -O /tmp/node.tar.gz \
		https://nodejs.org/dist/v$NODE_VERSION/node-v${NODE_VERSION}-linux-x64.tar.xz && \
	mkdir -p "/home/$USERNAME/node" && \
	tar -xf /tmp/node.tar.gz -C "/home/$USERNAME/node" && \
	mv "/home/$USERNAME/node/node-v$NODE_VERSION-linux-x64" "/home/$USERNAME/node/$NODE_VERSION" && \
	update-alternatives --install \
		/usr/bin/node node "/home/$USERNAME/node/$NODE_VERSION/bin/node" $NODE_VERSION_NUMERIC \
		--slave /usr/bin/npm npm "/home/$USERNAME/node/$NODE_VERSION/bin/npm" \
		--slave /usr/bin/npx npx "/home/$USERNAME/node/$NODE_VERSION/bin/npx"

# Download SASS
RUN wget -O /tmp/sass.tar.gz \
	https://github.com/sass/dart-sass/releases/download/$SASS_VERSION/dart-sass-$SASS_VERSION-linux-x64.tar.gz && \
	mkdir -p "/home/$USERNAME/sass" && \
	tar -xzf /tmp/sass.tar.gz -C "/home/$USERNAME/sass" && \
	update-alternatives --install \
		/usr/bin/sass \
		sass \
		"/home/$USERNAME/sass/dart-sass/sass" \
		$SASS_VERSION_NUMERIC

# Download lazygit
RUN wget -O /tmp/lazygit.tar.gz \
	https://github.com/jesseduffield/lazygit/releases/download/v$LAZY_GIT_VERSION/lazygit_${LAZY_GIT_VERSION}_Linux_x86_64.tar.gz && \
	mkdir -p "/home/$USERNAME/lazygit/$LAZY_GIT_VERSION" && \
	tar -xzf /tmp/lazygit.tar.gz -C "/home/$USERNAME/lazygit/$LAZY_GIT_VERSION" && \
	update-alternatives --install \
		/usr/bin/lazygit \
		lazygit \
		"/home/$USERNAME/lazygit/$LAZY_GIT_VERSION/lazygit" \
		$LAZY_GIT_VERSION_NUMERIC

# Download lazy docker
RUN wget -O /tmp/lazydocker.tar.gz \
	https://github.com/jesseduffield/lazydocker/releases/download/v$LAZY_DOCKER_VERSION/lazydocker_${LAZY_DOCKER_VERSION}_Linux_x86_64.tar.gz && \
	mkdir -p "/home/$USERNAME/lazydocker/$LAZY_DOCKER_VERSION" && \
	tar -xzf /tmp/lazydocker.tar.gz -C "/home/$USERNAME/lazydocker/$LAZY_DOCKER_VERSION" && \
	update-alternatives --install \
		/usr/bin/lazydocker \
		lazydocker \
		"/home/$USERNAME/lazydocker/$LAZY_DOCKER_VERSION/lazydocker" \
		$LAZY_DOCKER_VERSION_NUMERIC

# Handle extra setup
RUN locale-gen en_US.UTF-8 && \
	update-locale LANG=en_US.UTF-8

# Create the user
# Note that `chown` needs to be run on the home directory since files were
#   placed within that directory earlier in the setup process
# Adding the user to the docker group is necessary to allow lazydocker to work
#   without needing `sudo`
RUN groupadd --gid $USER_GID "$USERNAME" && \
	useradd --uid $USER_UID --gid $USER_GID -m "$USERNAME" -s /bin/bash && \
	echo $USERNAME ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/$USERNAME" && \
	chmod 0440 "/etc/sudoers.d/$USERNAME" && \
	groupadd docker && \
	usermod -aG docker "$USERNAME" && \
	cp /etc/skel/.bashrc "/home/$USERNAME/.bashrc" && \
	chown -R $USER_UID:$USER_GID "/home/$USERNAME"
USER $USERNAME

# Install npm packages
RUN npm install -g nx && \
	echo 'export NODE_PATH="'$(npm root -g)'"' >> ~/.bashrc

# Add aliases
RUN echo "alias gg=lazygit" >> ~/.bashrc && \
	echo "alias dd=lazydocker" >> ~/.bashrc && \
	echo 'alias nx="npx nx"' >> ~/.bashrc

# Add the path that pip scripts are added to
# Note that using `${PATH}` and `$PATH` may have different behavior according
#   to https://github.com/moby/moby/issues/42863. For safety, prefer `$PATH`.
ENV PATH="$PATH:/home/$USERNAME/.local/bin"
