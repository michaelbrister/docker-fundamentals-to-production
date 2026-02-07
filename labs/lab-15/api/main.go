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
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	_ "github.com/lib/pq"
)

// ----------------------------
// Structured logger (JSON lines)
// ----------------------------

type Level string

const (
	Debug Level = "debug"
	Info  Level = "info"
	Warn  Level = "warn"
	Error Level = "error"
)

func parseLevel(s string) Level {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "debug":
		return Debug
	case "info", "":
		return Info
	case "warn", "warning":
		return Warn
	case "error":
		return Error
	default:
		return Info
	}
}

type Logger struct {
	level Level
}

func (l Logger) enabled(level Level) bool {
	order := map[Level]int{Debug: 10, Info: 20, Warn: 30, Error: 40}
	return order[level] >= order[l.level]
}

func (l Logger) log(level Level, event string, fields map[string]any) {
	if !l.enabled(level) {
		return
	}
	rec := map[string]any{
		"ts":    time.Now().UTC().Format(time.RFC3339Nano),
		"level": level,
		"event": event,
	}
	for k, v := range fields {
		rec[k] = v
	}
	b, _ := json.Marshal(rec)
	log.Print(string(b))
}

func (l Logger) Debug(event string, f map[string]any) { l.log(Debug, event, f) }
func (l Logger) Info(event string, f map[string]any)  { l.log(Info, event, f) }
func (l Logger) Warn(event string, f map[string]any)  { l.log(Warn, event, f) }
func (l Logger) Error(event string, f map[string]any) { l.log(Error, event, f) }

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
	return strings.TrimSpace(string(b)), nil
}

// ----------------------------
// Minimal metrics (Prometheus text format)
// ----------------------------

type counter struct{ v atomic.Int64 }

func (c *counter) inc()          { c.v.Add(1) }
func (c *counter) add(n int64)   { c.v.Add(n) }
func (c *counter) load() int64   { return c.v.Load() }
func newCounter() *counter       { return &counter{} }
func nowMs() int64               { return time.Now().UnixMilli() }

type durationMetric struct {
	mu    sync.Mutex
	count int64
	sumMs float64
}

func (d *durationMetric) observe(ms float64) {
	d.mu.Lock()
	d.count++
	d.sumMs += ms
	d.mu.Unlock()
}
func (d *durationMetric) snapshot() (count int64, sumMs float64) {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.count, d.sumMs
}

type httpKey struct {
	method string
	path   string
	status int
}

type Metrics struct {
	startedAt            int64
	httpRequests         map[httpKey]*counter
	httpErrors           *counter
	httpDurationMs       *durationMetric
	dbPingFailures       *counter
	mu                   sync.Mutex
}

func NewMetrics() *Metrics {
	return &Metrics{
		startedAt:      nowMs(),
		httpRequests:   make(map[httpKey]*counter),
		httpErrors:     newCounter(),
		httpDurationMs: &durationMetric{},
		dbPingFailures: newCounter(),
	}
}

func (m *Metrics) incRequest(method, path string, status int) {
	m.mu.Lock()
	defer m.mu.Unlock()
	k := httpKey{method: method, path: path, status: status}
	c, ok := m.httpRequests[k]
	if !ok {
		c = newCounter()
		m.httpRequests[k] = c
	}
	c.inc()
}

func (m *Metrics) observeDuration(ms float64) {
	// clamp negative
	if ms < 0 {
		ms = 0
	}
	// clamp huge values to avoid nonsense in beginners' experiments
	ms = math.Min(ms, 600000)
	m.httpDurationMs.observe(ms)
}

func (m *Metrics) render() string {
	uptime := float64(nowMs()-m.startedAt) / 1000.0

	var b strings.Builder
	b.WriteString("# HELP process_uptime_seconds Process uptime in seconds\n")
	b.WriteString("# TYPE process_uptime_seconds gauge\n")
	b.WriteString(fmt.Sprintf("process_uptime_seconds %.3f\n", uptime))

	b.WriteString("# HELP http_requests_total Total HTTP requests by method/path/status\n")
	b.WriteString("# TYPE http_requests_total counter\n")

	m.mu.Lock()
	keys := make([]httpKey, 0, len(m.httpRequests))
	for k := range m.httpRequests {
		keys = append(keys, k)
	}
	// stable-ish ordering
	m.mu.Unlock()

	// print in deterministic order
	for i := 0; i < len(keys); i++ {
		for j := i + 1; j < len(keys); j++ {
			if keys[j].path < keys[i].path ||
				(keys[j].path == keys[i].path && keys[j].method < keys[i].method) ||
				(keys[j].path == keys[i].path && keys[j].method == keys[i].method && keys[j].status < keys[i].status) {
				keys[i], keys[j] = keys[j], keys[i]
			}
		}
	}

	m.mu.Lock()
	for _, k := range keys {
		b.WriteString(fmt.Sprintf(
			"http_requests_total{method=%q,path=%q,status=%q} %d\n",
			k.method, k.path, fmt.Sprintf("%d", k.status), m.httpRequests[k].load(),
		))
	}
	m.mu.Unlock()

	b.WriteString("# HELP http_errors_total Total HTTP responses with 5xx status\n")
	b.WriteString("# TYPE http_errors_total counter\n")
	b.WriteString(fmt.Sprintf("http_errors_total %d\n", m.httpErrors.load()))

	b.WriteString("# HELP http_request_duration_ms Request duration (count, sum)\n")
	b.WriteString("# TYPE http_request_duration_ms summary\n")
	cnt, sum := m.httpDurationMs.snapshot()
	b.WriteString(fmt.Sprintf("http_request_duration_ms_count %d\n", cnt))
	b.WriteString(fmt.Sprintf("http_request_duration_ms_sum %.3f\n", sum))

	b.WriteString("# HELP db_ping_failures_total Total DB ping failures (readiness)\n")
	b.WriteString("# TYPE db_ping_failures_total counter\n")
	b.WriteString(fmt.Sprintf("db_ping_failures_total %d\n", m.dbPingFailures.load()))

	return b.String()
}

