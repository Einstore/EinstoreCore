FROM liveui/boost-base:2.0

WORKDIR /app
COPY . /app

RUN swift build --configuration debug

RUN ln -s .build/debug/BoostRun

ENTRYPOINT /app/BoostRun
CMD ["serve", "--hostname", "0.0.0.0", "--port", "8080"]
