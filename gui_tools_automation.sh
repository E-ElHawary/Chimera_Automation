#!/bin/bash
set -euo pipefail

# ── helpers ───────────────────────────────────────────────────────────────────

die()   { zenity --error --text="$1"; exit 1; }
pick_dir()  { zenity --file-selection --directory --title="$1" || die "No directory selected"; }
pick_file() { zenity --file-selection            --title="$1" || die "No file selected"; }
pick_exe()  { local f; f=$(pick_file "$1"); chmod +x "$f"; echo "$f"; }

mock_num() { basename "$1" | sed 's/sample_//; s/\..*//' ; }

cleanup_r1() {
    local dir=$1
    find "$dir" -maxdepth 1 \( -name '*_R1_001.fasta' -o -name '*_R1_001.count_table' \) -delete
}

# ── input collection ──────────────────────────────────────────────────────────

collect_inputs() {
    local method=$1 tool=$2
    DATA=$(pick_dir "Select data directory")

    case "$tool" in
        ChimeraSlayer|Bellerophon|Perseus|UCHIME|VSEARCH\ denovo)
            TOOL_EXE=$(pick_file "Select MOTHUR executable") ;;
        VSEARCH)
            if [[ "$method" == "Reference-Based" ]]; then
                TOOL_EXE=$(pick_exe "Select VSEARCH executable")
            else
                TOOL_EXE=$(pick_file "Select MOTHUR executable")
            fi ;;
        UCHIME3)
            TOOL_EXE=$(pick_exe "Select usearch executable") ;;
        UCHIME2_*)
            TOOL_EXE=$(pick_exe "Select usearch executable") ;;
    esac

    case "$method-$tool" in
        Reference-Based-*|Denovo-ChimeraSlayer|Denovo-Bellerophon)
            REF=$(pick_file "Select reference file") ;;
        *)
            REF="" ;;
    esac
}

# ── fasta header modification (for UCHIME3) ───────────────────────────────────

modify_fasta_headers() {
    local dir=$1 out=$2
    mkdir -p "$out"

    for count_file in "$dir"/sample_*.count_table; do
        local n; n=$(mock_num "$count_file")
        local fasta="$dir/sample_${n}.fasta"
        local outfile="$out/modified_sample_${n}.fasta"

        declare -A abundances=()
        while read -r id count; do
            abundances["$id"]=$count
        done < <(awk 'NR>1 {print $1, $2}' "$count_file")

        local pairs=()
        local header="" seq=""
        while IFS= read -r line; do
            line=$(echo "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ $line == ">"* ]]; then
                if [[ -n $header && -n $seq ]]; then
                    local size; size=$(grep -oP '(?<=size=)\d+' <<< "$header")
                    pairs+=("$size|$header|$seq")
                fi
                local id="${line#>}"
                local ab="${abundances[$id]:-1}"
                header=">${id};size=${ab};"
                seq=""
            else
                seq+="$line"
            fi
        done < "$fasta"
        [[ -n $header && -n $seq ]] && { local size; size=$(grep -oP '(?<=size=)\d+' <<< "$header"); pairs+=("$size|$header|$seq"); }

        IFS=$'\n' sorted=($(sort -nr <<< "${pairs[*]}")); unset IFS
        {
            for entry in "${sorted[@]}"; do
                echo "${entry#*|}}" | awk -F'|' '{print $1; print $2}'
            done
        } > "$outfile"
    done
}

# ── run functions ─────────────────────────────────────────────────────────────

run_align_and() {
    # Usage: run_align_and <mothur> <outdir> <fasta> <ref> <chimera_cmd_suffix>
    local mothur=$1 outdir=$2 fasta=$3 ref=$4 suffix=$5
    local n; n=$(mock_num "$fasta")
    local aligned="$outdir/sample_${n}.align"
    eval "$mothur \"#set.dir(output=$outdir); align.seqs(fasta=$fasta, reference=$ref)\""
    eval "$mothur \"#set.dir(output=$outdir); $suffix\""
}

run_slayer_reference() {
    local outdir="${DATA}/${MARKER}_slayer_ref_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        local aligned="$outdir/sample_${n}.align"
        eval "$TOOL_EXE \"#set.dir(output=$outdir); align.seqs(fasta=$fa, reference=$REF)\""
        eval "$TOOL_EXE \"#set.dir(output=$outdir); chimera.slayer(fasta=$aligned, reference=$REF)\""
    done
}

run_slayer_denovo() {
    local outdir="${DATA}/${MARKER}_slayer_denovo_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        local aligned="$outdir/sample_${n}.align"
        local ct="$DATA/sample_${n}.count_table"
        eval "$TOOL_EXE \"#set.dir(output=$outdir); align.seqs(fasta=$fa, reference=$REF)\""
        eval "$TOOL_EXE \"#set.dir(output=$outdir); chimera.slayer(fasta=$aligned, count=$ct, reference=self)\""
    done
    cleanup_r1 "$DATA"
}

run_vsearch_reference() {
    local outdir="${DATA}/${MARKER}_vsearch_ref_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        eval "$TOOL_EXE --uchime_ref $fa --db $REF --chimeras $outdir/vsearch_sample_${n}.fasta"
    done
}

run_vsearch_denovo() {
    local outdir="${DATA}/${MARKER}_vsearch_denovo_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        local ct="$DATA/sample_${n}.count_table"
        eval "$TOOL_EXE \"#set.dir(output=$outdir); chimera.vsearch(fasta=$fa, count=$ct, dereplicate=t)\""
    done
    cleanup_r1 "$DATA"
}

run_bellerophon() {
    local outdir="${DATA}/${MARKER}_bellerophon_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        local aligned="$outdir/sample_${n}.align"
        eval "$TOOL_EXE \"#set.dir(output=$outdir); align.seqs(fasta=$fa, reference=$REF)\""
        eval "$TOOL_EXE \"#set.dir(output=$outdir); chimera.bellerophon(fasta=$aligned)\""
    done
}

run_perseus() {
    local outdir="${DATA}/${MARKER}_perseus_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        local ct="$DATA/sample_${n}.count_table"
        eval "$TOOL_EXE \"#set.dir(output=$outdir); chimera.perseus(fasta=$fa, count=$ct)\""
    done
    cleanup_r1 "$DATA"
}

run_uchime1_denovo() {
    local outdir="${DATA}/${MARKER}_uchime1_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        local ct="$DATA/sample_${n}.count_table"
        eval "$TOOL_EXE \"#set.dir(output=$outdir); chimera.uchime(fasta=$fa, count=$ct)\""
    done
    cleanup_r1 "$DATA"
}

run_uchime1_ref() {
    local outdir="${DATA}/${MARKER}_uchime1_ref_output"; mkdir -p "$outdir"
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        eval "$TOOL_EXE \"#set.dir(output=$outdir); chimera.uchime(fasta=$fa, reference=$REF)\""
    done
}

# Consolidated UCHIME2 — all five modes share the same structure
run_uchime2() {
    local mode=$1
    local outdir="${DATA}/${MARKER}_uchime2_${mode}_output"; mkdir -p "$outdir"

    # sensitive / high_confidence / specific need a UDB index first
    case "$mode" in
        sensitive|high_confidence|specific)
            local udb="$outdir/db.udb"
            eval "$TOOL_EXE -makeudb_usearch $REF -output $udb"
            local db="$udb" ;;
        *)
            local db="$REF" ;;
    esac

    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        eval "$TOOL_EXE -uchime2_ref $fa -db $db -uchimeout $outdir/out_${n}.txt -strand plus -mode $mode"
    done
}

