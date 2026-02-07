package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	_ "github.com/lib/pq"
)

type counter struct{ v atomic.Int64 }
func (c *counter) inc()        { c.v.Add(1) }
func (c *counter) load() int64 { return c.v.Load() }
func newCounter() *counter     { return &counter{} }

type durationMetric struct {
	mu    sync.Mutex
	count int64
	sumMs float64
}
func (d *durationMetric) observe(ms float64) { d.mu.Lock(); d.count++; d.sumMs += ms; d.mu.Unlock() }
func (d *durationMetric) snapshot() (int64, float64) { d.mu.Lock(); defer d.mu.Unlock(); return d.count, d.sumMs }

type httpKey struct{ method, path string; status int }

type Metrics struct {
	startedAt int64
	httpReq   map[httpKey]*counter
	httpErr   *counter
	durMs     *durationMetric
	mu        sync.Mutex
}

func nowMs() int64 { return time.Now().UnixMilli() }
func NewMetrics() *Metrics {
	return &Metrics{startedAt: nowMs(), httpReq: map[httpKey]*counter{}, httpErr: newCounter(), durMs: &durationMetric{}}
}
func (m *Metrics) incRequest(method, path string, status int) {
	m.mu.Lock(); defer m.mu.Unlock()
	k := httpKey{method: method, path: path, status: status}
	c := m.httpReq[k]
	if c == nil { c = newCounter(); m.httpReq[k] = c }
	c.inc()
}
func (m *Metrics) observeDuration(ms float64) {
	if ms < 0 { ms = 0 }
	ms = math.Min(ms, 600000)
	m.durMs.observe(ms)
}
func (m *Metrics) render() string {
	uptime := float64(nowMs()-m.startedAt) / 1000.0
	var b strings.Builder
	b.WriteString("# TYPE process_uptime_seconds gauge\n")
	b.WriteString(fmt.Sprintf("process_uptime_seconds %.3f\n", uptime))
	b.WriteString("# TYPE http_requests_total counter\n")
	m.mu.Lock()
	for k, c := range m.httpReq {
		b.WriteString(fmt.Sprintf("http_requests_total{method=%q,path=%q,status=%q} %d\n",
			k.method, k.path, fmt.Sprintf("%d", k.status), c.load(),
		))
	}
	b.WriteString("# TYPE http_errors_total counter\n")
	b.WriteString(fmt.Sprintf("http_errors_total %d\n", m.httpErr.load()))
	cnt, sum := m.durMs.snapshot()
	b.WriteString("# TYPE http_request_duration_ms summary\n")
	b.WriteString(fmt.Sprintf("http_request_duration_ms_count %d\n", cnt))
	b.WriteString(fmt.Sprintf("http_request_duration_ms_sum %.3f\n", sum))
	m.mu.Unlock()
	return b.String()
}

type respRec struct{ http.ResponseWriter; status int }
func (r *respRec) WriteHeader(code int) { r.status = code; r.ResponseWriter.WriteHeader(code) }

func env(key, def string) string { v := os.Getenv(key); if v == "" { return def }; return v }
func readSecret(path string) (string, error) {
	b, err := os.ReadFile(path)
	if err != nil { return "", err }
	return strings.TrimSpace(string(b)), nil
}
func normPath(p string) string {
	switch p {
	case "/healthz","/readyz","/notes","/metrics","/version":
		return p
	default:
		return "/other"
	}
}

func main() {
	port := env("PORT", "8080")
	active := env("ACTIVE_VERSION", env("RELEASE_VERSION", "0.0.0-dev"))

	dbHost := env("DB_HOST", "")
	dbPort := env("DB_PORT", "5432")
	dbName := env("DB_NAME", "")
	dbUser := env("DB_USER", "")

	dbPass := os.Getenv("DB_PASSWORD")
	dbPassFile := os.Getenv("DB_PASSWORD_FILE")
	if dbPass == "" && dbPassFile != "" {
		v, err := readSecret(dbPassFile)
		if err != nil { log.Fatalf("failed to read DB_PASSWORD_FILE: %v", err) }
		dbPass = v
	}
	if dbHost=="" || dbName=="" || dbUser=="" || dbPass=="" { log.Fatalf("missing required DB settings") }

	dsn := fmt.Sprintf("host=%s port=%s dbname=%s user=%s password=%s sslmode=disable", dbHost, dbPort, dbName, dbUser, dbPass)
	db, err := sql.Open("postgres", dsn)
	if err != nil { log.Fatalf("db open failed: %v", err) }

	var ready atomic.Bool
	ready.Store(false)

	check := func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := db.PingContext(ctx); err != nil { ready.Store(false); return }
		var reg sql.NullString
		if err := db.QueryRowContext(ctx, "select to_regclass('public.notes');").Scan(&reg); err != nil || !reg.Valid {
			ready.Store(false); return
		}
		ready.Store(true)
	}
	go func() { for { check(); time.Sleep(2*time.Second) } }()

	metrics := NewMetrics()

	withObs := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			rr := &respRec{ResponseWriter: w, status: 200}
			next.ServeHTTP(rr, r)
			metrics.incRequest(r.Method, normPath(r.URL.Path), rr.status)
			metrics.observeDuration(float64(time.Since(start).Milliseconds()))
			if rr.status >= 500 { metrics.httpErr.inc() }
		})
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(200); _,_ = w.Write([]byte("ok\n")) })
	mux.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
		if ready.Load() { w.WriteHeader(200); _,_ = w.Write([]byte("ready\n")); return }
		w.WriteHeader(503); _,_ = w.Write([]byte("not ready\n"))
	})
	mux.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type","application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{"active_version": active})
	})
	mux.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type","text/plain; version=0.0.4")
		_,_ = w.Write([]byte(metrics.render()))
	})
	mux.HandleFunc("/notes", func(w http.ResponseWriter, r *http.Request) {
		if !ready.Load() { w.WriteHeader(503); _,_ = w.Write([]byte("not ready\n")); return }
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second); defer cancel()
		rows, err := db.QueryContext(ctx, "select id, message, created_at from notes order by id desc limit 20;")
		if err != nil { http.Error(w, "db query failed", 500); return }
		defer rows.Close()
		type note struct{ ID int `json:"id"`; Message string `json:"message"`; CreatedAt time.Time `json:"created_at"` }
		var out []note
		for rows.Next() {
			var n note
			if err := rows.Scan(&n.ID, &n.Message, &n.CreatedAt); err != nil { http.Error(w, "db scan failed", 500); return }
			out = append(out, n)
		}
		w.Header().Set("Content-Type","application/json")
		_ = json.NewEncoder(w).Encode(out)
	})

	log.Printf(`{"ts":"%s","level":"info","event":"server_start","port":%q,"active_version":%q}`,
		time.Now().UTC().Format(time.RFC3339Nano), port, active,
	)
	log.Fatal(http.ListenAndServe(":"+port, withObs(mux)))
}
