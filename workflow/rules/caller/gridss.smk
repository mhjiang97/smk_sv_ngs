rule gridss:
    conda:
        "../../envs/gridss.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.recal.bam",
        fasta=config["fasta"],
        bed_exclude=config["bed_exclude"],
        jar=config["jar_gridss"],
    output:
        vcf=temp("gridss/{sample}/tmp.vcf"),
        dir_working_1=temp("gridss/{sample}/tmp.vcf.assembly.bam.gridss.working"),
        dir_working_2=temp(
            "gridss/{sample}/{sample}.sorted.md.recal.bam.gridss.working"
        ),
        dir_working_3=temp("gridss/{sample}/tmp.vcf.gridss.working"),
    threads: 1
    resources:
        mem_mb=1,
        mem_mb_other=1,
        tmpdir=lambda wildcards: f"gridss/{wildcards.sample}",
    log:
        "logs/{sample}/gridss.log",
    shell:
        """
        gridss \\
            -t {threads} \\
            --jvmheap $(({resources.mem_mb} / 1024))g \\
            --otherjvmheap $(({resources.mem_mb_other} / 1024))g \\
            -j {input.jar} \\
            -r {input.fasta} \\
            -b {input.bed_exclude} \\
            -o {output.vcf} \\
            -w {resources.tmpdir} \\
            --skipsoftcliprealignment \\
            {input.bam}
        """


rule format_gridss:
    input:
        vcf="gridss/{sample}/tmp.vcf",
    output:
        vcf="gridss/{sample}/{sample}.vcf",
        rdata="gridss/{sample}/{sample}.RData",
    params:
        genome=config["genome"],
        libs_r=config["libs_r"],
    log:
        "logs/{sample}/format_gridss.log",
    script:
        "../../scripts/add_svtype_svlen.R"
