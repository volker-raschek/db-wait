EXECUTABLE=db-wait
VERSION?=$(shell git describe --abbrev=0)+hash.$(shell git rev-parse --short HEAD)

# Destination directory and prefix to place the compiled binaries, documentaions
# and other files.
DESTDIR?=
PREFIX?=/usr/local

# CONTAINER_RUNTIME
# The CONTAINER_RUNTIME variable will be used to specified the path to a
# container runtime. This is needed to start and run a container image.
CONTAINER_RUNTIME?=$(shell which podman)

# DB_WAIT_IMAGE_REGISTRY_NAME
# Defines the name of the new container to be built using several variables.
DB_WAIT_IMAGE_REGISTRY_NAME:=git.cryptic.systems
DB_WAIT_IMAGE_REGISTRY_USER:=volker.raschek

DB_WAIT_IMAGE_NAMESPACE?=${DB_WAIT_IMAGE_REGISTRY_USER}
DB_WAIT_IMAGE_NAME:=${EXECUTABLE}
DB_WAIT_IMAGE_VERSION?=latest
DB_WAIT_IMAGE_FULLY_QUALIFIED=${DB_WAIT_IMAGE_REGISTRY_NAME}/${DB_WAIT_IMAGE_NAMESPACE}/${DB_WAIT_IMAGE_NAME}:${DB_WAIT_IMAGE_VERSION}

# BIN
# ==============================================================================
db-wait:
	CGO_ENABLED=1 \
	GOPROXY=$(shell go env GOPROXY) \
		go build -ldflags "-X 'main.version=${VERSION}'" -o ${@} main.go

# CLEAN
# ==============================================================================
PHONY+=clean
clean:
	rm --force --recursive db-wait

# TESTS
# ==============================================================================
PHONY+=test/unit
test/unit:
	CGO_ENABLED=0 \
	GOPROXY=$(shell go env GOPROXY) \
		go test -v -p 1 -coverprofile=coverage.txt -covermode=count -timeout 1200s ./pkg/...

PHONY+=test/integration
test/integration:
	CGO_ENABLED=0 \
	GOPROXY=$(shell go env GOPROXY) \
		go test -v -p 1 -count=1 -timeout 1200s ./it/...

PHONY+=test/coverage
test/coverage: test/unit
	CGO_ENABLED=0 \
	GOPROXY=$(shell go env GOPROXY) \
		go tool cover -html=coverage.txt

# GOLANGCI-LINT
# ==============================================================================
PHONY+=golangci-lint
golangci-lint:
	golangci-lint run --concurrency=$(shell nproc)

# INSTALL
# ==============================================================================
PHONY+=uninstall
install: db-wait
	install --directory ${DESTDIR}/etc/bash_completion.d
	./db-wait completion bash > ${DESTDIR}/etc/bash_completion.d/${EXECUTABLE}

	install --directory ${DESTDIR}${PREFIX}/bin
	install --mode 0755 ${EXECUTABLE} ${DESTDIR}${PREFIX}/bin/${EXECUTABLE}

	install --directory ${DESTDIR}${PREFIX}/share/licenses/${EXECUTABLE}
	install --mode 0644 LICENSE ${DESTDIR}${PREFIX}/share/licenses/${EXECUTABLE}/LICENSE

# UNINSTALL
# ==============================================================================
PHONY+=uninstall
uninstall:
	-rm --force --recursive \
		${DESTDIR}/etc/bash_completion.d/${EXECUTABLE} \
		${DESTDIR}${PREFIX}/bin/${EXECUTABLE} \
		${DESTDIR}${PREFIX}/share/licenses/${EXECUTABLE}

# BUILD CONTAINER IMAGE
# ==============================================================================
PHONY+=container-image/build
container-image/build:
	${CONTAINER_RUNTIME} build \
		--build-arg VERSION=${VERSION} \
		--file Dockerfile \
		--no-cache \
		--pull \
		--tag ${DB_WAIT_IMAGE_FULLY_QUALIFIED} \
		.

# DELETE CONTAINER IMAGE
# ==============================================================================
PHONY:=container-image/delete
container-image/delete:
	- ${CONTAINER_RUNTIME} image rm ${DB_WAIT_IMAGE_FULLY_QUALIFIED}

# PUSH CONTAINER IMAGE
# ==============================================================================
PHONY+=container-image/push
container-image/push:
	echo ${DB_WAIT_IMAGE_REGISTRY_PASSWORD} | ${CONTAINER_RUNTIME} login ${DB_WAIT_IMAGE_REGISTRY_NAME} --username ${DB_WAIT_IMAGE_REGISTRY_USER} --password-stdin
	${CONTAINER_RUNTIME} push ${DB_WAIT_IMAGE_FULLY_QUALIFIED}

# PHONY
# ==============================================================================
# Declare the contents of the PHONY variable as phony.  We keep that information
# in a variable so we can use it in if_changed.
.PHONY: ${PHONY}