# 🛡️ CrudePayloadGuard

> PowerShell script that monitors **active TCP connections** for hostnames containing `"xss"` — crude XSS/injection payload guard.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔍 **Connection Monitor** | Scans `Get-NetTCPConnection -State Established` |
| 🚫 **XSS Hostnames** | Flags connections where hostname contains `xss` |
| 🔥 **Auto-Block** | Disables adapter, blocks IP via firewall |
| ⚡ **Loop** | Continuous monitoring |

---

## 📋 Requirements

| Requirement | Details |
|-------------|---------|
| **OS** | Windows 10/11 |
| **PowerShell** | 5.1+ |
| **Privileges** | Administrator (for firewall and adapter) |

---

## 🚀 Usage

```powershell
# Run as Administrator
.\CrudePayloadGuard.ps1
```

---

## ⚠️ Note

This is a simple heuristic guard. Hostnames containing "xss" are rare; adjust logic for your use case. Part of the Gorstak EDR/security toolkit.

---

<p align="center">
  <sub>🛡️ Gorstak Security Tooling</sub>
</p>
