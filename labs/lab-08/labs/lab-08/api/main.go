package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync/atomic"
	"time"

	_ "github.com/lib/pq"
)

type Note struct {
	ID        int       `json:"id"`
	Message   string    `json:"message"`
	CreatedAt time.Time `json:"created_at"`
}

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func main() {
	port := env("PORT", "8080")

	dbHost := env("DB_HOST", "")
	dbPort := env("DB_PORT", "5432")
	dbName := env("DB_NAME", "")
	dbUser := env("DB_USER", "")
	dbPass := env("DB_PASSWORD", "")

	if dbHost == "" || dbName == "" || dbUser == "" || dbPass == "" {
		log.Fatal("missing required DB env vars")
	}

	dsn := fmt.Sprintf(
		"host=%s port=%s dbname=%s user=%s password=%s sslmode=disable",
		dbHost, dbPort, dbName, dbUser, dbPass,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("db open failed: %v", err)
	}

	db.SetConnMaxLifetime(30 * time.Second)
	db.SetMaxOpenConns(4)
	db.SetMaxIdleConns(4)

	var ready atomic.Bool
	var readyMsg atomic.Value
	readyMsg.Store("not ready")

	check := func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := db.PingContext(ctx); err != nil {
			ready.Store(false)
			readyMsg.Store("not ready: db ping failed")
			return
		}

		var reg sql.NullString
		if err := db.QueryRowContext(ctx, "select to_regclass('public.notes');").Scan(&reg); err != nil || !reg.Valid {
			ready.Store(false)
			readyMsg.Store("not ready: schema missing")
			return
		}

		ready.Store(true)
		readyMsg.Store("ready")
	}

	go func() {
		for {
			check()
			time.Sleep(2 * time.Second)
		}
	}()

	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(200)
		w.Write([]byte("ok
"))
	})

	mux.HandleFunc("/readyz", func(w http.ResponseWriter, _ *http.Request) {
		if ready.Load() {
			w.WriteHeader(200)
			w.Write([]byte("ready
"))
		} else {
			w.WriteHeader(503)
			w.Write([]byte(readyMsg.Load().(string) + "
"))
		}
	})

	mux.HandleFunc("/notes", func(w http.ResponseWriter, r *http.Request) {
		if !ready.Load() {
			w.WriteHeader(503)
			w.Write([]byte(readyMsg.Load().(string) + "
"))
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()

		switch r.Method {
		case http.MethodGet:
			limit := 20
			if v := r.URL.Query().Get("limit"); v != "" {
				if n, err := strconv.Atoi(v); err == nil && n > 0 && n <= 100 {
					limit = n
				}
			}

			rows, err := db.QueryContext(ctx,
				"select id, message, created_at from notes order by id desc limit $1",
				limit,
			)
			if err != nil {
				http.Error(w, err.Error(), 500)
				return
			}
			defer rows.Close()

			var notes []Note
			for rows.Next() {
				var n Note
				rows.Scan(&n.ID, &n.Message, &n.CreatedAt)
				notes = append(notes, n)
			}
			json.NewEncoder(w).Encode(notes)

		case http.MethodPost:
			var body struct{ Message string }
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Message == "" {
				http.Error(w, "invalid body", 400)
				return
			}
			var id int
			db.QueryRowContext(ctx,
				"insert into notes (message) values ($1) returning id",
				body.Message,
			).Scan(&id)
			w.WriteHeader(201)
			json.NewEncoder(w).Encode(map[string]any{"id": id, "message": body.Message})
		default:
			http.Error(w, "method not allowed", 405)
		}
	})

	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}
