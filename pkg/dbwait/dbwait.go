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
	defer func() { _ = sqlDB.Close() }()

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
				row := sqlDB.QueryRowContext(queryCtx, "SELECT 1 FROM dual")

				var n int
				err := row.Scan(&n)
				if err != nil {
					fmt.Fprintf(os.Stderr, "%s: %s\n", time.Now().String(), err.Error())
					ticker.Reset(period)
					continue LOOP
				}

				if n != 1 {
					fmt.Fprintf(os.Stderr, "%s: Returned value not 1\n", time.Now().String())
					ticker.Reset(period)
					continue LOOP
				}

				return nil
			case "postgres":
				row := sqlDB.QueryRowContext(queryCtx, "SELECT 1 AS ROW")
				err := row.Err()
				switch err {
				case nil:
					return nil
				default:
					fmt.Fprintf(os.Stderr, "%s: %s\n", time.Now().String(), err.Error())
					ticker.Reset(period)
					continue LOOP
				}
			}
		}
	}
}
