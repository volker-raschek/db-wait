package dbwait

import (
	"context"
	"database/sql"
	"fmt"
	"net/url"
	"os"
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
				_, err := sqlDB.QueryContext(queryCtx, "SELECT 1 FROM dual")
				if err != nil {
					fmt.Fprintf(os.Stderr, "%s: %s\n", time.Now().String(), err.Error())
					ticker.Reset(period)
					continue LOOP
				}
				return nil
			case "postgres":
				_, err := sqlDB.QueryContext(queryCtx, "SELECT 1 AS ROW")
				if err != nil {
					fmt.Fprintf(os.Stderr, "%s: %s\n", time.Now().String(), err.Error())
					ticker.Reset(period)
					continue LOOP
				}
				return nil
			}
		}
	}
}
