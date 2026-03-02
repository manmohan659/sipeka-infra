#!/bin/bash
set -e

HOST=${1:-localhost}
MAX_RETRIES=5
RETRY_DELAY=10

echo "=== SiPeKa Smoke Tests ==="
echo "Target: $HOST"
echo ""

pass=0
fail=0

run_test() {
    local name="$1"
    local url="$2"
    local expected_code="$3"

    for i in $(seq 1 $MAX_RETRIES); do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")

        if [ "$HTTP_CODE" = "$expected_code" ]; then
            echo "[PASS] $name (HTTP $HTTP_CODE)"
            pass=$((pass + 1))
            return 0
        fi

        if [ $i -lt $MAX_RETRIES ]; then
            echo "[RETRY $i/$MAX_RETRIES] $name - got $HTTP_CODE, expected $expected_code"
            sleep $RETRY_DELAY
        fi
    done

    echo "[FAIL] $name - expected $expected_code, got $HTTP_CODE"
    fail=$((fail + 1))
    return 1
}

# Backend health check
run_test "Backend Health" "http://$HOST:5000/health" "200"

# Backend returns JSON
HEALTH_RESP=$(curl -s "http://$HOST:5000/health" 2>/dev/null || echo "{}")
if echo "$HEALTH_RESP" | grep -q '"status":"ok"'; then
    echo "[PASS] Health response contains status:ok"
    pass=$((pass + 1))
else
    echo "[FAIL] Health response missing status:ok"
    fail=$((fail + 1))
fi

# Frontend serves HTML
run_test "Frontend Loading" "http://$HOST" "200"

# Auth endpoint reachable (401 is expected without session)
run_test "Auth Endpoint (/me)" "http://$HOST:5000/me" "401"

# Static assets
FRONTEND_RESP=$(curl -s "http://$HOST" 2>/dev/null || echo "")
if echo "$FRONTEND_RESP" | grep -q "<!DOCTYPE html>"; then
    echo "[PASS] Frontend returns HTML document"
    pass=$((pass + 1))
else
    echo "[FAIL] Frontend does not return HTML"
    fail=$((fail + 1))
fi

echo ""
echo "=== Results: $pass passed, $fail failed ==="

if [ $fail -gt 0 ]; then
    exit 1
fi

echo "All smoke tests passed!"
exit 0
