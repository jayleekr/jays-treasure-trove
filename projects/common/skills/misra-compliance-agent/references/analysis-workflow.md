# Analysis Workflow - Detailed Patterns

Comprehensive guide for executing MISRA/CERT-CPP violation analysis mode.

## Command Execution

```bash
./isir.py -m <module> -c <checker> -d
```

Where:
- `<module>`: container-manager, vam, libsntxx, diagnostic-manager, dpm, ethnm, rta, seccommon, soa
- `<checker>`: MISRA, Cert-CPP, or all

## Output Parsing

Expected output format:
```
Total violations: 1523
	MISRA violations: 1523
		misra_8.2.5.xml violations: 342
		misra_7.0.2.xml violations: 215
		misra_19.3.3.xml violations: 156
		...
```

Extract key metrics:
1. **Total violation count**: First line number
2. **Per-checker breakdown**: Indented sections by checker type
3. **Per-rule counts**: Individual rule XML file violations
4. **Rule frequency ranking**: Sort rules by violation count descending

## Rule Classification

Determine which rules have predefined suppression messages by reading isir.py:

Read `/home/jay.lee/ccu-2.0/isir.py` lines 165-206 (suppression_message function)

Count auto-suppressible vs manual rules:
- Auto-suppressible: Rules in suppression_message dict
- Manual needed: Rules NOT in dict

Calculate percentages:
```
auto_suppressible_pct = (auto_count / total_violations) * 100
manual_pct = (manual_count / total_violations) * 100
```

## Effort Estimation

Use the following heuristics:

**Auto-suppress effort**:
- Time: ~2-5 minutes (one command execution)
- Risk: Low (predefined messages reviewed)

**Manual suppression effort**:
- Time per rule: ~5-15 minutes (depends on violation count)
- Total time: `rule_count * avg_time_per_rule`
- Risk: Medium (requires custom justification review)

**Complete workflow effort**:
- Analysis: 5 minutes
- Auto-suppress: 5 minutes
- Manual rules: `manual_rule_count * 10 minutes`
- Git workflow: 10 minutes
- PR creation: 10 minutes
- Total: Sum of above + 20% buffer

## Recommendation Logic

Apply the following decision tree:

```
If auto_suppressible_pct >= 70%:
    Recommend: "Start with auto-suppress mode to quickly handle 70%+ of violations"

Else if auto_suppressible_pct >= 40%:
    Recommend: "Use auto-suppress for quick wins, then targeted mode for remaining rules"

Else:
    Recommend: "Use targeted mode for all rules (mostly custom justifications needed)"

If total_violations > 1000:
    Warn: "Large violation count - consider breaking into multiple PRs by rule category"

If manual_rule_count > 20:
    Suggest: "Consider updating isir.py suppression_message dict with common justifications"
```

## Output Presentation

Format findings as:

```
MISRA Compliance Analysis: <module>
=============================================

Total Violations: X,XXX
  - Mandatory (MISRA): X,XXX (116 rules)
  - Advisory (MISRA): XXX (53 rules)
  - CERT-CPP: XXX (YY rules)

Top Offenders:
  1. Rule 8.2.5: XXX violations [Predefined: ✅] - Type casting
  2. Rule 7.0.2: XXX violations [Predefined: ✅] - Type conversions
  3. Rule 19.3.3: XXX violations [Predefined: ✅] - Variadic macros
  4. Rule X.Y.Z: XXX violations [Predefined: ❌] - <description>
  ...

Auto-suppressible: X,XXX violations (XX rules with predefined messages)
Manual needed: XXX violations (XX rules need custom justification)

Effort Estimate:
  Auto-suppress: 5 minutes
  Manual rules: ~XX minutes (XX rules * 10 min avg)
  Total: ~XX minutes

Recommendations:
  ✅ Run auto-suppress to handle XX% of violations automatically
  ⚠️ XX rules require manual review and custom justification
  📋 Estimated manual effort: X-X hours

Next Steps:
  1. Auto-suppress: ./isir.py -m <module> -c <checker> -sa
  2. Review changes and commit
  3. Handle remaining rules with targeted mode
```

## Documentation Links

Provide rule documentation URLs:

**MISRA Rules**:
`https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule<X>.<Y>.<Z>.html`

Replace dots with underscores in URL: `misracpp2023rule8_2_5.html`

**CERT-CPP Rules**:
`https://uk.mathworks.com/help/bugfinder/ref/cert<RULE>cpp.html`

Example: `certconst30cpp.html`

## Error Handling During Analysis

**Network timeouts**:
- Inform user download is taking longer than expected
- Suggest using `--latest` flag with local XML reports if available

**Empty results**:
- Verify module name is correct
- Check if module has violations on ops server
- Confirm checker type is valid (MISRA, Cert-CPP, all)

**Python dependency errors**:
- Detect ModuleNotFoundError in output
- Auto-install missing packages: `pip3 install requests beautifulsoup4 lxml cpp-demangle`
- Retry analysis after installation
