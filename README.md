# Chimera Detection Pipeline

## Overview
This Bash script provides a graphical interface using `zenity` to facilitate the selection of directories, executable files, and reference files for running various chimera detection tools on 16S and 18S rRNA sequence data. The script automates data processing using tools such as MOTHUR, VSEARCH, and UCHIME.

## Features
- Supports both **Reference-Based** and **De Novo** chimera detection methods.
- Provides a GUI interface for selecting files and tools.
- Supports multiple detection tools, including:
  - ChimeraSlayer
  - VSEARCH
  - UCHIME
  - Perseus
  - Bellerophon
- Processes FASTA files and count tables automatically.
- Ensures executables are set with the correct permissions before use.
- Generates organized output directories for results.

## Prerequisites
Before running the script, ensure the following tools are installed and available on your system:
- **Zenity** (for GUI selection prompts)
- **MOTHUR**
- **VSEARCH**
- **USEARCH**
- **UCHIME** (included in MOTHUR)
- **BASH Shell** (Ubuntu/Linux environment recommended)

To install Zenity, use:
```sh
sudo apt-get install zenity
```

## Usage
Run the script using:
```sh
./gui_tools_automation.sh
```
The script will prompt you to select:
1. The dataset directory.
2. The method (`Reference-Based` or `Denovo`).
3. The tool to use for chimera detection.
4. The required executables and reference files depending on the selected method and tool.

### Example Workflow
- Select `Reference-Based` method with `VSEARCH`.
- Choose the data directory containing FASTA files.
- Select the VSEARCH executable.
- Provide the reference database file.
- The script will process the data and generate results in an organized directory structure.

## Output
The processed files and results are saved in subdirectories within the selected data directory. Output directories are named based on the tool and method used, e.g., `18S_vsearch_ref_output`.

## Notes
- Ensure all input files are properly formatted before running the script.
- The script requires executable permissions. If needed, set them using:
```sh
chmod +x gui_tools_automation.sh
```
- If an incorrect file is selected, the script will show an error and exit.
## Demo Video
A walkthrough of the Chimera Detection Pipeline GUI and workflow is available here:  
[Watch the Demo Video](https://nileuniversity-my.sharepoint.com/:v:/r/personal/e_elhawary_nu_edu_eg/Documents/Chimera_demo.mp4?csf=1&web=1&nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=mdAt62)
