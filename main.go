package main

import "git.cryptic.systems/volker.raschek/db-wait/cmd"

var version string

func main() {
	_ = cmd.Execute(version)
}
