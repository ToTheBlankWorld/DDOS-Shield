# DDOS-Shield — SIH Demonstration Script

Every command below actually exists. The simulator injects **synthetic
telemetry into the local detector only** — it never sends traffic to anyone, and
every simulated incident is flagged `[SIMULATION]` end to end.

## 0. Setup (once, on the VPS as root)

```bash
cd ddos-shield
sudo bash scripts/install.sh
```

This builds the binary, installs it at `/usr/local/bin/ddos-shield`, migrates any
legacy AVNI state, seeds `/etc/ddos-shield/config.toml`, and arms the enforcement
path (`ddos_shield` ipset + `DDOS-SHIELD` chain).

> Let the shield collect a baseline for a minute or two before demoing, so
> `ddos-shield ddos status` shows `baseline: warm`. On a fresh box it will say
> `baseline: learning (NN%)` — that is expected.

---

## The story (12 steps)

### 1 — Start the control center

```bash
ddos-shield
```

The splash reads **DDOS-Shield — CLOUD SECURITY CONTROL CENTER — DDOS-Shield**.
Press `2` for the **Shield** tab.

### 2 — Show the healthy baseline

Shield dashboard shows `● PROTECTED`, a low **DDOS SCORE**, `THREAT NORMAL`,
live request/bandwidth/connection/risk graphs, top sources, mitigation readiness
and per-service health. Everything is measured from the real box.

```bash
ddos-shield ddos status
ddos-shield ddos baseline      # the learned "normal"
```

### 3 — Start a controlled local simulation

From the Shield tab press `h` (HTTP flood), `D` (distributed — asks to confirm),
`b` (burst), `c` (connection), `i` (internal), or `f` (flash-crowd surge).
Or from the CLI:

```bash
ddos-shield ddos simulate distributed --confirm-local-test --duration 45
```

A banner appears: **⚠ SIMULATION ACTIVE — synthetic telemetry, no real traffic**.

### 4 — Watch the score climb

The risk score ramps through the bands, live:

```
t+ 5s  score  32/100  ELEVATED    ...
t+10s  score  58/100  SUSPICIOUS  ...
t+15s  score  84/100  ATTACK      DISTRIBUTED HTTP FLOOD  UNDER ATTACK
t+20s  score  94/100  CRITICAL    DISTRIBUTED HTTP FLOOD  UNDER ATTACK
```

### 5 — DDOS-Shield explains the attack

The tab flips to the **ACTIVE INCIDENT** screen with the incident id
(`DDOS-SHIELD-YYYYMMDD-NNNN`) and a **WHY DETECTED** panel — each line a real
measurement:

```
+ Traffic anomaly (+20) — inbound 60.0 Mbps vs 2.0 Mbps baseline (30.0x) ...
+ Request-rate anomaly (+20) — 1500 req/s vs 10.0 baseline (150.0x) ...
+ Endpoint concentration (+10) — /api/search receives 98% of all requests
+ Behaviour similarity (+9) — 91% of sources share the busiest endpoint ...
+ Connection anomaly (+10) — 120 new conn/s vs 4.0 baseline (30.0x)
```

```bash
ddos-shield ddos why           # same explanation on the CLI
ddos-shield ddos top           # top sources / endpoints / networks right now
```

### 6 — Automatic mitigation engages

The MITIGATION panel lights up (rate limiting, IP filtering, connection guard,
Docker protection) with the level and the count of blocked sources.

```bash
ddos-shield ddos mitigation    # the actual TTL'd rules, with incident id + reason
```

(Real ipset/iptables rules in the `DDOS-SHIELD` chain — verify with
`ipset list ddos_shield` and `iptables -S DDOS-SHIELD`.)

### 7 — Application stays available

The IMPACT panel shows measured downtime. Because mitigation shed the flood, the
protected services keep answering — the SIH-metrics strip shows `downtime 0s` (or
the real measured value if the app did degrade).

### 8 — The attack stops

The simulator stops on its own ~2/3 through (`--- attack stopped ---`), or press
`x` in the Shield tab.

### 9 — Cooldown

State moves to `RECOVERY_PENDING`. DDOS-Shield does **not** roll back yet — it waits
for the cooldown and healthy samples.

### 10 — Automatic recovery

After the cooldown and several consecutive healthy samples, the machine rolls
back every automatic rule (`RECOVERING → HEALTH_VERIFICATION → NORMAL`). Verify
the chain is clean:

```bash
ddos-shield ddos mitigation    # now empty
ipset list ddos_shield    # drained
```

### 11 — Incident report

```bash
ddos-shield ddos incidents
ddos-shield ddos incident DDOS-SHIELD-YYYYMMDD-0001
```

Shows attack type, peak score, sources/networks, target endpoint, and the
**measured** metrics: detection time, mitigation time, recovery time, downtime,
availability, plus the full timeline.

### 12 — Audit the record

```bash
ddos-shield audit verify       # ✓ audit chain VERIFIED — N records intact
ddos-shield audit log 10       # the chained security events
```

To demonstrate tamper-evidence, edit any line in
`/var/lib/ddos-shield/audit/chain.jsonl` and re-run `ddos-shield audit verify` — it
reports `✗ audit chain TAMPERED` and names the first broken record.

---

## The one-line pitch to the judges

> DDOS-Shield continuously observes cloud traffic, learns normal behaviour, detects
> abnormal patterns using multiple signals, classifies potential DDoS attacks,
> automatically applies layered mitigation, verifies application health, removes
> the temporary protections after the attack, records the incident in a
> tamper-evident audit chain, and returns the infrastructure to a healthy state
> with minimal downtime.

## Scenarios worth showing

| Command | Point it makes |
|---------|----------------|
| `simulate http-flood` | single-source detection + blocking |
| `simulate distributed` | coordination detection where no single IP stands out |
| `simulate burst` | short-spike detection |
| `simulate connection` | L4 SYN/connection exhaustion without HTTP |
| `simulate internal` | container-origin (internal cloud) anomaly |
| `simulate surge` | **flash crowd is NOT called an attack** (false-positive protection) |
