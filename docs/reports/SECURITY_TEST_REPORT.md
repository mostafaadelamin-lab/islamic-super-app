# Security test report — Milestone 1

Automated checks only. **They do not replace a specialist security review**, which has not been done.

## Automated results
| Check | Tool | Scope | Result | Evidence |
|---|---|---|---|---|
| Python dependency CVEs | pip-audit | services/api/requirements.txt | 0 known vulnerabilities (after DEF-004 upgrade) | CI `backend` job |
| Python static analysis | ruff `S` (bandit rules) + bandit 1.x | services/api/app | 0 findings | tests/evidence/security/bandit-backend.json |
| Multi-language SAST | Semgrep (p/default, p/python, p/typescript, p/secrets) | repo (excl. content, evidence) | first CI run: 23 findings, all supply-chain (mutable action tags, Dependabot cooldown) → fixed (DEF-007) | CI `security` job |
| Secret scanning | gitleaks (CI, full history) | repo | PASS (0 leaks) | CI `secrets` job |
| Secret scanning | detect-secrets (local, all files) | repo | only false positives: content hashes, the word "password" in UI strings, test passwords | tests/evidence/security/detect-secrets.json |
| npm dependency audit | `npm audit --omit=dev --audit-level=high` | apps/web | CI `web` job | CI |
| Dependency updates | Dependabot | pip, npm, pub, actions | enabled with 7-day cooldown | .github/dependabot.yml |

## Security acceptance scenarios (backend, all executed — pytest)
| Scenario | Test | Result |
|---|---|---|
| Passwords stored as Argon2id, never plaintext | test_password_is_hashed_not_stored | PASS |
| Wrong password / unknown user → 401, same message | test_login_wrong_password_and_unknown_user | PASS |
| Missing/garbage/Basic auth header → 401/403 | test_me_requires_valid_token (4 cases) | PASS |
| Token signed with another secret rejected | test_token_signed_with_other_secret_rejected | PASS |
| Expired token rejected | test_expired_token_rejected | PASS |
| `alg=none` token rejected | test_alg_none_rejected | PASS |
| Token for non-existent user rejected | test_token_for_deleted_user_rejected | PASS |
| User A cannot read/overwrite user B's bookmarks (IDOR) | test_users_cannot_see_or_overwrite_each_others_bookmarks | PASS |
| Mass-assignment / extra fields rejected | test_register_validation, test_bookmark_validation | PASS |
| Input validation (ranges, ids, sizes) | test_bookmark_validation (9), test_prayer_times_validation (6), search validation | PASS |
| Settings payload size cap (413) | test_settings_size_limit | PASS |
| Brute-force: auth 10/min/IP → 429 | test_auth_endpoints_rate_limited | PASS |
| General rate limit → 429 | test_general_rate_limit | PASS |
| Security headers (nosniff, DENY, no-referrer, no-store on private routes) | test_security_headers_and_cors | PASS |
| CORS allow-list (foreign origin gets no ACAO) | test_security_headers_and_cors | PASS |
| Cascade delete removes user data | test_cascade_delete_user_removes_bookmarks | PASS |

## Client-side
- Web: no third-party scripts, fonts self-hosted, no analytics; all storage access wrapped; Lighthouse best-practices 100.
- Mobile: cleartext HTTP allowed only to 10.0.2.2/localhost (development API).

## Open risks (must be closed before a public release)
1. Mobile token in shared_preferences → move to flutter_secure_storage (Keychain/Keystore). 
2. Release signing keys and store accounts (owner's decision; Apple developer account costs USD 99/year — **needs owner approval**).
3. Production JWT secret management and HTTPS deployment (no deployment exists yet).
4. Shared rate-limit store for multi-instance deployments.
5. OWASP ZAP dynamic scan: not run (no deployed environment) — **NOT TESTED**.
6. Specialist security review: **NOT DONE**.
