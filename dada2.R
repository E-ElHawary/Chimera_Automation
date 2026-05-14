library(dada2)

start_time <- Sys.time()

path <- "/mnt/aeebb108-3c88-4302-b64d-01c12b054dff/Mocks/mock_4"
fnFs <- sort(list.files(path, pattern="_R1_001.fastq", full.names = TRUE))
fnRs <- sort(list.files(path, pattern="_R2_001.fastq", full.names = TRUE))
# Extract sample names, assuming filenames have format: SAMPLENAME_XXX.fastq
sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)
# Generate unique identifiers for output files
output_suffix <- seq_along(sample.names)

# Construct output file paths
filtFs <- file.path(path, "filtered", paste0(sample.names, "F_filt", output_suffix, ".fastq.gz"))
filtRs <- file.path(path, "filtered", paste0(sample.names, "R_filt", output_suffix, ".fastq.gz"))

# Assign unique names to output files
names(filtFs) <- paste0(sample.names, "F_filt", output_suffix)
names(filtRs) <- paste0(sample.names, "R_filt", output_suffix)

# Run filterAndTrim function
out <- tryCatch({
  filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c(220,200),
                maxN=0, maxEE=c(3,3), rm.phix=TRUE,
                compress=TRUE, multithread=TRUE)
}, error = function(e) {
  warning("An error occurred during processing:", conditionMessage(e))
  NULL
})

print(out)

errF <- learnErrors(filtFs, multithread=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE)
derepFs <- derepFastq(filtFs, verbose=TRUE)
derepRs <- derepFastq(filtRs, verbose=TRUE)
# Name the derep-class objects by the sample names
names(derepFs) <- sample.names
names(derepRs) <- sample.names
dadaFs <- dada(derepFs, err=errF, multithread=TRUE)
dadaRs <- dada(derepRs, err=errR, multithread=TRUE)
mergers <- mergePairs(dadaFs, derepFs, dadaRs, derepRs, verbose=TRUE)
# Inspect the merger data.frame from the first sample
head(mergers[[1]])
seqtab <- makeSequenceTable(mergers)
dim(seqtab)
file_path <- file.path(path, "filtered")  # Updated to set the file path correctly
file_name_4 <- "seqtab.csv"

file_4 <- file.path(file_path, file_name_4)

write.csv(seqtab, file=file_4)
table(nchar(getSequences(seqtab)))

seqtab.nochim <- removeBimeraDenovo(seqtab, method="consensus", multithread=TRUE, verbose=TRUE)
dim(seqtab.nochim)
file_name_5 <- "seqtab_nochime.csv"

file_5 <- file.path(file_path, file_name_5)
write.csv(seqtab.nochim, file=file_5)
table(nchar(getSequences(seqtab.nochim)))  # Corrected from using seqtab to seqtab.nochim


end_time <- Sys.time()  # End time

# Calculate the time difference
time_taken <- end_time - start_time
time_taken
print(paste("Time taken: ", time_taken))
