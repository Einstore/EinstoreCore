FROM einstore/einstore-base:2.0 as builder

WORKDIR /app
COPY . /app

RUN swift build --configuration debug --product EinstoreRun

# ------------------------------------------------------------------------------

FROM einstore/einstore-base:2.0

WORKDIR /app
COPY --from=builder /app/.build/debug/EinstoreRun /app

ENTRYPOINT ["/app/EinstoreRun"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "8080"]
