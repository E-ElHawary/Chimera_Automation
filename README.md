# Chimera Detection Pipeline

## Overview

A Bash script providing a graphical (zenity) interface for running chimera detection on 16S and 18S rRNA FASTA sequence data. Supports both reference-based and de novo methods across multiple detection tools, with automated output directory organisation.

---

## Prerequisites

The following must be installed and accessible before running the script:

| Dependency | Purpose | Install |
|---|---|---|
| **Zenity** | GUI prompts | `sudo apt-get install zenity` |
| **MOTHUR** | ChimeraSlayer, VSEARCH (de novo), Bellerophon, Perseus, UCHIME | [mothur.org](https://mothur.org) |
| **VSEARCH** | Reference-based VSEARCH | [github.com/torognes/vsearch](https://github.com/torognes/vsearch) |
| **USEARCH** | All UCHIME2 modes and UCHIME3 | [drive5.com/usearch](https://drive5.com/usearch) |

> **Display required.** Zenity requires a graphical environment. Running over SSH without X forwarding will fail. Use `ssh -X` or run locally.

---

## Input File Requirements

All input files must follow this exact naming convention and reside in the same directory:

```
sample_1.fasta
sample_1.count_table
sample_2.fasta
sample_2.count_table
...
```

- Files not matching `sample_N.fasta` / `sample_N.count_table` will be ignored.
- **Paths must not contain spaces.** The script passes paths directly into MOTHUR and USEARCH commands via `eval`; spaces in any path (data directory, executable, or reference file) will cause silent failures or incorrect execution.

---

## Supported Tools

### Reference-Based

| Tool | Executable needed |
|---|---|
| ChimeraSlayer | MOTHUR |
| VSEARCH | VSEARCH binary |
| UCHIME | MOTHUR |
| UCHIME2_Balanced | USEARCH |
| UCHIME2_HighConfidence | USEARCH |
| UCHIME2_Sensitive | USEARCH |
| UCHIME2_Specific | USEARCH |
| UCHIME2_Denoised | USEARCH |

### De Novo

| Tool | Executable needed |
|---|---|
| ChimeraSlayer | MOTHUR |
| VSEARCH | MOTHUR |
| UCHIME | MOTHUR |
| UCHIME3 | USEARCH |
| Bellerophon | MOTHUR |
| Perseus | MOTHUR |

---

## Usage

Set execute permission once:

```sh
chmod +x chimera_detection.sh
```

Run the script:

```sh
./chimera_detection.sh
```

---

## Workflow

The script prompts in this exact order:

1. **Marker gene** — select `16S` or `18S`.
2. **Method** — select `Reference-Based` or `Denovo`.
3. **Tool** — select from the list filtered by your method choice.
4. **Data directory** — the folder containing your `sample_N.fasta` and `sample_N.count_table` files.
5. **Executable** — MOTHUR, VSEARCH, or USEARCH binary depending on the tool selected.
6. **Reference file** — required for all reference-based tools, and for de novo ChimeraSlayer and Bellerophon. Not prompted for other de novo tools.

If any prompt is cancelled or left empty, the script exits with an error dialog.

---

## UCHIME3 — Special Pre-processing

When UCHIME3 is selected, the script automatically reformats FASTA headers before running detection. For each sample it:

1. Reads abundance values from the corresponding `.count_table`.
2. Appends `;size=N;` to each sequence header.
3. Sorts sequences by abundance in descending order (required by UCHIME3).

This modified FASTA is written to the output directory as `modified_sample_N.fasta` and is used as input to UCHIME3. Your original files are not modified.

---

## Output

Results are written to subdirectories created inside your selected data directory, named by marker gene, tool, and method. Examples:

```
/your/data/dir/
├── 16S_slayer_ref_output/
├── 16S_vsearch_denovo_output/
├── 16S_uchime2_sensitive_output/
├── 16S_uchime3_output/
│   ├── modified_sample_1.fasta
│   ├── out_1.txt
│   ├── chimeras_1.fa
│   └── nonchimeras_1.fa
└── ...
```

UCHIME2 modes that build a UDB index (Sensitive, HighConfidence, Specific) also write `db.udb` to their output directory.

---

## Error Behaviour

The script runs with `set -euo pipefail`. Any unhandled error — including a failed tool command — will cause immediate exit. If the script stops mid-run, check the terminal output for the failed command and verify:

- The correct executable was selected for the chosen tool.
- All input files follow the required naming convention.
- No paths contain spaces.
- The selected executable has permission to run on your filesystem (executables on `noexec`-mounted drives will fail even after `chmod +x`).

---

## Demo

A full walkthrough of the GUI and workflow is available here:  
[Watch the Demo Video](https://nileuniversity-my.sharepoint.com/:v:/g/personal/e_elhawary_nu_edu_eg/IQBG3wm6DqzUQZ_6nX4wtI2NAcRZlI4sgwNVM4OvMylYk8Y?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=hrpuQ3)
