#!/usr/bin/env python3
"""
UI/UX Audit script for Memory Arcade.
Checks design system compliance, accessibility, and interaction patterns.

Usage:
    python .agents/skills/uiux-skill/scripts/uiux_audit.py [--project ROOT] [--json] [--output FILE]

Findings are pattern matches: leads to confirm by reading the code, not
verdicts. Principles and sections refer to SKILL.md.
"""

import json
import re
import argparse
import sys
from pathlib import Path
from datetime import datetime, timezone

# ── Configuration ──────────────────────────────────────────────

# <root>/.agents/skills/uiux-skill/scripts/uiux_audit.py
PROJECT_ROOT = Path(__file__).resolve().parents[4]

# Generated, vendored or tool directories: never project source.
SKIPPED_DIRS = {".dart_tool", ".fvm", "build", ".git", "Pods", "node_modules", ".gradle", ".idea"}

# The theme defines the tokens, so literal colors and sizes are expected there.
TOKEN_DIR = "lib/core/theme/"

# Pressable is built on a GestureDetector: it is the one allowed place.
PRESSABLE_FILE = "lib/core/widgets/pressable.dart"

DESIGN_PATTERNS = {
    "hardcoded_color": {
        "pattern": r'\bColor\(0x[0-9A-Fa-f]{8}\)',
        "severity": "medium",
        "message": "Hardcoded color - use AppColors tokens (principle 1)",
    },
    "hardcoded_spacing": {
        # A literal as the first value: `EdgeInsets.all(16)`, `SizedBox(height: 8)`.
        "pattern": r'\bEdgeInsets\.\w+\(\s*(?:\w+:\s*)?\d|\bSizedBox\(\s*(?:height|width):\s*\d',
        "severity": "low",
        "message": "Hardcoded spacing - use AppSpacing tokens (principles 1 and 10)",
    },
    "ink_well": {
        "pattern": r'\bInkWell\(',
        "severity": "high",
        "message": "InkWell - replace with Pressable",
    },
    "gesture_detector": {
        # RawGestureDetector is for custom recognizers (letter_wheel.dart), not taps.
        "pattern": r'(?<!Raw)\bGestureDetector\(',
        "severity": "medium",
        "message": "GestureDetector gives no press feedback - consider Pressable",
    },
    "animated_container": {
        "pattern": r'\bAnimatedContainer\(',
        "severity": "low",
        "message": "AnimatedContainer - check its duration honours reduce motion (ProfileTokens)",
    },
    "small_touch_target": {
        # Last value below 48: `minimumSize: Size(40, 40)`, `Size.square(32)`.
        "pattern": r'(?:minimumSize|fixedSize):\s*(?:const\s+)?Size(?:\.square|\.fromHeight)?\([^)]*?\b(?:[0-9]|[1-3][0-9]|4[0-7])(?:\.\d+)?\s*\)',
        "severity": "medium",
        "message": "Touch target below 48dp (56dp for primary controls, principle 5)",
    },
}

# Core widgets from SKILL.md, with the file that defines each.
REQUIRED_WIDGETS = {
    "Pressable": "lib/core/widgets/pressable.dart",
    "AppCard": "lib/core/widgets/app_card.dart",
    "GameIcon": "lib/core/widgets/game_icon.dart",
    "AppBadge": "lib/core/widgets/app_badge.dart",
    "AppStatChip": "lib/core/widgets/app_stat_chip.dart",
    "AppProgressBar": "lib/core/widgets/app_progress_bar.dart",
    "SectionHeader": "lib/core/widgets/section_header.dart",
    "ProfileTokens": "lib/core/theme/profile_tokens.dart",
}

REQUIRED_THEME_TOKENS = [
    "app_colors.dart",
    "app_motion.dart",
    "app_spacing.dart",
    "app_typography.dart",
    "app_shadows.dart",
    "app_theme.dart",
    "profile_tokens.dart",
    "visual_profile.dart",
]


def finding(file: str, severity: str, message: str, line=None, code: str = "") -> dict:
    return {"file": file, "line": line, "severity": severity, "message": message, "code": code}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def find_dart_files(project_root: Path) -> list[Path]:
    """Hand-written Dart sources under lib/."""
    lib = project_root / "lib"
    if not lib.exists():
        return []
    return [
        f for f in lib.rglob("*.dart")
        if not set(f.relative_to(project_root).parts) & SKIPPED_DIRS
        and not f.name.endswith(".g.dart")
    ]


