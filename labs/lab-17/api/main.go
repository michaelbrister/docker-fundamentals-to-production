package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func env(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

func main() {
	port := env("PORT", "8080")
	release := env("RELEASE_VERSION", "0.0.0-dev")

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok\n"))
	})
	mux.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"release_version": release,
			"ts":              time.Now().UTC().Format(time.RFC3339),
		})
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "not found", http.StatusNotFound)
	})

	log.Printf(`{"ts":"%s","level":"info","event":"server_start","port":%q,"release_version":%q}`,
		time.Now().UTC().Format(time.RFC3339Nano), port, release)

	log.Fatal(http.ListenAndServe(":"+port, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// tiny request log, no secrets
		path := r.URL.Path
		if path == "" {
			path = "/"
		}
		wrw := &rec{ResponseWriter: w, status: 200}
		mux.ServeHTTP(wrw, r)
		log.Printf(`{"ts":"%s","level":"info","event":"http_request","method":%q,"path":%q,"status":%d}`,
			time.Now().UTC().Format(time.RFC3339Nano),
			r.Method, strings.Split(path, "?")[0], wrw.status,
		)
	})))
}

type rec struct {
	http.ResponseWriter
	status int
}

func (r *rec) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}
