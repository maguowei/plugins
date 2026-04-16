.PHONY: build run test migrate lint clean

build:
	go build -o bin/server ./cmd/server
	go build -o bin/migrate ./cmd/migrate

run:
	go run ./cmd/server

test:
	go test ./... -v

migrate:
	go run ./cmd/migrate

lint:
	golangci-lint run ./...

generate:
	go generate ./...

clean:
	rm -rf bin/

docker-up:
	docker-compose -f docker/docker-compose.yaml up -d

docker-down:
	docker-compose -f docker/docker-compose.yaml down
