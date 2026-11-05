# DDOS-Shield — Architecture

## 1. Problem

DDOS-Shield is a DDoS protection system for cloud infrastructure that detects
suspicious traffic (from single sources, ranges, or coordinated distributed
sources), protects against it automatically, recovers automatically, maintains
high availability, and keeps a trustworthy, tamper-evident security record.

## 2. Shape of the solution

One Rust binary on a Linux VPS. It keeps the original control-center
functionality (host, Docker/Traefik, SSH, users, permanent firewall, IP
intelligence) and adds **DDOS-Shield**, a background pipeline that never
blocks the UI.

```
                    INTERNET
                       │
                       ▼
              Traffic / Edge Intelligence
                       │
                       ▼
                    Traefik  (reverse proxy, access logs)
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
       Web Application           API
            └──────────┬──────────┘
                    SERVICES (Docker)

                  DDOS-Shield
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   Telemetry       Detection       Health
    Engine          Engine         Monitor
        └──────────────┼──────────────┘
                       ▼
                 Risk Score Engine   (explainable, 9 signals)
                       ▼
                  Policy Engine      (threat band → level)
                       ▼
               Mitigation Engine
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
      ipset        iptables      rate/conn limit
        └──────────────┼──────────────┘
                       ▼
                Recovery Engine      (cooldown, health-verified rollback)
                       ▼
                Incident Engine
                       ▼
             Tamper-Evident Audit    (SHA-256 hash chain)
```

## 3. Threading & responsiveness

The TUI render loop never performs an expensive operation. Two background
mechanisms feed it:

- **System snapshot** (`main.rs::gather`) — host/docker/ssh/users/IP registry,
  fanned out across threads, polled non-blocking. Unchanged from the original
  design; the IP registry is still parsed incrementally by file offset.
- **Shield engine** (`shield::engine`) — owns all mutable shield state on its
  own thread, publishes an immutable `ShieldSnapshot` behind an
  `Arc<Mutex<…>>`. The UI/CLI only *read* that snapshot, so a firewall call can
  never happen on the render path, and the render path can never touch the
  firewall.

The engine ticks every `sample_interval_secs` (default 5). Each tick:

1. reads `/proc` counters → derives rates (no subprocess);
2. reads new Traefik access-log lines from a saved byte offset (never rescans);
3. folds them into bounded rolling windows;
4. probes application health on a slower cadence;
5. runs the detector → score, threat, attack type, explanation;
6. updates the baseline (skipped while the score is high);
7. drives the recovery state machine, which emits mitigation/rollback actions;
8. prunes expired rules;
9. appends any state changes to the audit chain;
10. publishes a fresh snapshot.

## 4. Data flow, stage by stage

| Stage | Module | Output |
|-------|--------|--------|
| OBSERVE / COLLECT | `telemetry`, `accesslog` | raw counters, parsed requests |
| NORMALIZE | `window` | bounded per-tick aggregates + rolling views |
| BASELINE | `baseline` | EWMA mean/variance per metric, hourly profile |
| DETECT / SCORE / EXPLAIN | `detect` | `Assessment` (score, signals, reasons) |
| CLASSIFY | `detect::classify` | `AttackType` |
| MITIGATE | `mitigate` | isolated, TTL'd firewall rules |
| VERIFY | `health` | per-service state, measured downtime |
| RECOVER | `recovery` | state machine + rollback |
| AUDIT | `audit`, `incident` | hash-chained incident ledger |

## 5. State on disk

```
/etc/ddos-shield/config.toml           configuration (validated, self-documenting)
/etc/ddos-shield/whitelist.txt         protected addresses (never auto-blocked)
/etc/ddos-shield/blacklist.save        permanent ipset save
/var/lib/ddos-shield/ips.json          IP intelligence registry (+ log offsets)
/var/lib/ddos-shield/ddos/baseline.json    learned normal traffic
/var/lib/ddos-shield/ddos/active_rules.json automatic mitigation rules (with TTL)
/var/lib/ddos-shield/ddos/incidents.json    incident records
/var/lib/ddos-shield/audit/chain.jsonl      tamper-evident audit chain
```

All writes are atomic (temp file + rename). Corrupt state is rejected and
rebuilt rather than trusted (a corrupt baseline would silently suppress
detection, so it is discarded).

## 6. Isolation of automatic mitigation

The permanent, operator-owned firewall (`ddos_shield_blacklist` ipset + the
`ddos-shield-firewall.sh` INPUT/DOCKER-USER rules, plus fail2ban) and the automatic
DDoS mitigation (`ddos_shield` / `ddos_shield_net` ipsets in the
`DDOS-SHIELD` chain) are completely separate structures. Rolling back an
incident flushes only what DDOS-Shield owns. A failed or half-applied mitigation
therefore cannot damage permanent state, and the two layers can be reasoned
about independently.

## 7. Why not more infrastructure

No Kafka, Elasticsearch, Kubernetes, external database, or ML runtime. The
detector is explainable statistics over bounded windows; the audit chain is
SHA-256 in-tree. The whole system is one static binary that runs in a few MB of
RAM, which is what a VPS-resident guard needs to be. See
[DDOS.md](DDOS.md) for the detection detail and
[LIMITATIONS.md](LIMITATIONS.md) for the boundary.
