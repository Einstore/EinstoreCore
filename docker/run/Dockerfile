FROM liveui/boost-base:1.4.0

WORKDIR /app

#COPY .build ./.build
COPY Resources ./Resources
COPY Sources ./Sources
COPY Tests ./Tests
COPY Package.swift ./
COPY Package.resolved ./
COPY scripts/wait-for-it.sh ./

RUN swift build --configuration debug
RUN ln -s .build/x86_64-unknown-linux/debug/BoostRun ./run

EXPOSE 8080
CMD ./run serve --hostname 0.0.0.0
