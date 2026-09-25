#!/usr/bin/env python3
"""
UI/UX Audit script for Memory Arcade.
Checks design system compliance, accessibility, and interaction patterns.

Usage:
    python scripts/uiux_audit.py [--project ROOT]

Outputs a JSON report with findings.
"""

import json
import re
import sys
import argparse
from pathlib import Path
from datetime import datetime

# ── Configuration ──────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

DESIGN_PATTERNS = {
    "hardcoded_color": {
        "pattern": r'Color\(0x[0-9A-Fa-f]{8}\)',
        "severity": "medium",
        "message": "Hardcoded color found — use AppColors tokens instead"
    },
    "hardcoded_spacing": {
        "pattern": r'\b(EdgeInsets\.|Padding\.|SizedBox\(height:\s*\d+|SizedBox\(width:\s*\d+)\s*\(?\s*\d+\)',
        "severity": "low",
        "message": "Hardcoded spacing — use AppSpacing tokens"
    },
    "ink_well": {
        "pattern": r'\bInkWell\b',
        "severity": "high",
        "message": "InkWell found — replace with Pressable"
    },
    "gesture_detector_without_feedback": {
        "pattern": r'GestureDetector\s*\(',
        "severity": "medium",
        "message": "GestureDetector without Pressable feedback — consider Pressable"
    },
    "ink_well": {
        "pattern": r'\bAnimatedContainer\b',
        "severity": "low",
        "message": "AnimatedContainer may not respect reduceMotion — check ProfileTokens"
    },
    "no_semantics": {
        "pattern": r'(Icon\s*\(|Text\s*\()[^;]*\n\s*(?!.*Semantics)(?!.*Pressable)',
        "severity": "low",
        "message": "Widget may lack semantics label"
    },
    "missing_pressable": {
        "pattern": r'onTap:\s*[^;]+',
        "severity": "medium",
        "message": "onTap found — ensure it's wrapped in Pressable"
    },
}

ACCESSIBILITY_CHECKS = {
    "min_touch_target": {
        "pattern": r'(height:\s*(?:4[0-5]|5[0-9])dp|height:\s*(?:4[0-5]|5[0-9]))',
        "severity": "medium",
        "message": "Touch target height — should be >= 48dp (56dp for primary)"
    },
    "text_scale_clamp": {
        "pattern": r'\bflutter_localizations\b',
        "severity": "low",
        "message": "Verify textScaleFactor clamp exists in app.dart"
    },
    "color_not_alone": {
        "pattern": r'color:\s*(AppColors\.|Colors\.)',
        "severity": "low",
        "message": "Check color is paired with icon+word, not standalone"
    },
}

REQUIRED_WIDGETS = [
    "Pressable",
    "AppCard",
    "GameIcon",
    "AppBadge",
    "AppStatChip",
    "AppProgressBar",
    "SectionHeader",
    "ProfileTokens",
]

REQUIRED_THEME_TOKENS = [
    "app_colors.dart",
    "app_motion.dart",
    "app_spacing.dart",
    "app_typography.dart",
    "app_shadows.dart",
    "profile_tokens.dart",
    "visual_profile.dart",
]


def find_files(project_root: Path, extensions: list[str]) -> list[Path]:
    found = []
    for ext in extensions:
        found.extend(project_root.rglob(f"*{ext}"))
    return [f for f in found if ".dart_tool" not in str(f) and ".fvm" not in str(f)]


def scan_file(filepath: Path, patterns: dict) -> list[dict]:
    findings = []
    try:
        content = filepath.read_text(encoding="utf-8", errors="ignore")
        lines = content.split("\n")
        for i, line in enumerate(lines, 1):
            for name, check in patterns.items():
                if re.search(check["pattern"], line):
                    findings.append({
                        "file": str(filepath.relative_to(PROJECT_ROOT)),
                        "line": i,
                        "severity": check["severity"],
                        "message": check["message"],
                        "code": line.strip()[:120]
                    })
    except Exception:
        pass
    return findings


def check_required_widgets(project_root: Path) -> list[dict]:
    """Check if core widgets exist."""
    findings = []
    widgets_dir = project_root / "lib" / "core" / "widgets"
    if not widgets_dir.exists():
        return findings

    existing = {f.stem for f in widgets_dir.glob("*.dart")}
    for widget in REQUIRED_WIDGETS:
        if widget not in existing and widget != "Pressable":
            findings.append({
                "file": str(widgets_dir),
                "severity": "medium",
                "message": f"Missing recommended widget: {widget}",
                "code": ""
            })

    return findings


def check_design_system(project_root: Path) -> list[dict]:
    """Check if DESIGN.md and theme files exist."""
    findings = []

    design_md = project_root / "assets" / "DESIGN.md"
    if not design_md.exists():
        findings.append({
            "file": "assets/DESIGN.md",
            "severity": "high",
            "message": "Missing DESIGN.md — the design system documentation is required",
            "code": ""
        })

    theme_dir = project_root / "lib" / "core" / "theme"
    if not theme_dir.exists():
        findings.append({
            "file": "lib/core/theme",
            "severity": "high",
            "message": "Missing theme directory",
            "code": ""
        })
        return findings

    for token in REQUIRED_THEME_TOKENS:
        if not (theme_dir / token).exists():
            findings.append({
                "file": f"lib/core/theme/{token}",
                "severity": "medium",
                "message": f"Missing theme token file: {token}",
                "code": ""
            })

    return findings


