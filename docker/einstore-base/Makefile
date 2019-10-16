REPO = einstore
IMAGE = einstore-base
TAG = 0.0.5

all: build publish

build:
	docker build -t $(REPO)/$(IMAGE):$(TAG) .

publish: build
	docker tag $(REPO)/$(IMAGE):$(TAG) $(REPO)/$(IMAGE):latest
	docker push $(REPO)/$(IMAGE):$(TAG)
	docker push $(REPO)/$(IMAGE):latest
