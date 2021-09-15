# db-wait

[![Build Status](https://drone.cryptic.systems/api/badges/volker.raschek/db-wait/status.svg)](https://drone.cryptic.systems/volker.raschek/db-wait)
[![Docker Pulls](https://img.shields.io/docker/pulls/volkerraschek/db-wait)](https://hub.docker.com/r/volkerraschek/db-wait)

With `db-wait` is it possible to wait in CI/CD environments until a database
connection can be established and SQL queries are possible.

This is very useful for example when a database is started for an integration
test and it needs time to start and initialize all schemes before the test
connects to it.

## Usage

As argument db-wait expects a database URI. This can be different depending on
the backend. Currently only oracle and postgres are supported. The supported URI
patterns can be found in the respective library or directly in the documentation
of the database backend.

For example:

```bash
# postgres
db-wait postgres://user:password@localhost:5432/postgres?sslmode=disable

# oracle
db-wait oracle://user:password@localhost:1521/xe
```

More about URI Pattern is documented here for
[oracle](https://godror.github.io/godror/doc/connection.html#-connection-strings)
and
[postgres](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING).

## Installation

There are two ways to install `db-wait`. Directly via `go` or via `make` in
combination with `git` and `go`. The advantage of the second option is that the
binary is installed with all the additional files that the developer specifies.

```bash
# go
$ go install git.cryptic.systems/volker.raschek/db-wait

# git, make, go
$ git clone https://git.cryptic.systems/volker.raschek/db-wait.git && \
  cd db-wait && \
  make install PREFIX=/usr
```

## Usage as container image

Alternatively can be `db-wait` used as container image. A local installation is
not necessary.

```bash
# postgres
$ docker run --rm --network host docker.io/volkerraschek/db-wait:latest \
    postgres://user:password@localhost:5432/postgres?sslmode=disable

# oracle
$ docker run --rm --network host docker.io/volkerraschek/db-wait:latest \
    oracle://user:password@localhost:1521/xe
```
