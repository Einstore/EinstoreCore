run:
	docker-compose up

build:
	docker build -t einstore/einstore-core:local-dev .

clean:
	docker-compose stop -t 2
	docker-compose down --volumes
	docker-compose --project-name boostcore-test -f docker-compose.yaml -f docker-compose.test.yaml stop -t 2
	docker-compose --project-name boostcore-test -f docker-compose.yaml -f docker-compose.test.yaml down --volumes
	rm -rf .build

test:
	docker-compose --project-name boostcore-test -f docker-compose.yaml -f docker-compose.test.yaml down
	docker-compose --project-name boostcore-test -f docker-compose.yaml -f docker-compose.test.yaml run --rm api swift test
	docker-compose --project-name boostcore-test -f docker-compose.yaml -f docker-compose.test.yaml down