// ----------------------------
// App
// ----------------------------

type Note struct {
	ID        int       `json:"id"`
	Message   string    `json:"message"`
	CreatedAt time.Time `json:"created_at"`
}

func main() {
	port := env("PORT", "8080")
	appEnv := env("APP_ENV", "dev")
	logLevel := parseLevel(env("LOG_LEVEL", "info"))
	simLatencyMs, _ := strconv.Atoi(env("SIMULATE_LATENCY_MS", "0"))
	if simLatencyMs < 0 {
		simLatencyMs = 0
	}
	if simLatencyMs > 5000 {
		simLatencyMs = 5000
	}

	logger := Logger{level: logLevel}
	metrics := NewMetrics()

	dbHost := env("DB_HOST", "")
	dbPort := env("DB_PORT", "5432")
	dbName := env("DB_NAME", "")
	dbUser := env("DB_USER", "")

	dbPass := os.Getenv("DB_PASSWORD")
	dbPassFile := os.Getenv("DB_PASSWORD_FILE")
	if dbPass == "" && dbPassFile != "" {
		if v, err := readSecretFromFile(dbPassFile); err == nil {
			dbPass = v
		} else {
			log.Fatalf("failed to read DB_PASSWORD_FILE: %v", err)
		}
	}

	// Strict: required settings must be present
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

	// Log config keys only (never secret values)
	logger.Info("config_loaded", map[string]any{
		"app_env":  appEnv,
		"log_lvl":  logLevel,
		"port":     port,
		"db_host":  dbHost,
		"db_port":  dbPort,
		"db_name":  dbName,
		"db_user":  dbUser,
		"secrets":  "db_password=[REDACTED]",
		"latency_ms_inject": simLatencyMs,
	})

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
			metrics.dbPingFailures.inc()
			ready.Store(false)
			readyMsg.Store("not ready: db ping failed")
			logger.Warn("db_not_ready", map[string]any{"err": err.Error()})
			return
		}

		var reg sql.NullString
		if err := db.QueryRowContext(ctx, "select to_regclass('public.notes');").Scan(&reg); err != nil {
			ready.Store(false)
			readyMsg.Store("not ready: schema check failed")
			logger.Warn("schema_check_failed", map[string]any{"err": err.Error()})
			return
		}
		if !reg.Valid {
			ready.Store(false)
			readyMsg.Store("not ready: schema missing (table notes not found)")
			logger.Warn("schema_missing", map[string]any{})
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

	withObs := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			// Optional: inject latency so learners can see metrics change.
			if simLatencyMs > 0 {
				time.Sleep(time.Duration(simLatencyMs) * time.Millisecond)
			}

			// capture status
			rr := &respRec{ResponseWriter: w, status: 200}
			next.ServeHTTP(rr, r)

			durMs := float64(time.Since(start).Milliseconds())
			path := demonstratePath(r.URL.Path)
			metrics.incRequest(r.Method, path, rr.status)
			metrics.observeDuration(durMs)
			if rr.status >= 500 {
				metrics.httpErrors.inc()
			}

			logger.Info("http_request", map[string]any{
				"method":      r.Method,
				"path":        path,
				"status":      rr.status,
				"duration_ms": durMs,
			})
		})
	}

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

	mux.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; version=0.0.4")
		_, _ = w.Write([]byte(metrics.render()))
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
				http.Error(w, "db query failed", http.StatusInternalServerError)
				logger.Error("db_query_failed", map[string]any{"err": err.Error()})
				return
			}
			defer rows.Close()

			var notes []Note
			for rows.Next() {
				var n Note
				if err := rows.Scan(&n.ID, &n.Message, &n.CreatedAt); err != nil {
					http.Error(w, "db scan failed", http.StatusInternalServerError)
					logger.Error("db_scan_failed", map[string]any{"err": err.Error()})
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
				http.Error(w, "db insert failed", http.StatusInternalServerError)
				logger.Error("db_insert_failed", map[string]any{"err": err.Error()})
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
	logger.Info("server_start", map[string]any{"addr": addr})
	log.Fatal(http.ListenAndServe(addr, withObs(mux)))
}

type respRec struct {
	http.ResponseWriter
	status int
}

func (r *respRec) WriteHeader(statusCode int) {
	r.status = statusCode
	r.ResponseWriter.WriteHeader(statusCode)
}

// demonstratePath reduces cardinality for beginner metrics: we only emit known paths.
func demonstratePath(p string) string {
	switch p {
	case "/healthz", "/readyz", "/notes", "/metrics":
		return p
	default:
		return "/other"
	}
}
