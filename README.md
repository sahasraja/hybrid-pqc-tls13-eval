# hybrid-pqc-tls13-eval

Reproducible evaluation of hybrid post-quantum key exchange (X25519MLKEM768) in TLS 1.3 with OpenSSL 3.5: scripts, data, and packet captures.

**Paper:** *Drop-In Hybrid Post-Quantum Key Exchange for TLS 1.3 at Zero Trust Boundaries: Architecture, Functional Validation, and an Open Evaluation Agenda* ([PDF](paper/Hybrid_PQC_TLS13_Zero_Trust_Paper.pdf))
**Author:** Raj Sahasranamam, Nila Professional Services ([ORCID 0009-0001-4855-6601](https://orcid.org/0009-0001-4855-6601))
**Archive DOI:** assigned by Zenodo on first release

## What this is

Adversaries can record encrypted traffic today and decrypt it once a large quantum computer exists ("harvest now, decrypt later"). The fix for TLS 1.3 is to change **only the key exchange**: replace classical ECDHE with the hybrid group **X25519MLKEM768** (X25519 combined with NIST's ML-KEM-768, specified in RFC 10024). Applications, certificates and cipher suites stay unchanged.

With OpenSSL 3.5, hybrid is already offered by default. Upgrading the library does most of the work; the `-groups` setting **enforces** the hybrid group and makes it auditable.

## Status and scope

- **Validated:** functional handshake on Windows 11 Pro, single host, loopback, OpenSSL 3.5 series. Evidence is in [`evidence/`](evidence).
- **Not measured:** performance, cross-host, Linux, or middlebox behavior.
- **Proposed, not tested:** quantum random number generator (QRNG) entropy integration and Ising/QUBO optimization. See Section VI of the paper.

## Quick start

Check that your OpenSSL build supports ML-KEM:

```powershell
# Windows
.\scripts\windows\check-pqc.ps1
```
```bash
# Linux
bash scripts/linux/check-pqc.sh
```

Run the server and client in two terminals:

```powershell
# Windows
.\scripts\windows\server.ps1
.\scripts\windows\client.ps1
```
```bash
# Linux
bash scripts/linux/server.sh
bash scripts/linux/client.sh
```

Expected result:

```
RESULT: Negotiated TLS1.3 group: X25519MLKEM768
```

If Windows blocks the scripts, run them with `powershell -ExecutionPolicy Bypass -File <script>`.

Options: test another group with `-Group SecP384r1MLKEM1024` (Windows) or `bash scripts/linux/client.sh 127.0.0.1 4433 SecP384r1MLKEM1024` (Linux). Use `default` as the group to see what OpenSSL negotiates without any group setting. Run `cleanup` when done.

## Repository layout

| Folder | Contents |
|---|---|
| [`paper/`](paper) | Paper PDF and LaTeX source |
| [`scripts/`](scripts) | Windows (PowerShell) and Linux (bash) check, server, client and cleanup scripts |
| [`evidence/`](evidence) | Redacted screenshots and the KEM algorithm listing from the validation |
| [`docs/`](docs) | Developer playbook, the Path B procedure used for validation, and the untested FIPS provider variant |

## Contribute measurements

The paper's **open evaluation agenda** (Section VII) lists the tests that remain: handshake latency (p50/p95/p99), bytes on the wire, TCP segmentation, CPU cost, throughput, WAN emulation, and behavior through TLS-inspecting proxies. It also sets out five testable hypotheses (H1 to H5).

Results are welcome as pull requests or issues. Please include the OpenSSL version and build options, OS, hardware, network conditions, and raw per-handshake data.

## How to cite

Use the **"Cite this repository"** button on GitHub (generated from [`CITATION.cff`](CITATION.cff)), or cite the Zenodo DOI once it is assigned.

## License

Code: MIT ([LICENSE](LICENSE)). Paper and documentation: CC BY 4.0.
