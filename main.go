package main

import (
	"git.cryptic.systems/volker.raschek/db-wait/cmd"
	_ "github.com/lib/pq"
	_ "github.com/sijms/go-ora/v2"
)

var version string

func main() {
	_ = cmd.Execute(version)
}
