FROM einstore/einstore-base:2.0 as builder

WORKDIR /app
COPY . /app

ARG CONFIGURATION="release"

RUN swift build --configuration ${CONFIGURATION} --product EinstoreRun

# ------------------------------------------------------------------------------

FROM einstore/einstore-base:2.0

ARG CONFIGURATION="release"

WORKDIR /app
COPY --from=builder /app/.build/${CONFIGURATION}/EinstoreRun /app

ENTRYPOINT ["/app/EinstoreRun"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "8080"]
