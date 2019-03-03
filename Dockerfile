FROM liveui/boost-base:2.0

WORKDIR /app
COPY . /app

RUN swift build --configuration release --product BoostRun

RUN ln -s .build/release/BoostRun

ENTRYPOINT /app/BoostRun
CMD ["serve", "--hostname", "0.0.0.0", "--port", "8080"]