def check_dark_mode(project_root: Path) -> list[dict]:
    """Check if dark mode is implemented."""
    findings = []

    theme_path = project_root / "lib" / "core" / "theme" / "app_theme.dart"
    if not theme_path.exists():
        return findings

    content = theme_path.read_text()
    if "darkTheme" not in content and "ThemeMode" not in content and "darkMode" not in content:
        findings.append({
            "file": "lib/core/theme/app_theme.dart",
            "severity": "medium",
            "message": "Dark mode not implemented — consider adding ThemeMode.system",
            "code": ""
        })

    return findings


def check_audio_system(project_root: Path) -> list[dict]:
    """Check if audio system exists."""
    findings = []

    audio_dir = project_root / "lib" / "core" / "audio"
    if not audio_dir.exists():
        findings.append({
            "file": "lib/core/audio/",
            "severity": "low",
            "message": "No audio system found — consider adding contextual sound feedback",
            "code": ""
        })

    pubspec_path = project_root / "pubspec.yaml"
    if pubspec_path.exists():
        content = pubspec_path.read_text()
        if "just_audio" not in content and "audioplayers" not in content:
            findings.append({
                "file": "pubspec.yaml",
                "severity": "low",
                "message": "No audio package in dependencies",
                "code": ""
            })

    return findings


def check_onboarding(project_root: Path) -> list[dict]:
    """Check if onboarding exists."""
    findings = []

    onboarding_dir = project_root / "lib" / "features" / "onboarding"
    if not onboarding_dir.exists():
        findings.append({
            "file": "lib/features/onboarding/",
            "severity": "medium",
            "message": "No onboarding feature found — consider adding interactive tutorial",
            "code": ""
        })

    return findings


def generate_report(project_root: Path) -> dict:
    """Run all UI/UX checks and generate a report."""
    dart_files = find_files(project_root, [".dart"])
    yaml_files = find_files(project_root, [".yaml", ".md"])
    all_files = dart_files + yaml_files

    all_findings = []

    # Pattern scanning
    for f in all_files:
        all_findings.extend(scan_file(f, DESIGN_PATTERNS))
        all_findings.extend(scan_file(f, ACCESSIBILITY_CHECKS))

    # Structural checks
    all_findings.extend(check_required_widgets(project_root))
    all_findings.extend(check_design_system(project_root))
    all_findings.extend(check_dark_mode(project_root))
    all_findings.extend(check_audio_system(project_root))
    all_findings.extend(check_onboarding(project_root))

    # Deduplicate
    seen = set()
    unique_findings = []
    for f in all_findings:
        key = (f["file"], f["line"], f["message"])
        if key not in seen:
            seen.add(key)
            unique_findings.append(f)

    # Sort by severity
    severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    unique_findings.sort(key=lambda x: severity_order.get(x["severity"], 4))

    # Summary
    summary = {
        "critical": sum(1 for f in unique_findings if f["severity"] == "critical"),
        "high": sum(1 for f in unique_findings if f["severity"] == "high"),
        "medium": sum(1 for f in unique_findings if f["severity"] == "medium"),
        "low": sum(1 for f in unique_findings if f["severity"] == "low"),
    }

    report = {
        "project": "Memory Arcade",
        "generated": datetime.utcnow().isoformat() + "Z",
        "summary": summary,
        "total_findings": len(unique_findings),
        "findings": unique_findings,
    }

    return report


def main():
    parser = argparse.ArgumentParser(description="Memory Arcade UI/UX Audit")
    parser.add_argument("--project", default=str(PROJECT_ROOT), help="Project root path")
    parser.add_argument("--output", default=None, help="Output JSON file path")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    project_root = Path(args.project)
    report = generate_report(project_root)

    if args.json or args.output:
        output = json.dumps(report, indent=2)
        if args.output:
            Path(args.output).write_text(output)
        else:
            print(output)
    else:
        print(f"\n🎨 UI/UX Audit: {report['project']}")
        print(f"   Generated: {report['generated']}")
        print(f"\n   🔴 Critical: {report['summary']['critical']}")
        print(f"   🟠 High:     {report['summary']['high']}")
        print(f"   🟡 Medium:   {report['summary']['medium']}")
        print(f"   🟢 Low:      {report['summary']['low']}")
        print(f"   Total:       {report['total_findings']}\n")

        for f in report["findings"]:
            icon = {"critical": "🔴", "high": "🟠", "medium": "🟡", "low": "🟢"}[f["severity"]]
            print(f"   {icon} [{f['severity'].upper()}] {f['file']}:{f['line']}")
            print(f"      {f['message']}")
            if f['code']:
                print(f"      `{f['code']}`")
            print()


if __name__ == "__main__":
    main()
