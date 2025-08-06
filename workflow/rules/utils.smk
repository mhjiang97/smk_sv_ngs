import logging
import os
from math import floor
from pathlib import Path

import yaml
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


def get_annotsv_cache_outputs():
    if SPECIES in ["homo_sapiens"]:
        return {
            "dir_1": f"{config['cache_annotsv']}/Annotations_Human",
            "dir_2": f"{config['cache_annotsv']}/Annotations_Exomiser",
        }
    else:
        raise ValueError("Unsupported species")


def get_annotsv_cache_parameters():
    if SPECIES in ["homo_sapiens"]:
        return {
            "arg_install": "install-human-annotation",
            "dirs": [
                "share/AnnotSV/Annotations_Human",
                "share/AnnotSV/Annotations_Exomiser",
            ],
        }
    else:
        raise ValueError("Unsupported species")


def get_user_name():
    name = os.getenv("USER") or os.getenv("USERNAME") or os.getlogin()

    if not name:
        raise ValueError("Unable to determine user name.")

    return name


# *--------------------------------------------------------------------------* #
# * Functions to validate files in the config file                           * #
# *--------------------------------------------------------------------------* #
def validate_vep_version(config, env_file):
    with open(env_file, "r") as f:
        config_vep = yaml.safe_load(f)

    dependencies = config_vep.get("dependencies", [])
    dependency_vep = next(
        (
            dep
            for dep in dependencies
            if isinstance(dep, str) and dep.startswith("ensembl-vep")
        ),
        None,
    )

    version_vep = dependency_vep.split("=")[1]
    version_env_major = floor(float(version_vep))
    version_config = config["version_vep"]

    if version_env_major != version_config:
        logger.warning(
            f"[bold yellow]⚠ VEP version mismatch detected[/]: "
            f"config = [cyan]{version_config}[/], env = [magenta]{version_env_major}[/]."
        )
        logger.info(
            f"[bold green]Recommendation:[/] Align the VEP version in 'config/config.yaml' with 'workflow/envs/vep.yaml'."
        )


def validate_annotsv_version(config, env_file):
    with open(env_file, "r") as f:
        config_annotsv = yaml.safe_load(f)

    dependencies = config_annotsv.get("dependencies", [])
    dependency_annotsv = next(
        (
            dep
            for dep in dependencies
            if isinstance(dep, str) and dep.startswith("annotsv")
        ),
        None,
    )

    version_annotsv = dependency_annotsv.split("=")[1]
    version_config = config["version_annotsv"].strip("v")

    if version_annotsv != version_config:
        logger.error(
            f"[bold red]✖ Annotsv version mismatch detected[/]: "
            f"config = [cyan]{version_config}[/], env = [magenta]{version_annotsv}[/]."
        )
        logger.info(
            f"[bold green]Recommendation:[/] Align the Annotsv version in 'config/config.yaml' with 'workflow/envs/annotsv.yaml'."
        )
        raise ValueError()


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


def perform_validations_with_rich(config, vep_env_path, annotsv_env_path, file_params):
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

    validate_vep_version(config, vep_env_path)
    validate_annotsv_version(config, annotsv_env_path)
    validate_files(config, file_params)

    root.setLevel(old_level)
    root.handlers = old_handlers
