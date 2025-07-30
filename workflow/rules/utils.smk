import logging
from pathlib import Path

from rich.console import Console
from rich.logging import RichHandler


# *--------------------------------------------------------------------------* #
# * Functions to get input files and parameters                              * #
# *--------------------------------------------------------------------------* #
def get_targets():
    targets = []

    targets += [
        f"survivor/{sample}/final/{sample}.{type_sv}.merged.vcf"
        for sample in SAMPLES
        for type_sv in TYPES_SV
    ]

    if TO_CLEAN_FQ:
        targets += [f"fastp/{sample}/{sample}.json" for sample in SAMPLES]
        if TO_RUN_FASTQC:
            targets += [f"fastqc/fastp/{sample}" for sample in SAMPLES]
        if TO_RUN_MULTIQC:
            targets += ["multiqc/fastp/multiqc_report.html"]
    else:
        if TO_RUN_FASTQC:
            targets += [f"fastqc/{sample}" for sample in SAMPLES]
        if TO_RUN_MULTIQC:
            targets += ["multiqc/multiqc_report.html"]

    return targets


def get_fastq_files(wildcards):
    sample = wildcards.sample
    dir_base = "fastp/{sample}" if TO_CLEAN_FQ else DIR_DATA

    return {
        "fq_1": f"{dir_base}/{{sample}}{SUFFIX_READ_1}",
        "fq_2": f"{dir_base}/{{sample}}{SUFFIX_READ_2}",
    }


def format_genome(genome):
    if genome == "hg19":
        return "GRCh37"
    elif genome == "hg38":
        return "GRCh38"
    else:
        return genome


def format_survivor_parameters(parameter):
    return 1 if parameter else 0


# *--------------------------------------------------------------------------* #
# * Functions to validate files in the config file                           * #
# *--------------------------------------------------------------------------* #
def validate_files(config, parameters):
    for param in parameters:
        paths = config[param]
        paths = [paths] if isinstance(paths, str) else paths

        missing = [p for p in paths if not Path(p).exists()]
        if missing:
            files = ", ".join(f"[dim]'{f}'[/]" for f in missing)
            logger.error(
                f"[bold red]✖ Missing file(s)[/]: {files} not found for parameter '{param}'."
            )
            logger.info(
                f"[bold cyan]Hint:[/] Please verify the paths in 'config/config.yaml'."
            )
            raise ValueError()


def perform_validations_with_rich(config, file_params):
    root = logging.getLogger()
    old_level = root.level
    old_handlers = root.handlers.copy()

    console = Console()
    logging.basicConfig(
        level=logging.INFO,
        format="%(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[RichHandler(console=console, rich_tracebacks=True, markup=True)],
    )
    logger = logging.getLogger()

    validate_files(config, file_params)

    root.setLevel(old_level)
    root.handlers = old_handlers
