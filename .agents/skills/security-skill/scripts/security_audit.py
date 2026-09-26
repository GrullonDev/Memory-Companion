#!/usr/bin/env python3
"""
Security audit script for Memory Arcade.
Checks common security issues in the project.

Usage:
    python .agents/skills/security-skill/scripts/security_audit.py [--project ROOT] [--json] [--output FILE]

Findings are pattern matches: leads to confirm by reading the code, not
verdicts. Section letters (A-K) refer to SKILL.md.
"""

import json
import re
import argparse
import sys
from pathlib import Path
from datetime import datetime, timezone

# ── Configuration ──────────────────────────────────────────────

# <root>/.agents/skills/security-skill/scripts/security_audit.py
PROJECT_ROOT = Path(__file__).resolve().parents[4]

SCANNED_EXTENSIONS = [".dart", ".yaml", ".xml", ".plist", ".rules", ".kts", ".gradle"]

# Generated, vendored or tool directories: never project source.
SKIPPED_DIRS = {".dart_tool", ".fvm", "build", ".git", "Pods", "node_modules", ".gradle", ".idea"}

# Firebase client config is public by design (SKILL.md, K); its apiKey is
# not a secret, so these files are not scanned for secrets.
PUBLIC_CONFIG_FILES = {"firebase_options.dart", "google-services.json", "GoogleService-Info.plist"}

SECURITY_PATTERNS = {
    "hardcoded_secrets": {
        # Whole words only: `authErrorWeakPassword: '...'` is a label, not a secret.
        "pattern": r'\b(?:password|secret|api_?key|token)\s*[:=]\s*["\'][^"\']{8,}["\']',
        "severity": "critical",
        "message": "Possible hardcoded secret",
    },
    "cleartext_http": {
        # Plain http only; XML namespaces and local hosts are not traffic.
        "pattern": r'http://(?!schemas\.android\.com|www\.w3\.org|www\.apple\.com|localhost|127\.0\.0\.1|10\.0\.2\.2)[^\s"\'<>]+',
        "severity": "medium",
        "message": "Cleartext http:// URL - use https",
    },
    "debug_mode": {
        "pattern": r'(debug: true|DEBUG=true|debugMode\s*[:=]?\s*true)',
        "severity": "medium",
        "message": "Debug mode enabled",
    },
    "auth_emulator": {
        "pattern": r'useAuthEmulator|useFirestoreEmulator',
        "severity": "medium",
        "message": "Emulator hook - make sure it cannot run in release (principle 5)",
    },
    "firebase_rules_open_write": {
        "pattern": r'allow (?:\w+\s*,\s*)*(?:write|create|update|delete)(?:\s*,\s*\w+)*\s*:\s*if true',
        "severity": "critical",
        "message": "Firestore rule allows unrestricted writes",
    },
    "firebase_rules_public_read": {
        # Legitimate for public content (daily_challenges); confirm intent.
        "pattern": r'allow (?:read|get|list)\s*:\s*if true',
        "severity": "low",
        "message": "Public read - confirm this collection holds no personal data",
    },
}


def finding(file: str, severity: str, message: str, line=None, code: str = "") -> dict:
    return {"file": file, "line": line, "severity": severity, "message": message, "code": code}


def find_files(project_root: Path, extensions: list[str]) -> list[Path]:
    """Project files with the given extensions, outside generated directories."""
    found = []
    for ext in extensions:
        for f in project_root.rglob(f"*{ext}"):
            parts = set(f.relative_to(project_root).parts)
            if parts & SKIPPED_DIRS or f.name.endswith(".g.dart"):
                continue
            found.append(f)
    return found


def scan_file(project_root: Path, filepath: Path, patterns: dict) -> list[dict]:
    """Scan a single file for security patterns."""
    findings = []
    try:
        lines = filepath.read_text(encoding="utf-8", errors="ignore").split("\n")
    except OSError:
        return findings
    rel = filepath.relative_to(project_root).as_posix()
    for i, line in enumerate(lines, 1):
        # Comments quote old rules and examples; only code counts.
        if line.lstrip().startswith(("//", "#", "*", "<!--")):
            continue
        for name, check in patterns.items():
            if name == "hardcoded_secrets" and filepath.name in PUBLIC_CONFIG_FILES:
                continue
            if re.search(check["pattern"], line, re.IGNORECASE):
                findings.append(finding(rel, check["severity"], check["message"], i, line.strip()[:120]))
    return findings


def check_required_files(project_root: Path) -> list[dict]:
    required = [
        "firestore.rules",
        "pubspec.yaml",
        "android/app/src/main/AndroidManifest.xml",
        "ios/Runner/Info.plist",
        "analysis_options.yaml",
    ]
    return [
        finding(f, "medium", f"Missing required file: {f}")
        for f in required
        if not (project_root / f).exists()
    ]


def _dependencies(pubspec: str) -> set[str]:
    """Package names declared in pubspec.yaml (direct and dev)."""
    return set(re.findall(r'^\s{2}([a-z0-9_]+):', pubspec, re.MULTILINE))


