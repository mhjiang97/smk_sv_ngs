rule hard_filter:
    input:
        vcf="{caller}/{sample}/{sample}.duphold.vcf",
    output:
        vcf="{caller}/{sample}/{sample}.duphold.filtered.vcf",
    params:
        min_size=config["min_size"],
        min_reads=config["min_reads"],
        min_coverage=config["min_coverage"],
        min_dhffc=config["min_dhffc"],
        max_dhbfc=config["max_dhbfc"],
    log:
        "logs/{sample}/hard_filter.{caller}.log",
    script:
        "../../scripts/hard_filter.sh"
