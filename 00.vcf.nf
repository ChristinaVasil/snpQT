params.infile = "../data/format_8.vcf"
params.outdir = "$baseDir/results"
params.ref_fasta = "../data/human_g1k_v37.fasta"

log.info """\
         snpQT: make your SNPs cute 
         input file: ${params.infile}
         outdir: ${params.outdir}
         """
         .stripIndent()

Channel
    .fromPath( params.infile )
    .ifEmpty { error "Cannot find: ${params.infile}" }
    .set { in_file } 

// STEP A1 --------------------------------------------------------------------
process convert_VCF {
    echo true
    container 'snpqt'
    publishDir "$baseDir/results", mode: 'copy', overwrite: true, 
      pattern: "*.pdf"

    input:
    file in_file

    output:
    file "dataset_2.bim" into dataset_2_bim
    file "dataset_2.bed" into dataset_2_bed
    file "dataset_2.fam" into dataset_2_fam
    file "dataset_2*" into dataset_2

    """
    plink --vcf $in_file --make-bed --keep-allele-order --out dataset_2 &>/dev/null
    """
}

reference_fasta = Channel.fromPath(params.ref_fasta).collect()
    
process flip_snp {
    echo true
    container 'snpqt'

    input:
    file dataset_2_bim
    file reference_fasta

    output:
    file "snpflip.reverse" into snpflip_reverse
    file "snpflip.ambiguous"
    file "snpflip.annotated_bim"

    """
    snpflip -b $dataset_2_bim -f $reference_fasta -o snpflip
    """
}

process SNP_flip_PLINK {
    echo true
    container 'snpqt'

    input:
    file dataset_2 
    file snpflip_reverse

    output:
    file "dataset_3*" into dataset_3

    """
    plink --bfile dataset_2 --flip $snpflip_reverse --make-bed --out dataset_3
    """
 }

process plink_to_vcf {
    echo true
    container 'snpqt'

    input:
    file dataset_3

    output:
    file "dataset_4.vcf" into dataset_4_vcf
    file "dataset_4.log" 
    file "dataset_4.nosex"

    """
    plink --bfile dataset_3 --recode vcf --keep-allele-order --out dataset_4
    """
}

process vcf_gz {
    echo true
    container 'snpqt'

    input:
    file dataset_4_vcf

    output:
    file "dataset_4.vcf.gz" into dataset_5

    """
    bgzip -c $dataset_4_vcf > dataset_4.vcf.gz
    """
}

process vcf_index {
    echo true
    container 'snpqt'

    input:
    file dataset_5

    """
    bcftools index $dataset_5
    """
}