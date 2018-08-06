FROM liveui/boost-base:1.1.1

WORKDIR /boost

#ENV PATH="/usr/local/bin:${PATH}"

#ADD .build ./.build
ADD Resources ./Resources
ADD Sources ./Sources
ADD Tests ./Tests
ADD Package.swift ./
ADD Package.resolved ./

RUN swift build --configuration debug
RUN ln -s .build/x86_64-unknown-linux/debug/BoostRun ./boost

COPY ./scripts/wait-for-it.sh .

EXPOSE 8080
CMD ./boost serve --hostname 0.0.0.0
