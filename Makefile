run:
	docker-compose up

build:
	docker build -t einstore/einstore-core:local-dev .

build-debug:
	docker build --build-arg CONFIGURATION="debug" -t einstore/einstore-core:local-dev-debug .

clean:
	docker-compose stop -t 2
	docker-compose down --volumes
	docker-compose --project-name boostcore-test stop -t 2
	docker-compose --project-name boostcore-test down --volumes
	rm -rf .build

test:
	docker-compose --project-name boostcore-test down
	docker-compose --project-name boostcore-test run --rm api swift test
	docker-compose --project-name boostcore-test down
