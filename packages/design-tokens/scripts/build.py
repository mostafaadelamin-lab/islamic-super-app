#!/usr/bin/env python3
"""Generate platform files from tokens.json: CSS custom properties (web) and Dart constants (mobile)."""
import json, pathlib, re
R = pathlib.Path(__file__).resolve().parents[1]
T = json.loads((R / "tokens.json").read_text())
kebab = lambda s: re.sub(r"([A-Z0-9]+)", lambda m: "-" + m.group(1).lower(), s)
def css_block(c): return "".join(f"--color-{kebab(k)}:{v};" for k, v in c.items())
num = lambda grp, unit: "".join(f"--{kebab(grp)}-{kebab(k)}:{v}{unit};" for k, v in T[grp].items())
css = (f"/* generated from tokens.json — do not edit */\n:root{{{css_block(T['color']['light'])}{num('fontSize','px')}{num('space','px')}{num('radius','px')}"
       f"--font-quran:'{T['font']['quran']}',serif;--font-ui:'{T['font']['uiArabic']}','{T['font']['uiLatin']}',system-ui,sans-serif;--min-touch:{T['minTouchTarget']}px}}\n"
       f"@media (prefers-color-scheme: dark){{:root:not([data-theme=\"light\"]){{{css_block(T['color']['dark'])}color-scheme:dark}}}}\n"
       f":root[data-theme=\"dark\"]{{{css_block(T['color']['dark'])}color-scheme:dark}}\n")
(R / "dist/tokens.css").write_text(css)
(R / "dist/tokens.ts").write_text("// generated from tokens.json — do not edit\nexport const tokens = " + json.dumps(T, indent=1) + " as const;\n")
def dart_colors(name, c): return f"  static const {name} = <String, Color>{{\n" + "".join(f"    '{k}': Color(0xFF{v[1:]}),\n" for k, v in c.items()) + "  };\n"
dart = ("// generated from packages/design-tokens/tokens.json — do not edit\nimport 'dart:ui';\n\nclass DesignTokens {\n  DesignTokens._();\n"
        + dart_colors("light", T["color"]["light"]) + dart_colors("dark", T["color"]["dark"])
        + "".join(f"  static const double {g}{k[0].upper()+k[1:]} = {float(v)};\n" for g in ("fontSize", "space", "radius") for k, v in T[g].items())
        + f"  static const String fontQuran = '{T['font']['quran']}';\n  static const String fontUi = '{T['font']['uiArabic']}';\n  static const double minTouchTarget = {float(T['minTouchTarget'])};\n}}\n")
(R / "dist/design_tokens.dart").write_text(dart)
print("tokens built")
