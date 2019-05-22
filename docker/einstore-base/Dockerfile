FROM swift:4.2

RUN apt-get update && \
    apt-get install -y \
    aapt \
    lib32z1 \
    libc6-dev-i386 \
    libgd-dev \
    libssl-dev \
    openssl \
    software-properties-common \
    gd \
    unzip && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y openjdk-7-jdk="7u95-*" && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y \
    python="2.7.12-*" \
    python-dev \
    python-pip \
    python-software-properties \
    python-virtualenv && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
