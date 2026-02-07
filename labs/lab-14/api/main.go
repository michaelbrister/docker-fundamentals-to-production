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
	"strings"
	"sync/atomic"
	"time"

	_ "github.com/lib/pq"
)

type Note struct {
	ID        int       `json:"id"`
	Message   string    `json:"message"`
	CreatedAt time.Time `json:"created_at"`
}

type Level int

const (
	LevelDebug Level = iota
	LevelInfo
	LevelWarn
	LevelError
)

func parseLevel(s string) Level {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "debug":
		return LevelDebug
	case "info", "":
		return LevelInfo
	case "warn", "warning":
		return LevelWarn
	case "error":
		return LevelError
	default:
		return LevelInfo
	}
}

func env(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

func readSecretFromFile(path string) (string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	// Trim trailing newline (common for secret files)
	return strings.TrimSpace(string(b)), nil
}

func main() {
	port := env("PORT", "8080")
	appEnv := env("APP_ENV", "dev")
	logLevel := parseLevel(env("LOG_LEVEL", "info"))

	dbHost := env("DB_HOST", "")
	dbPort := env("DB_PORT", "5432")
	dbName := env("DB_NAME", "")
	dbUser := env("DB_USER", "")

	// Secret can arrive via DB_PASSWORD OR via a secrets-mounted file DB_PASSWORD_FILE
	dbPass := os.Getenv("DB_PASSWORD")
	dbPassFile := os.Getenv("DB_PASSWORD_FILE")
	if dbPass == "" && dbPassFile != "" {
		if v, err := readSecretFromFile(dbPassFile); err == nil {
			dbPass = v
		} else {
			log.Fatalf("failed to read DB_PASSWORD_FILE: %v", err)
		}
	}

	// Strict: required configuration must be present
	missing := []string{}
	if dbHost == "" {
		missing = append(missing, "DB_HOST")
	}
	if dbName == "" {
		missing = append(missing, "DB_NAME")
	}
	if dbUser == "" {
		missing = append(missing, "DB_USER")
	}
	if dbPass == "" {
		missing = append(missing, "DB_PASSWORD (or DB_PASSWORD_FILE)")
	}
	if len(missing) > 0 {
		log.Fatalf("missing required settings: %s", strings.Join(missing, ", "))
	}

	// Print config keys (never secrets) — teaches observability without leaks
	if logLevel <= LevelInfo {
		log.Printf("config: APP_ENV=%s LOG_LEVEL=%s PORT=%s", appEnv, strings.ToLower(env("LOG_LEVEL", "info")), port)
		log.Printf("config: DB_HOST=%s DB_PORT=%s DB_NAME=%s DB_USER=%s", dbHost, dbPort, dbName, dbUser)
		if dbPassFile != "" {
			log.Printf("secrets: DB_PASSWORD_FILE=[REDACTED] (loaded)")
		} else {
			log.Printf("secrets: DB_PASSWORD=[REDACTED] (loaded)")
		}
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
	ready.Store(false)
	readyMsg.Store("not ready: db not checked yet")

	checkOnce := func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := db.PingContext(ctx); err != nil {
			ready.Store(false)
			readyMsg.Store("not ready: db ping failed")
			if logLevel <= LevelWarn {
				log.Printf("db not ready: %v", err)
			}
			return
		}

		var reg sql.NullString
		if err := db.QueryRowContext(ctx, "select to_regclass('public.notes');").Scan(&reg); err != nil {
			ready.Store(false)
			readyMsg.Store("not ready: schema check failed")
			if logLevel <= LevelWarn {
				log.Printf("schema check failed: %v", err)
			}
			return
		}
		if !reg.Valid {
			ready.Store(false)
			readyMsg.Store("not ready: schema missing (table notes not found). Did you run init.sql?")
			if logLevel <= LevelWarn {
				log.Printf("schema missing: notes table not found")
			}
			return
		}

		ready.Store(true)
		readyMsg.Store("ready")
	}

	go func() {
		for {
			checkOnce()
			time.Sleep(2 * time.Second)
		}
	}()

	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok\n"))
	})

	mux.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
		if ready.Load() {
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte("ready\n"))
			return
		}
		w.WriteHeader(http.StatusServiceUnavailable)
		_, _ = w.Write([]byte(readyMsg.Load().(string) + "\n"))
	})

	mux.HandleFunc("/notes", func(w http.ResponseWriter, r *http.Request) {
		if !ready.Load() {
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = w.Write([]byte(readyMsg.Load().(string) + "\n"))
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()

		switch r.Method {
		case http.MethodGet:
			limit := 20
			if v := r.URL.Query().Get("limit"); v != "" {
				if n, err := strconv.Atoi(v); err == nil && n > 0 {
					if n > 100 {
						n = 100
					}
					limit = n
				}
			}

			rows, err := db.QueryContext(ctx,
				"select id, message, created_at from notes order by id desc limit $1;",
				limit,
			)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			defer rows.Close()

			var notes []Note
			for rows.Next() {
				var n Note
				if err := rows.Scan(&n.ID, &n.Message, &n.CreatedAt); err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
				notes = append(notes, n)
			}

			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(notes)

		case http.MethodPost:
			var body struct {
				Message string `json:"message"`
			}
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Message == "" {
				http.Error(w, "invalid body; expected JSON {\"message\":\"...\"}", http.StatusBadRequest)
				return
			}

			var id int
			if err := db.QueryRowContext(ctx,
				"insert into notes (message) values ($1) returning id;",
				body.Message,
			).Scan(&id); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusCreated)
			_ = json.NewEncoder(w).Encode(map[string]any{"id": id, "message": body.Message})

		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})

	addr := ":" + port
	log.Printf("listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}
