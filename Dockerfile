FROM liveui/boost-base:2.0

WORKDIR /app
COPY . /app

RUN swift build --configuration debug

# TODO
#RUN swift build --configuration release

ENTRYPOINT /app/run
CMD ["serve", "--hostname", "0.0.0.0", "--port", "8080"]
