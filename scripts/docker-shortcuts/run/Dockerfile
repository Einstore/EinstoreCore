FROM einstore/einstore-base:2.0

WORKDIR /app

#ADD .build ./.build
ADD Resources ./Resources
ADD Sources ./Sources
ADD Tests ./Tests
ADD Package.swift ./
ADD Package.resolved ./

RUN swift build --configuration debug
RUN ln -s .build/x86_64-unknown-linux/debug/EinstoreCoreRun ./run

COPY ./scripts/wait-for-it.sh .

EXPOSE 8080
CMD ./run serve --hostname 0.0.0.0
