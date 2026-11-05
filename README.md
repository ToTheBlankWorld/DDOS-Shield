<div align="center">

<img src="assets/shield.svg" width="72" alt="DDOS-Shield logo" />

# DDOS-Shield

### ☁️ *The Security Operations Center that lives in your terminal*

**Autonomous Cloud DDoS Detection · Mitigation · Recovery · Tamper-Evident Audit**

<br/>

![Rust](https://img.shields.io/badge/Built_with-Rust-CE422B?style=for-the-badge&logo=rust&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux_VPS-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Tests](https://img.shields.io/badge/Tests-152_passing-2ea44f?style=for-the-badge&logo=githubactions&logoColor=white)
![Deploy](https://img.shields.io/badge/Deploy-Single_Binary-0A66C2?style=for-the-badge&logo=docker&logoColor=white)
![Stars](https://img.shields.io/github/stars/ToTheBlankWorld/DDOS-Shield?style=for-the-badge&logo=github&color=yellow)

<br/>

[Why it's different](#-why-its-different) · [Lifecycle](#-defense-lifecycle) · [Demo](#-see-it-in-action) · [Quick start](#-quick-start) · [Signals](#-the-9-detection-signals) · [Docs](#-documentation) · [Contributing](#-contributing)

</div>

---

## 🌩️ What is DDOS-Shield?

**DDOS-Shield** is a single, self-contained **Rust** binary that turns a bare Linux
cloud VPS into a **Security Operations Center in your terminal**. It combines a full
server / firewall control center with an autonomous DDoS defense pipeline that never
stops watching your traffic.

<div align="center">

```
🔭 OBSERVE → 📥 COLLECT → 🧮 NORMALIZE → 📊 BASELINE → 🧠 DETECT → 🏷️ CLASSIFY
     → 🎯 SCORE → 💬 EXPLAIN → 🛡️ MITIGATE → ✅ VERIFY → ♻️ RECOVER → ⛓️ AUDIT
```

</div>

It continuously **learns what normal looks like**, **detects abnormal patterns** with
multiple explainable signals, **classifies** the attack, **applies layered mitigation**,
**verifies** the application stays alive, **rolls back** the protections once the storm
passes, and **records every step** in a tamper-evident audit chain — with **minimal
downtime** and **zero config to get started**.

<br/>

<div align="center">

```
┌──────────────────────────────────────────────────────────────────────┐
│ $ ddos-shield ddos status                                            │
│                                                                      │
│  score       94/100  ██████████████████████████░░  CRITICAL          │
│  threat      DISTRIBUTED HTTP FLOOD                                  │
│  posture     MITIGATING · DDOS-SHIELD chain armed · 3 IPs pinned     │
│  health      HEALTHY · upstream 200s · error rate normal             │
│  baseline    learned 14m ago · FROZEN during attack                  │
│  audit       verified · head 9f2c…a41b                               │
│                                                                      │
│ $ ddos-shield audit verify                                           │
│  OK  412 events · chain intact · tamper-evident                      │
└──────────────────────────────────────────────────────────────────────┘
```

</div>

---

## ✨ Why it's different

| | Principle | What it means |
|---|---|---|
| 🧠 | **No dumb thresholds** | Verdicts are a weighted sum of **9 independent signals**. Every point carries the exact measurement behind it — never *"AI detected DDoS"* with no evidence. |
| 🎭 | **False-positive aware** | A viral flash crowd (20× traffic, but diverse & healthy) is labelled a **TRAFFIC SURGE**, *not* an attack — and is never auto-blocked. |
| ❄️ | **Attack-aware baseline** | The learning model **freezes** during an attack, so a 10-minute flood can never poison "normal". |
| 🔒 | **Reversible by design** | Every auto-rule lives in an isolated firewall chain with a **kernel TTL**. Your permanent blacklist, whitelist, fail2ban & Docker rules are **untouchable**. |
| ⏱️ | **Earned recovery** | Rollback requires a cooldown **and** multiple healthy samples **and** a falling score. One quiet second proves nothing. |
| 📐 | **Real metrics only** | Detection, mitigation, recovery & downtime times are **measured** — never hard-coded to look good. |
| ⛓️ | **Tamper-evident ledger** | Every incident event is **SHA-256 hash-chained**. Any edit, delete or reorder is detected by `ddos-shield audit verify`. |

---

## ⚡ Defense lifecycle

| Phase | What happens |
|:---:|---|
| 📊 **LEARN** | Rolling windows build an EWMA baseline of *your* traffic — per hour of day, per endpoint. |
| 🧠 **DETECT** | 9 explainable signals score every tick from `0 → 100`. Every point is evidence-backed. |
| 🛡️ **DEFEND** | Above threshold: layered mitigation into the isolated `DDOS-SHIELD` chain + `ddos_shield*` ipsets, each rule expiring on a **kernel TTL**. |
| ♻️ **RECOVER** | Cooldown + consecutive healthy samples + falling score → automatic, verified rollback. |
| ⛓️ **PROVE** | Every event hash-chained with SHA-256. The postmortem is cryptographic, not anecdotal. |

---

## 🎬 See it in action

Watch the score climb → attack classified → auto-mitigated → app stays alive → auto-recovered → audited:

<div align="center">

```
t+ 5s   score  32/100   🟡 ELEVATED
t+10s   score  58/100   🟠 SUSPICIOUS
t+15s   score  84/100   🔴 ATTACK        DISTRIBUTED HTTP FLOOD
t+20s   score  94/100   🚨 CRITICAL      DISTRIBUTED HTTP FLOOD   →  🛡️ MITIGATING
t+45s   score  41/100   🟡 ELEVATED      mitigation holding · app healthy
t+90s   score  12/100   🟢 NORMAL        ♻️ rules rolled back · ⛓️ incident sealed
```

</div>

> [!TIP]
> **Zero-risk demo.** `ddos-shield ddos simulate distributed --confirm-local-test`
> feeds *synthetic* telemetry into the engine — no real packets leave the box, and the
> rollback at the end is fully automatic. Perfect for a live demo.

```bash
ddos-shield                                # 🖥️  launch the SOC control center (TUI)
ddos-shield ddos status                    # 🎯  live risk score + threat posture
ddos-shield ddos simulate distributed \
        --confirm-local-test               # 🧪  SAFE, local-only synthetic attack
ddos-shield audit verify                   # ⛓️  verify the tamper-evident chain
```

---

## 🚀 Quick start

> [!NOTE]
> **Prerequisites** — a Linux VPS, root access, and a Rust stable toolchain
> (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`).
> `ipset` / `iptables` are programmed automatically by the installer.

```bash
git clone https://github.com/ToTheBlankWorld/DDOS-Shield.git
cd DDOS-Shield
sudo bash scripts/install.sh          # 🔨 build · install · arm the shield
ddos-shield                           # 🛡️  launch DDOS-Shield
```

Run it **always-on**, headless (no TUI needed):

```bash
sudo WITH_SERVICE=1 bash scripts/install.sh
systemctl status ddos-shield.service  # ♾️  the shield engine as a systemd service
```

Grant a teammate passwordless access (auto-elevates via sudoers):

```bash
sudo usermod -aG ddos-shield alice    # 👥  members of the 'ddos-shield' group can run it
```

---

## ⌨️ CLI reference

<details>
<summary><b>📖 Expand full command list</b></summary>

<br/>

| Command | Description |
|---|---|
| `ddos-shield` | 🖥️ Launch the full TUI control center |
| `ddos-shield status` | 🩺 Host + service + security summary |
| `ddos-shield services` | 🐳 Containers, status, domains |
| `ddos-shield ddos status [--json]` | 🎯 Live risk score, threat, posture |
| `ddos-shield ddos score` | 🔢 Just the number |
| `ddos-shield ddos top [--json]` | 📊 Top sources / endpoints / networks right now |
| `ddos-shield ddos why` | 💬 Full explainable breakdown of the current score |
| `ddos-shield ddos incidents [--json]` | 📁 Recorded incidents |
| `ddos-shield ddos incident <id>` | 🔍 One incident report |
| `ddos-shield ddos baseline` | 📊 The learned normal traffic |
| `ddos-shield ddos policy` | 📋 Detection thresholds + mitigation policy |
| `ddos-shield ddos mitigation` | 🛡️ Active automatic firewall rules |
| `ddos-shield ddos recover` | ♻️ Force rollback of automatic rules now |
| `ddos-shield ddos enable \| disable` | 🔌 Arm / disarm the enforcement path |
| `ddos-shield ddos daemon` | ⚙️ Headless engine (used by systemd) |
| `ddos-shield ddos simulate <kind>` | 🧪 Synthetic attack: `http-flood` · `distributed` · `burst` · `connection` · `internal` · `surge` |
| `ddos-shield ddos export [file]` | 📤 Export incidents + audit as JSON |
| `ddos-shield audit verify` | ⛓️ Verify the tamper-evident incident chain |
| `ddos-shield audit diagnose` | 🔬 Explain exactly why verification passes/fails |
| `ddos-shield audit migrate` | 🗄️ Seal an incompatible legacy chain, start fresh |
| `ddos-shield audit head` | 🧷 Current chain head hash |
| `ddos-shield audit log [N]` | 📜 Last N audit records |
| `ddos-shield config validate` | ✅ Check `/etc/ddos-shield/config.toml` |
| `ddos-shield config show` | 👁️ Print the effective configuration |
| `ddos-shield config init` | 📝 Write a default config if none exists |

</details>

---

## 🧠 The 9 detection signals

| Signal | ⚖️ Weight | Answers |
|--------|:---:|---------|
| 🌊 Traffic anomaly | `20` | Is the pipe (edge **or** internal bridge) carrying far more than normal? |
| 📨 Request-rate anomaly | `20` | Is the application being asked for far more? |
| 🎯 Source concentration | `15` | Is one address or `/24` network responsible? |
| 📍 Endpoint concentration | `10` | Is one resource absorbing everything? |
| 🤖 Behaviour similarity | `10` | Do many sources act like one coordinated script? |
| 🔌 Connection anomaly | `10` | Are sockets being created abnormally fast / half-open? |
| ❌ Error-rate anomaly | `5` | Is the application starting to fail? |
| 🕐 Temporal anomaly | `5` | Is this abnormal *for this hour of day*? |
| 💓 Application health | `5` | Are the protected services actually hurting? |

### 🎚️ Threat bands

| Band | Score | Gauge |
|------|:---:|---|
| 🟢 **NORMAL** | `0–29` | `███████████████···································` |
| 🟡 **ELEVATED** | `30–49` | `···············██████████·························` |
| 🟠 **SUSPICIOUS** | `50–69` | `·························██████████···············` |
| 🔴 **ATTACK** | `70–84` | `···································████████·······` |
| 🚨 **CRITICAL** | `85–100` | `···········································███████` |

---

## 💥 Attacks it detects & stops

| Attack | Vector | Verdict |
|---|---|---|
| 💥 **HTTP flood** | Single-source request storms | 🛡️ Blocked |
| 🕸️ **Distributed HTTP flood** | Thousands of coordinated sources, no single IP standing out | 🛡️ Blocked |
| 📍 **Endpoint exhaustion** | One resource hammered into the ground | 🛡️ Blocked |
| 🔌 **Connection / SYN exhaustion** | The socket table *is* the target | 🛡️ Blocked |
| ⚡ **Burst attacks** | Short, sharp spikes | 🛡️ Blocked |
| 🐳 **Internal cloud anomalies** | Container-origin floods from *inside* the infrastructure | 🛡️ Blocked |
| 🎭 **Flash crowds** | 20× legitimate traffic — diverse & healthy | ✅ **Never blocked** |

---

## 🏗️ Architecture

<div align="center">

```
                          🌍 INTERNET
                               │
                               ▼
                    🔀 Traefik (reverse proxy + access logs)
                               │
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
            🌐 Web App                     🔗 API
                 └─────────────┬─────────────┘
                          🐳 SERVICES

                         🛡️ DDOS-Shield
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
      🔭 Telemetry     🧠 Detection      💓 Health
          └────────────────┼────────────────┘
                           ▼
                   🎯 Risk Score Engine
                           ▼
                    📋 Policy Engine
                           ▼
                   🛡️ Mitigation Engine
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
       📦 ipset        🧱 iptables      ⏱️ rate/conn limit
          └────────────────┼────────────────┘
                           ▼
                   ♻️ Recovery Engine
                           ▼
                   📁 Incident Engine
                           ▼
                ⛓️ Tamper-Evident Audit
```

</div>

---

## 📂 Project layout

```
📦 DDOS-Shield
├── 🦀 ddos-shield-rs/            Rust workspace (lib + bin)
│   └── src/
│       ├── lib.rs            📚 library core (UI-free, fully tested)
│       ├── main.rs           🖥️ TUI app loop + base tabs
│       ├── ui_shield.rs      🛡️ SHIELD dashboard + active-incident screen
│       ├── config.rs         ⚙️ /etc/ddos-shield/config.toml (parse + validate)
│       ├── sha256.rs         🔐 in-tree SHA-256 (audit primitive)
│       ├── firewall.rs       🧱 permanent ipset/fail2ban (operator-owned)
│       ├── system.rs         📡 host/docker/traefik/ssh/users/IP intel
│       ├── cli.rs            ⌨️ scriptable CLI (all `ddos` commands)
│       └── shield/           🛡️ the DDoS pipeline
│           ├── telemetry.rs  🔭 /proc counters → rates
│           ├── accesslog.rs  📥 incremental Traefik log tail
│           ├── window.rs     🧮 bounded rolling windows
│           ├── baseline.rs   📊 attack-aware EWMA baseline
│           ├── detect.rs     🧠 9-signal scoring + classification
│           ├── health.rs     💓 application health correlation
│           ├── mitigate.rs   🛡️ isolated, TTL'd, reversible mitigation
│           ├── recovery.rs   ♻️ recovery state machine
│           ├── incident.rs   📁 incident records + metrics
│           ├── audit.rs      ⛓️ tamper-evident hash chain
│           ├── simulate.rs   🧪 safe, local-only attack simulator
│           └── engine.rs     ⚙️ background orchestrator
├── 📜 scripts/               install.sh · ddos-shield-firewall.sh · systemd unit
├── 📖 docs/                  architecture · DDoS · security · demo · threat model
└── 🗄️ legacy/                original prototype (kept for reference)
```

---

## 📖 Documentation

| 📄 Doc | What it covers |
|--------|----------------|
| [🏗️ ARCHITECTURE](docs/ARCHITECTURE.md) | System architecture & data flow |
| [🧠 DDOS](docs/DDOS.md) | Telemetry, baseline, signals, scoring, classification |
| [♻️ RECOVERY](docs/RECOVERY.md) | Recovery state machine, cooldown, rollback, metrics |
| [🔒 SECURITY](docs/SECURITY.md) | How DDOS-Shield protects itself |
| [⚠️ THREAT_MODEL](docs/THREAT_MODEL.md) | Threats → detection → mitigation → residual risk |
| [🎬 DEMO](docs/DEMO.md) | Step-by-step demonstration script |
| [📏 LIMITATIONS](docs/LIMITATIONS.md) | Honest protection boundary |
| [🎯 REQUIREMENTS](docs/REQUIREMENTS.md) | Requirements → features & test coverage mapping |

---

## 🧪 Build & test

```bash
cargo test              # ✅ 152 unit tests — scoring, baseline, classification,
                        #    mitigation, recovery, audit chain, config & more
cargo build --release   # 🦀 build the ddos-shield binary
cargo clippy            # 🧹 lint clean
cargo fmt               # ✨ rustfmt-formatted
```

---

## 📏 Protection boundary (the honest bit)

> [!IMPORTANT]
> DDOS-Shield protects the **host, application, reverse proxy, services & internal
> cloud traffic** on a single VPS — HTTP floods, distributed floods,
> endpoint/connection exhaustion, burst & internal-origin attacks — keeping the
> app alive throughout.

> [!WARNING]
> It **cannot** absorb an **upstream-link-saturating** volumetric flood — no single
> VPS can. For that, the cloud/ISP provider must supply upstream scrubbing.
> DDOS-Shield is the host-and-application guard **behind** that layer.
> See [LIMITATIONS.md](docs/LIMITATIONS.md).

---

## 🤝 Contributing

Contributions are welcome! 🎉

```bash
git checkout -b feat/your-feature      # 🌿 branch
cargo fmt && cargo clippy              # 🧹 keep it clean
cargo test                             # ✅ keep 152 passing
git commit -m "feat: your feature"     # 📌 conventional commits
```

Then open a Pull Request — describe **what** changed and **why**. For security
issues, please don't open a public issue; disclose responsibly. 🔐

---

<div align="center">

### 🛡️ DDOS-Shield — *observe · learn · detect · explain · mitigate · recover · audit*

**Autonomous. Explainable. Reversible. Auditable.**

<br/>

⭐ **Star this repo if DDOS-Shield guards your cloud** ⭐

*Made with 🦀 and too much ☕ — because your traffic never sleeps, and neither does the shield.*

</div>