def scan_file(project_root: Path, filepath: Path, patterns: dict) -> list[dict]:
    """Scan a single Dart file for design patterns."""
    findings = []
    try:
        lines = read(filepath).split("\n")
    except OSError:
        return findings
    rel = filepath.relative_to(project_root).as_posix()
    for i, line in enumerate(lines, 1):
        # Comments quote the widgets they replace; only code counts.
        if line.lstrip().startswith(("//", "/*", "*")):
            continue
        for name, check in patterns.items():
            if name in ("hardcoded_color", "hardcoded_spacing") and rel.startswith(TOKEN_DIR):
                continue
            if name == "gesture_detector" and rel == PRESSABLE_FILE:
                continue
            if re.search(check["pattern"], line):
                findings.append(finding(rel, check["severity"], check["message"], i, line.strip()[:120]))
    return findings


def check_required_widgets(project_root: Path) -> list[dict]:
    """Check that the core widgets exist and define their class."""
    findings = []
    for widget, rel in REQUIRED_WIDGETS.items():
        path = project_root / rel
        if not path.exists() or not re.search(rf'\bclass {widget}\b', read(path)):
            findings.append(finding(rel, "medium", f"Missing core widget: {widget}"))
    return findings


def check_design_system(project_root: Path) -> list[dict]:
    """Check that DESIGN.md and the theme token files exist."""
    findings = []
    if not (project_root / "assets" / "DESIGN.md").exists():
        findings.append(finding(
            "assets/DESIGN.md", "high",
            "Missing DESIGN.md - the design system documentation is required",
        ))

    theme_dir = project_root / TOKEN_DIR
    if not theme_dir.exists():
        findings.append(finding(TOKEN_DIR, "high", "Missing theme directory"))
        return findings

    for token in REQUIRED_THEME_TOKENS:
        if not (theme_dir / token).exists():
            findings.append(finding(f"{TOKEN_DIR}{token}", "medium", f"Missing theme token file: {token}"))
    return findings


def check_text_scaling(project_root: Path) -> list[dict]:
    """System font scaling is honoured but clamped at app level (DESIGN.md)."""
    rel = "lib/utils/app.dart"
    path = project_root / rel
    if path.exists() and "withClampedTextScaling" not in read(path):
        return [finding(rel, "medium", "No text scale clamp - DESIGN.md clamps system font scaling at 135%")]
    return []


def check_dark_mode(project_root: Path) -> list[dict]:
    """Section 8: dark mode."""
    sources = [project_root / TOKEN_DIR / "app_theme.dart", project_root / "lib/utils/app.dart"]
    text = "".join(read(p) for p in sources if p.exists())
    if text and not re.search(r'\bdarkTheme\b|\bThemeMode\b', text):
        return [finding(
            f"{TOKEN_DIR}app_theme.dart", "medium",
            "Dark mode not implemented - see SKILL.md section 8",
        )]
    return []


def check_audio_system(project_root: Path) -> list[dict]:
    """Section 12: sound feedback."""
    findings = []
    if not (project_root / "lib" / "core" / "audio").exists():
        findings.append(finding(
            "lib/core/audio/", "low",
            "No audio system - see SKILL.md section 12",
        ))
    pubspec = project_root / "pubspec.yaml"
    if pubspec.exists() and not re.search(r'^\s{2}(?:just_audio|audioplayers):', read(pubspec), re.MULTILINE):
        findings.append(finding("pubspec.yaml", "low", "No audio package in dependencies"))
    return findings


def check_onboarding(project_root: Path) -> list[dict]:
    """Section 4: interactive onboarding."""
    if not (project_root / "lib" / "features" / "onboarding").exists():
        return [finding(
            "lib/features/onboarding/", "medium",
            "No onboarding feature - see SKILL.md section 4",
        )]
    return []


def generate_report(project_root: Path) -> dict:
    """Run all UI/UX checks and generate a report."""
    all_findings = []
    for f in find_dart_files(project_root):
        all_findings.extend(scan_file(project_root, f, DESIGN_PATTERNS))
    all_findings.extend(check_required_widgets(project_root))
    all_findings.extend(check_design_system(project_root))
    all_findings.extend(check_text_scaling(project_root))
    all_findings.extend(check_dark_mode(project_root))
    all_findings.extend(check_audio_system(project_root))
    all_findings.extend(check_onboarding(project_root))

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
    parser = argparse.ArgumentParser(description="Memory Arcade UI/UX Audit")
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

    print(f"\nUI/UX Audit: {report['project']}")
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
