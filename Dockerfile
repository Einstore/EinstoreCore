FROM einstore/einstore-base:2.0 as builder

WORKDIR /app
COPY . /app

RUN swift build --configuration release --product BoostRun

# ------------------------------------------------------------------------------

FROM einstore/einstore-base:2.0

WORKDIR /app
COPY --from=builder /app/.build/release/BoostRun /app

ENTRYPOINT ["/app/BoostRun"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "8080"]
