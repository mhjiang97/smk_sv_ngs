rule base_recalibrator:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.bam",
        fasta=config["fasta"],
    output:
        table=protected(f"{MAPPER}/{{sample}}/{{sample}}.recal.table"),
    params:
        polymorphism_known=config["polymorphism_known"],
    resources:
        mem_mb=1,
    log:
        "logs/{sample}/base_recalibrator.log",
    shell:
        """
        {{ known_sites=""
        for site in {params.polymorphism_known}; do
            known_sites="${{known_sites}} --known-sites ${{site}}"
        done

        gatk BaseRecalibrator \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --input {input.bam} --output {output.table} \\
            --reference {input.fasta} ${{known_sites}}; }} \\
        1> {log} 2>&1
        """


rule apply_bqsr:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.bam",
        table=f"{MAPPER}/{{sample}}/{{sample}}.recal.table",
        fasta=config["fasta"],
    output:
        bam=protected(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.recal.bam"),
        bai=temp(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.recal.bai"),
        bai_renamed=protected(
            f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.recal.bam.bai"
        ),
    resources:
        mem_mb=1,
    log:
        "logs/{sample}/apply_bqsr.log",
    shell:
        """
        {{ gatk ApplyBQSR \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --input {input.bam} --output {output.bam} \\
            --bqsr-recal-file {input.table} --reference {input.fasta}

        cp {output.bai} {output.bai_renamed}
        touch {output.bai_renamed}; }} \\
        1> {log} 2>&1
        """
