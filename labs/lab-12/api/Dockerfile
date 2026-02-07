# Baseline runtime (for comparison)
# ---- builder ----
FROM golang:1.22-alpine AS builder
WORKDIR /src
RUN apk add --no-cache ca-certificates
COPY go.mod ./
RUN go mod download
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/notes-api .

# ---- runtime ----
FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /out/notes-api /app/notes-api
USER app:app
EXPOSE 8080
ENV PORT=8080
ENTRYPOINT ["/app/notes-api"]
