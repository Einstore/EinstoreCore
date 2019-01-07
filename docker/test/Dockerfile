FROM liveui/boost-base:1.4.0

WORKDIR /app

#COPY .build ./.build
COPY Resources ./Resources
COPY Sources ./Sources
COPY Tests ./Tests
COPY Package.swift ./
COPY Package.resolved ./
COPY scripts/wait-for-it.sh ./

CMD swift test

