help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

run:  ## Run docker compose
	docker-compose up

build:  ## Build docker
	docker build -t einstore/einstore-core:local-dev .

build-debug:  ## Build docker image in debug mode
	docker build --build-arg CONFIGURATION="debug" -t einstore/einstore-core:local-dev-debug .

clean:  ## Clean docker compose and .build folder
	docker-compose stop -t 2
	docker-compose down --volumes
	docker-compose --project-name boostcore-test stop -t 2
	docker-compose --project-name boostcore-test down --volumes
	rm -rf .build

test:  ## Run tests in docker
	docker-compose --project-name boostcore-test down
	docker-compose --project-name boostcore-test run --rm api swift test
	docker-compose --project-name boostcore-test down

xcode:  ## Generate Xcode project
	cp ./EinstoreCore.xcodeproj/xcshareddata/xcschemes/EinstoreRun.xcscheme ./EinstoreRun.xcscheme
	vapor xcode -n --verbose
	mv ./EinstoreRun.xcscheme ./EinstoreCore.xcodeproj/xcshareddata/xcschemes/EinstoreRun.xcscheme
	
update:  ## Update all dependencies but keep same versions
	cp ./EinstoreCore.xcodeproj/xcshareddata/xcschemes/EinstoreRun.xcscheme ./EinstoreRun.xcscheme
	rm -rf .build
	vapor clean -y --verbose
	vapor xcode -n --verbose
	mv ./EinstoreRun.xcscheme ./EinstoreCore.xcodeproj/xcshareddata/xcschemes/EinstoreRun.xcscheme
	
upgrade:  ## Upgrade all dependencies to the latest versions
	cp ./EinstoreCore.xcodeproj/xcshareddata/xcschemes/EinstoreRun.xcscheme ./EinstoreRun.xcscheme
	rm -rf .build
	vapor clean -y --verbose
	rm -f Package.resolved
	vapor xcode -n --verbose
	mv ./EinstoreRun.xcscheme ./EinstoreCore.xcodeproj/xcshareddata/xcschemes/EinstoreRun.xcscheme

linuxmain:  ## Generate linuxmain file
	swift test --generate-linuxmain