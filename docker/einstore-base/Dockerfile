FROM vapor3/swift:5.2.1

RUN apt-get update && \
    apt-get install -y \
    aapt \
    lib32z1 \
    libc6-dev-i386 \
    libgd-dev \
    libssl-dev \
    openssl \
    software-properties-common \
    unzip && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get install -y libgd-dev
    
RUN add-apt-repository ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y \
    python \
    python-dev \
    python-pip \
    software-properties-common \
    python-virtualenv && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
