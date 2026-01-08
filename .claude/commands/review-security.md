# /review-security - Security-Focused Code Review

You are a security auditor reviewing code for vulnerabilities. Focus exclusively on security issues.

## Target
$ARGUMENTS

If no files specified, scan the entire codebase for security issues.

## Security Checks

### 1. Secrets & Credentials
```bash
# Search for potential secrets
grep -rn "api[_-]?key" --include="*.dart" --include="*.swift" --include="*.kt"
grep -rn "password" --include="*.dart" --include="*.swift" --include="*.kt"
grep -rn "secret" --include="*.dart" --include="*.swift" --include="*.kt"
grep -rn "token" --include="*.dart" --include="*.swift" --include="*.kt"
```

Check:
- [ ] No hardcoded API keys
- [ ] No hardcoded passwords
- [ ] Secrets in environment variables or secure storage
- [ ] .env files in .gitignore

### 2. Data Storage
- [ ] Sensitive data encrypted at rest
- [ ] No PII in logs
- [ ] Secure storage for tokens (Keychain/Keystore)
- [ ] SharedPreferences only for non-sensitive data

### 3. Network Security
- [ ] HTTPS enforced
- [ ] Certificate pinning (if applicable)
- [ ] No sensitive data in URLs
- [ ] Proper SSL/TLS configuration

### 4. Authentication & Authorization
- [ ] Token expiration handled
- [ ] Refresh token rotation
- [ ] Proper logout (clear all tokens)
- [ ] Session management

### 5. Input Validation
- [ ] User input sanitized
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention
- [ ] Path traversal prevention

### 6. Platform-Specific

#### iOS
- [ ] App Transport Security configured
- [ ] Keychain access groups correct
- [ ] Data protection entitlements

#### Android
- [ ] Network security config
- [ ] Backup rules (no sensitive data backup)
- [ ] ProGuard obfuscation

## Output Format

```markdown
# Security Audit Report

**Scan Date**: [timestamp]
**Scope**: [files/directories scanned]

## Critical Vulnerabilities (Immediate Action Required)
| ID | Location | Vulnerability | Risk | Remediation |
|----|----------|---------------|------|-------------|

## High Risk Issues
| ID | Location | Issue | Risk | Remediation |
|----|----------|-------|------|-------------|

## Medium Risk Issues
| ID | Location | Issue | Risk | Remediation |
|----|----------|-------|------|-------------|

## Low Risk / Informational
| ID | Location | Issue | Note |
|----|----------|-------|------|

## Compliance Checklist
- [ ] OWASP Mobile Top 10 addressed
- [ ] No hardcoded secrets
- [ ] Secure data storage
- [ ] Network security

## Recommendations
1. [Priority recommendations]
```

## Execute Security Scan
