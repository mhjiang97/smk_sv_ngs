rule manta:
    conda:
        "../../envs/manta.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.recal.bam",
        fasta=config["fasta"],
    output:
        config="manta/{sample}/config.ini",
        script="manta/{sample}/runWorkflow.py",
        workspace=directory("manta/{sample}/workspace"),
        vcf=protected("manta/{sample}/results/variants/tumorSV.vcf.gz"),
        vcf_renamed=protected("manta/{sample}/{sample}.vcf"),
    params:
        min_reads=config["min_reads"],
    threads: 1
    log:
        "logs/{sample}/manta.log",
    shell:
        """
        {{ {{ echo "[manta]"
        echo "referenceFasta = {input.fasta}"
        echo "minCandidateVariantSize = 8"
        echo "rnaMinCandidateVariantSize = 1000"
        echo "minEdgeObservations = 3"
        echo "graphNodeMaxEdgeCount = 10"
        echo "minCandidateSpanningCount = {params.min_reads}"
        echo "minScoredVariantSize = 50"
        echo "minDiploidVariantScore = 10"
        echo "minPassDiploidVariantScore = 20"
        echo "minPassDiploidGTScore = 15"
        echo "minSomaticScore = 10"
        echo "minPassSomaticScore = 30"
        echo "enableRemoteReadRetrievalForInsertionsInGermlineCallingModes = 1"
        echo "enableRemoteReadRetrievalForInsertionsInCancerCallingModes = 0"
        echo "useOverlapPairEvidence = 0"
        echo "enableEvidenceSignalFilter = 1"; }} \\
        > {output.config}

        out_dir=$(dirname {output.config})
        configManta.py --config {output.config} --referenceFasta {input.fasta} --tumorBam {input.bam} --runDir ${{out_dir}}

        {output.script} -j {threads}

        gunzip -c {output.vcf} > {output.vcf_renamed}; }} \\
        1> {log} 2>&1
        """
