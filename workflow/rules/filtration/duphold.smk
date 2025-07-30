rule duphold:
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.recal.bam",
        fasta=config["fasta"],
    output:
        bcf=temp("{caller}/{sample}/{sample}.sorted.bcf"),
        vcf="{caller}/{sample}/{sample}.duphold.vcf",
    threads: 1
    log:
        "logs/{sample}/duphold.{caller}.log",
    shell:
        """
        {{ bcftools sort -Ou {input.vcf} > {output.bcf}

        export DUPHOLD_SAMPLE_NAME={wildcards.sample}
        duphold \\
            -t {threads} \\
            -v {output.bcf} \\
            -b {input.bam} \\
            -f {input.fasta} \\
            -o {output.vcf}; }} \\
        1> {log} 2>&1
        """