run_uchime3() {
    local outdir="${DATA}/${MARKER}_uchime3_output"; mkdir -p "$outdir"
    modify_fasta_headers "$DATA" "$outdir"   # run once, not per-file
    for fa in "$DATA"/sample_*.fasta; do
        local n; n=$(mock_num "$fa")
        eval "$TOOL_EXE -uchime3_denovo $outdir/modified_sample_${n}.fasta \
            -uchimeout $outdir/out_${n}.txt \
            -chimeras $outdir/chimeras_${n}.fa \
            -nonchimeras $outdir/nonchimeras_${n}.fa"
    done
}

# ── dispatch ──────────────────────────────────────────────────────────────────

run_tool() {
    local method=$1 tool=$2
    case "$tool" in
        ChimeraSlayer)
            [[ "$method" == "Reference-Based" ]] && run_slayer_reference || run_slayer_denovo ;;
        VSEARCH)
            [[ "$method" == "Reference-Based" ]] && run_vsearch_reference || run_vsearch_denovo ;;
        UCHIME)
            [[ "$method" == "Reference-Based" ]] && run_uchime1_ref || run_uchime1_denovo ;;
        UCHIME3)             run_uchime3 ;;
        UCHIME2_Balanced)    run_uchime2 balanced ;;
        UCHIME2_HighConfidence) run_uchime2 high_confidence ;;
        UCHIME2_Sensitive)   run_uchime2 sensitive ;;
        UCHIME2_Specific)    run_uchime2 specific ;;
        UCHIME2_Denoised)    run_uchime2 denoised ;;
        Bellerophon)         run_bellerophon ;;
        Perseus)             run_perseus ;;
        *)                   die "Unknown tool: $tool" ;;
    esac
}

# ── main ──────────────────────────────────────────────────────────────────────

MARKER=$(zenity --list --title="Select marker gene" --column="Gene" "16S" "18S") \
    || die "No marker selected"

METHOD=$(zenity --list --title="Select method" --column="Method" "Reference-Based" "Denovo") \
    || die "No method selected"

TOOLS_REF=("ChimeraSlayer" "VSEARCH" "UCHIME2_Balanced" "UCHIME2_HighConfidence" "UCHIME2_Sensitive" "UCHIME2_Specific" "UCHIME2_Denoised" "UCHIME")
TOOLS_DE=("Perseus" "Bellerophon" "ChimeraSlayer" "VSEARCH" "UCHIME3" "UCHIME")

if [[ "$METHOD" == "Reference-Based" ]]; then
    TOOL_LIST=("${TOOLS_REF[@]}")
else
    TOOL_LIST=("${TOOLS_DE[@]}")
fi

TOOL=$(zenity --list --title="Select tool" --column="Tool" "${TOOL_LIST[@]}") \
    || die "No tool selected"

# Declare globals that run_* functions read
declare DATA="" TOOL_EXE="" REF="" 
collect_inputs "$METHOD" "$TOOL"

run_tool "$METHOD" "$TOOL"
