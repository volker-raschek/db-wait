package cmd

import (
	"net/url"
	"time"

	"git.cryptic.systems/volker.raschek/db-wait/pkg/dbwait"
	"github.com/spf13/cobra"

	_ "github.com/lib/pq"
	_ "github.com/sijms/go-ora/v2"
)

func Execute(version string) error {
	rootCmd := &cobra.Command{
		Use:   "db-wait",
		Short: "Tool to wait until a connection to a database can be established",
		Args:  cobra.ExactArgs(1),
		RunE:  rootRunE,
		Long: `Wait until a database connection can be established and returns a zero exit code if successfully

# Wait until oracle database is ready to establish connections
$ db-wait oracle://user:password@localhost:1521/xe

# Wait until postgres database is ready to establish connections
$ db-wait postgres://user:password@localhost:5432/postgres?sslmode=disable
`,
	}
	rootCmd.Flags().Duration("period", time.Second*5, "Period")
	rootCmd.Flags().Duration("timeout", time.Second*60, "Timeout")

	return rootCmd.Execute()
}

func rootRunE(cmd *cobra.Command, args []string) error {
	period, err := cmd.Flags().GetDuration("period")
	if err != nil {
		return err
	}

	timeout, err := cmd.Flags().GetDuration("timeout")
	if err != nil {
		return err
	}

	databaseURL, err := url.Parse(args[0])
	if err != nil {
		return err
	}

	return dbwait.Wait(databaseURL, period, timeout)
}
