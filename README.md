<!-- markdownlint-configure-file {"no-inline-html": {"allowed_elements": ["code", "details", "h2", "summary"]}} -->

# SMK_SV_NGS

![License GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg)

A Snakemake workflow for structural variant calling from NGS data

<details>

<summary><h2>Recommended Project Structure</h2></summary>

```text
project/
├── analysis/
│   └── wgs/
│       └── ...                # Outputs of this workflow
├── code/
│   └── wgs/
│       └── smk_sv_ngs/        # This workflow
├── data/
│   └── wgs/
│       ├── *_R1.fq.gz         # Paired-end forward reads
│       └── *_R2.fq.gz         # Paired-end reverse reads
└── doc/
```

</details>

**Note:** The workflow expects all FASTQ files to be located in *dir_data* specified in `config/config.yaml`, with no sample-specific subfolders (See [Main Configuration](#main-configuration)).

**Hints:** You can create symbolic links (`ln -s source_file target_file`) pointing to original FASTQ files.

*This structure could enable an organized layout for each project.*

## Prerequisites

- [**Python**](https://www.python.org)
- [**Snakemake**](https://snakemake.github.io) (tested on 9.8.0)
- [**eido**](https://pep.databio.org/eido/)
- [**SAMtools**](https://www.htslib.org)
- [**Mamba**](https://mamba.readthedocs.io/en/latest/) (recommended) or [**conda**](https://docs.conda.io/projects/conda/en/stable/)

Additional dependencies are automatically installed by **Mamba** or **conda**. Environments are defined in yaml files under `workflow/envs/`.

- [**BCFtools**](http://samtools.github.io/bcftools/)
- [**GATK**](https://gatk.broadinstitute.org/hc/en-us)
- [**SnpEff**](https://pcingola.github.io/)
- [**SnpSift**](https://pcingola.github.io/)
- [**vcf2maf**](https://github.com/mskcc/vcf2maf)
- [**VEP**](https://www.ensembl.org/info/docs/tools/vep/index.html)
- [**FastQC**](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [**MultiQC**](https://multiqc.info/)

## Quick Start

```shell
# ---------------------------------------------------------------------------- #
# Install Mamba (if not already installed)                                     #
# ---------------------------------------------------------------------------- #
if ! command -v mamba &> /dev/null; then
    "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
    source ~/.bashrc
fi

# Install Snakemake and eido using pipx (https://pipx.pypa.io/stable/)
pipx install snakemake
pipx inject snakemake eido

# Clone the repository
git clone https://github.com/mhjiang97/smk_sv_ngs.git
cd smk_sv_ngs/

# Initialize configuration
cp config/.config.yaml config/config.yaml
cp config/pep/.config.yaml config/pep/config.yaml
cp workflow/profiles/default/.config.yaml workflow/profiles/default/config.yaml
```

## Configuration

### Main Configuration

<details>

<summary>Edit <code>config/config.yaml</code></summary>

```yaml
dir_run: /projects/project_xxx/analysis/wgs                                                 # Output directory (Optional)
dir_data: /projects/project_xxx/data/wgs                                                    # Directory for raw FASTQ files (Required)

libs_r:                                                                                     # Directories containing installed R packages (Optional)
  - /local/var/R/Rlibrary4/
  - /.condax/r-base/lib/R/library

species: homo_sapiens                                                                       # Species (Default: homo_sapiens)
genome: GRCh37                                                                              # Genome assembly (Default: GRCh37)

mapper: bwamem2                                                                             # Alignment tool (Default: bwamem2)

fasta: /doc/ref/GRCh37/fasta/GRCh37.primary_assembly.genome.fa                              # Genome FASTA file (Required)
index_bwamem2: /doc/tool/mapper/bwamem2/GRCh37/gencode/GRCh37.primary_assembly.genome.fa    # Prefix for bwa-mem2 index files. (Required. If doesn't exist, it will be generated)

polymorphism_known:                                                                         # Known polymorphism VCF files used by GATK BaseRecalibrator (Required)
  - /doc/db/gatkbundle/chr/dbsnp_138.b37.vcf.gz
  - /doc/db/gatkbundle/chr/1000G_phase1.indels.b37.vcf.gz
  - /doc/db/gatkbundle/chr/Mills_and_1000G_gold_standard.indels.b37.vcf.gz
  - /doc/db/gatkbundle/chr/1000G_phase1.snps.high_confidence.b37.vcf.gz

dbsnp: /doc/db/gatkbundle/chr/dbsnp_138.b37.vcf.gz                                         # dbSNP VCF file used by SvABA (Required)

suffixes_fastq:                                                                            # Suffixes for FASTQ files (Defaults: ["_R1.fq.gz", "_R2.fq.gz"])
  - "_R1.fq.gz"
  - "_R2.fq.gz"

clean_fq: true                                                                             # Whether to run Fastp to trim raw FASTQ files (Default: true)
run_fastqc: true                                                                           # Whether to run FastQC to generate quality control reports (Default: true)
run_multiqc: false                                                                         # Whether to run MultiQC to aggregate QC reports (Default: true)

penalty_mismatch: 3                                                                        # Penalty for mismatches in BWA-MEM2 (Default: 3)

cache_vep: /.vep                                                                           # Cache directory for VEP
cache_snpeff: /doc/tool/annotator/snpeff                                                   # Cache directory for SnpEff
version_vep: 114                                                                           # VEP cache version (Default: 114)
version_snpeff: 87                                                                         # SnpEff cache version (Default: "87")
max_size_vep: 50000000                                                                     # Maximum size (bp) of SV to be annotated by VEP (Default: 50,000,000)
max_size_annotsv: 10000000                                                                 # SVs larger than this value (bp) will be annotated in batches by AnnotSV (Default: 10,000,000)
size_chunk: 300                                                                            # Chunk size for annotating large SVs (Default: 300)

min_reads: 3                                                                               # Minimum number of reads supporting a structural variant (Default: 3)
min_coverage: 6                                                                            # Minimum coverage for structural variant calling (Default: 6)
min_quality_mapping: 20                                                                    # Minimum mapping quality for reads (Default: 20)
min_size: 50                                                                               # Minimum size of structural variants (Default: 50)
min_dhffc: 0.7                                                                             # Minimum duphold's DHFFC for structural variants (Default: 0.7)
max_dhbfc: 1.3                                                                             # Maximum duphold's DHBFC for structural variants (Default: 1.3)

distance_sv:                                                                               # Maximum distance between breakpoints when merging SVs from different callers (Default: {"DEL": 10, "INS": 10, "INV": 10, "BND": 10, "DUP": 10})
  BND: 10
  DEL: 10
  INS: 10
  INV: 10
  DUP: 10
n_callers:                                                                                 # Number of callers to be merged (Default: {"BND": 3, "DEL": 2, "INS": 2, "INV": 2, "DUP": 2})
  BND: 3
  DEL: 2
  INS: 2
  INV: 2
  DUP: 2
consider_type:                                                                             # Whether to consider the type of structural variants when merging (Default: {"BND": false, "DEL": false, "INS": false, "INV": false, "DUP": false})
  BND: false
  DEL: false
  INS: false
  INV: false
  DUP: false
consider_strand:                                                                           # Whether to consider the strand of reads when merging structural variants (Default: {"BND": false, "DEL": false, "INS": false, "INV": false, "DUP": false})
  BND: false
  DEL: false
  INS: false
  INV: false
  DUP: false
estimate_distance:                                                                         # Whether to estimate the distance between breakpoints when merging structural variants (Default: {"BND": true, "DEL": true, "INS": true, "INV": true, "DUP": true})
  BND: true
  DEL: true
  INS: true
  INV: true
  DUP: true

terms_relative: leuka?emia|blood|lymph|myelo|ha?ema|marrow|platel|thrombo|anemia|neutro    # Keywords of interest - SVs associated with these terms will be rescued from filtering (Optional)

bed_exclude: /local/opt/gridss/example/chr/ENCFF001TDO.bed                                 # BED file with regions to exclude from SV calling used by GRIDSS (Required)
jar_gridss: /local/opt/gridss/gridss-2.13.2-gridss-jar-with-dependencies.jar               # GRIDSS JAR file (Required)
```

</details>

### Execution Profile

<details>

<summary>Edit <code>workflow/profiles/default/config.yaml</code></summary>

```yaml
software-deployment-method:
  - conda
conda-prefix: /.snakemake/envs/smk_sv_ngs
printshellcmds: True
keep-incomplete: True
cores: 80
resources:
  mem_mb: 500000  # 500GB
  n_instance: 1
default-resources:
  mem_mb: 5000  # 5GB
set-threads:
  fastp: 4
  fastqc: 4
  bwamem2: 10
  manta: 10
  tiddit: 10
  wham: 10
  gridss: 10
  svaba: 10
  duphold: 5
  vep: 5
  filter_annotations: 20
set-resources:
  mark_duplicates:
    mem_mb: 100000  # 100GB
  base_recalibrator:
    mem_mb: 50000  # 50GB
  apply_bqsr:
    mem_mb: 50000  # 50GB
  gridss:
    mem_mb: 50000  # 50GB
    mem_mb_other: 10000  # 10GB
  snpeff:
    mem_mb: 50000  # 50GB
```

</details>

### Sample Metadata

This workflow uses [**Portable Encapsulated Projects (PEP)**](https://pep.databio.org/) for sample management.

<details>

<summary>Edit <code>config/pep/config.yaml</code></summary>

```yaml
pep_version: 2.1.0
sample_table: samples.csv    # Path to the sample table (Required)
```

</details>

The sample table must include these mandatory columns:

| **sample_name**                   |
| --------------------------------- |
| Unique identifier for each sample |

## Execution

```shell
# Create environments
snakemake --conda-create-envs-only

# Run the workflow
snakemake
```

## Output

By default, all results are written to the directory you specify as *dir_run* (or to `workflow/` if *dir_run* is unset).

<details>

<summary>Main results</summary>

- **fastp/**
  - Trimmed reads: `{sample}/{sample}<_R1/_R2>.fq.gz`

- **fastqc/**
  - Raw reads: `{sample}/{sample}<_1/_2>_fastqc.html`
  - Trimmed reads: `fastp/{sample}/{sample}<_1/_2>_fastqc.html`

- **multiqc/**
  - Pre-trimming summary: `multiqc_report.html`
  - Post-trimming summary: `fastp/multiqc_report.html`

- **{mapper}/**
  - BAM: `{sample}/{sample}.sorted.bam`
  - Duplicates marked BAM: `{sample}/{sample}.sorted.md.bam`
  - Base recalibrated BAM: `{sample}/{sample}.sorted.md.recal.bam`

- **{caller}/**
  - VCF: `{sample}/{sample}.vcf`

- **survivor/**
  - Final merged VCFs: `{sample}/final/{sample}.{type_sv}.merged.vcf`

</details>

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).
