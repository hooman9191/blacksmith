VERSION ?= $(shell git describe --tags)
COMMIT := $(shell git rev-parse HEAD)
BUILD_TIME := $(shell LANG=en_US date +"%F_%T_%z")
DOCKER_IMAGE ?= "cafebazaar/blacksmith"

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  blacksmith   to build the main binary (for linux/amd64)"
	@echo "  docker       to build the docker image"
	@echo "  push         to push the built docker to docker hub"
	@echo "  test         to run unittests"
	@echo "  clean        to remove generated files"

define run-generate =
	go get -v github.com/mjibson/esc
	GOOS=linux GOARCH=amd64 go generate
endef

test: *.go */*.go pxe/pxelinux_autogen.go web/ui_autogen.go
	go get -t -v ./...
	go test -v ./...

blacksmith: *.go */*.go pxe/pxelinux_autogen.go web/ui_autogen.go
	go get -v
	GOOS=linux GOARCH=amd64 go build -ldflags "-s -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.buildTime=$(BUILD_TIME)" -o blacksmith

pxe/pxelinux_autogen.go: pxe/pxelinux
	$(run-generate)

EXTERNAL_FILES := web/ui/bower_components/angular/angular.min.js web/ui/bower_components/angular-route/angular-route.min.js web/ui/bower_components/angular-resource/angular-resource.min.js web/ui/bower_components/angular-xeditable/dist/js/xeditable.min.js web/ui/bower_components/jquery/dist/jquery.min.js web/ui/bower_components/bootstrap/dist/js/bootstrap.min.js web/ui/bower_components/bootstrap/dist/css/bootstrap.css web/ui/bower_components/angular-xeditable/dist/css/xeditable.css
web/ui/external: $(EXTERNAL_FILES)
	mkdir web/ui/external
	cp -v $(EXTERNAL_FILES) web/ui/external

web/ui_autogen.go: web/ui web/ui/external
	$(run-generate)

clean:
	rm -rf blacksmith pxe/pxelinux_autogen.go web/ui_autogen.go web/ui/external

docker: blacksmith
	docker build -t $(DOCKER_IMAGE) .

push:
	docker push $(DOCKER_IMAGE)

.PHONY: help clean docker push test
