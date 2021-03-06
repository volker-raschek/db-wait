package dbwait

import (
	"context"
	"database/sql"
	"fmt"
	"net/url"
	"os"
	"strings"
	"time"
)

func Wait(databaseURL *url.URL, period time.Duration, timeout time.Duration) error {
	var err error
	var sqlDB *sql.DB

	switch databaseURL.Scheme {
	case "oracle":
		sqlDB, err = sql.Open("oracle", databaseURL.String())
		if err != nil {
			return err
		}
	case "postgres":
		sqlDB, err = sql.Open("postgres", databaseURL.String())
		if err != nil {
			return err
		}
	}
	defer sqlDB.Close()

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	ticker := time.NewTicker(time.Nanosecond)
	<-ticker.C

LOOP:
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			queryCtx, queryCancel := context.WithTimeout(ctx, period)
			defer queryCancel()

			switch databaseURL.Scheme {
			case "oracle":
				row := sqlDB.QueryRowContext(queryCtx, "SELECT INSTANCE_NAME, STATUS, DATABASE_STATUS FROM V$INSTANCE WHERE INSTANCE_NAME=$1", databaseURL.Path)

				var instaceName string
				var instanceStatus string
				var databaseStatus string

				err := row.Scan(instaceName, instanceStatus, databaseStatus)
				if err != nil {
					fmt.Fprintf(os.Stderr, "%s: %s\n", time.Now().String(), err.Error())
					ticker.Reset(period)
					continue LOOP
				}

				if strings.ToUpper(instanceStatus) != "OPEN" {
					fmt.Fprintf(os.Stderr, "%s: Instance status is not open: %s\n", time.Now().String(), instanceStatus)
					ticker.Reset(period)
					continue LOOP
				}

				if strings.ToUpper(databaseStatus) != "OPEN" {
					fmt.Fprintf(os.Stderr, "%s: Database status is not active: %s\n", time.Now().String(), databaseStatus)
					ticker.Reset(period)
					continue LOOP
				}

				return nil
			case "postgres":
				row := sqlDB.QueryRowContext(queryCtx, "SELECT 1 AS ROW")
				if row.Err() != nil {
					fmt.Fprintf(os.Stderr, "%s: %s\n", time.Now().String(), err.Error())
					ticker.Reset(period)
					continue LOOP
				}
				return nil
			}
		}
	}
}