def check_packages(project_root: Path) -> list[dict]:
    findings = []
    pubspec_path = project_root / "pubspec.yaml"
    if not pubspec_path.exists():
        return findings
    deps = _dependencies(pubspec_path.read_text(encoding="utf-8"))

    for pkg in ["firebase_auth", "cloud_firestore", "drift", "flutter_riverpod"]:
        if pkg not in deps:
            findings.append(finding("pubspec.yaml", "critical", f"Missing required package: {pkg}"))

    # A. The local database is encrypted by swapping the SQLite build, not by
    # adding sqflite. Both libraries bundle libsqlite3 and cannot coexist.
    if "sqlcipher_flutter_libs" not in deps:
        findings.append(finding(
            "pubspec.yaml", "medium",
            "Local Drift database is not encrypted (no sqlcipher_flutter_libs) - see SKILL.md A",
        ))
    elif "sqlite3_flutter_libs" in deps:
        findings.append(finding(
            "pubspec.yaml", "high",
            "sqlcipher_flutter_libs and sqlite3_flutter_libs together - remove sqlite3_flutter_libs",
        ))

    if "firebase_app_check" not in deps:
        findings.append(finding("pubspec.yaml", "medium", "Firebase App Check not configured - see SKILL.md E"))
    if "firebase_crashlytics" not in deps:
        findings.append(finding("pubspec.yaml", "low", "No crash reporting (firebase_crashlytics) - see SKILL.md J"))
    return findings


def check_android(project_root: Path) -> list[dict]:
    findings = []
    manifest_rel = "android/app/src/main/AndroidManifest.xml"
    manifest = project_root / manifest_rel
    if manifest.exists():
        text = manifest.read_text(encoding="utf-8", errors="ignore")
        # B. Backup defaults to on: the local database goes to Google Drive.
        backup_off = re.search(r'android:allowBackup\s*=\s*"false"', text)
        has_rules = "dataExtractionRules" in text or "fullBackupContent" in text
        if not backup_off and not has_rules:
            findings.append(finding(
                manifest_rel, "medium",
                "Android Auto Backup uploads the local database (including local-only context) - see SKILL.md B",
            ))
        if re.search(r'android:usesCleartextTraffic\s*=\s*"true"', text):
            findings.append(finding(manifest_rel, "high", "Cleartext traffic allowed"))

    # C. Release builds signed with the debug key cannot be published.
    for name in ["build.gradle.kts", "build.gradle"]:
        gradle = project_root / "android/app" / name
        if not gradle.exists():
            continue
        text = gradle.read_text(encoding="utf-8", errors="ignore")
        release = re.search(r'release\s*\{(.*?)\n\s*\}', text, re.DOTALL)
        if release and re.search(r'signingConfigs\.(?:getByName\("debug"\)|debug)', release.group(1)):
            findings.append(finding(
                f"android/app/{name}", "high",
                "Release build is signed with the debug key - see SKILL.md C",
            ))
    return findings


def generate_report(project_root: Path) -> dict:
    """Run all security checks and generate a report."""
    all_findings = []
    for f in find_files(project_root, SCANNED_EXTENSIONS):
        all_findings.extend(scan_file(project_root, f, SECURITY_PATTERNS))
    all_findings.extend(check_required_files(project_root))
    all_findings.extend(check_packages(project_root))
    all_findings.extend(check_android(project_root))

    seen = set()
    unique_findings = []
    for f in all_findings:
        key = (f["file"], f["line"], f["message"])
        if key not in seen:
            seen.add(key)
            unique_findings.append(f)

    severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    unique_findings.sort(key=lambda x: severity_order.get(x["severity"], 4))

    return {
        "project": "Memory Arcade",
        "generated": datetime.now(timezone.utc).isoformat(),
        "summary": {
            s: sum(1 for f in unique_findings if f["severity"] == s)
            for s in ["critical", "high", "medium", "low"]
        },
        "total_findings": len(unique_findings),
        "findings": unique_findings,
    }


def main():
    # Windows consoles default to a legacy code page.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description="Memory Arcade Security Audit")
    parser.add_argument("--project", default=str(PROJECT_ROOT), help="Project root path")
    parser.add_argument("--output", default=None, help="Output JSON file path")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    report = generate_report(Path(args.project).resolve())

    if args.json or args.output:
        output = json.dumps(report, indent=2, ensure_ascii=False)
        if args.output:
            Path(args.output).write_text(output, encoding="utf-8")
        else:
            print(output)
        return

    print(f"\nSecurity Audit: {report['project']}")
    print(f"   Generated: {report['generated']}")
    for severity in ["critical", "high", "medium", "low"]:
        print(f"   {severity.capitalize():<9} {report['summary'][severity]}")
    print(f"   Total     {report['total_findings']}\n")

    for f in report["findings"]:
        location = f["file"] if f["line"] is None else f"{f['file']}:{f['line']}"
        print(f"   [{f['severity'].upper()}] {location}")
        print(f"      {f['message']}")
        if f["code"]:
            print(f"      `{f['code']}`")
        print()


if __name__ == "__main__":
    main()
