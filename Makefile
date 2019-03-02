run:
	docker-compose up --build

test:
	docker-compose -f docker-compose.test.yaml run --rm api swift test
