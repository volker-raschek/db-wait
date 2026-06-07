EXECUTABLE=db-wait
VERSION?=$(shell git describe --abbrev=0)+hash.$(shell git rev-parse --short HEAD)

# Destination directory and prefix to place the compiled binaries, documentaions
# and other files.
DESTDIR?=
PREFIX?=/usr/local

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
test/coverage:
	CGO_ENABLED=0 \
	GOPROXY=$(shell go env GOPROXY) \
		go tool cover -func=coverage.txt

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

# PHONY
# ==============================================================================
# Declare the contents of the PHONY variable as phony.  We keep that information
# in a variable so we can use it in if_changed.
.PHONY: ${PHONY}
