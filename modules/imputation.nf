// Pre-imputation 
// =============================================================================

// STEP D2: Remove ambiguous SNPs ---------------------------------------------
// STEP D4: Flip reverse SNPs
// note: taken care of by popstrat modules now

// STEP D3: Remove one of each pair of duplicated SNPs 
process fix_duplicates {
    input:
    path(bed)
    path(bim)
    path(fam)

    output:
    path "D3.bed", emit: bed
    path "D3.bim", emit: bim
    path "D3.fam", emit: fam
    
    shell:
    '''
    # D3: duplicates
    plink --bfile !{bed.baseName} \
      --list-duplicate-vars ids-only suppress-first
    
    plink --bfile !{bed.baseName} \
      --exclude plink.dupvar \
      --make-bed \
      --out D3
    '''
}

// STEP D5: Convert Plink file into VCF ---------------------------------------
// STEP D6: bgzip VCF and then VCF needs to be indexed/sorted 
// STEP D7: Convert .vcf.gz file to .bcf file ---------------------------------

process to_bcf {
    input:
    path(bed)
    path(bim)
    path(fam)

    output:
    path "D7.bcf", emit: bcf

    shell:
    '''
    plink --bfile !{bed.baseName} \
        --recode vcf bgz \
        --keep-allele-order \
        --out D6
    bcftools convert -Ou D6.vcf.gz > D7.bcf
    '''
}

// STEP D8: Check and fix the REF allele --------------------------------------

process check_ref_allele {
    input:
    path(bcf)
    path(db)

    output:
    path "D8.bcf", emit: bcf

    shell:
    '''
    # extract specific file from db
    dbSNP=!{db}"/All_20180423.vcf.gz"
    g37=!{db}"/human_g1k_v37.fasta"
   
    bcftools +fixref !{bcf} \
        -Ob -o D8.bcf -- \
        -d -f $g37 \
        -i $dbSNP
    '''
}

// STEP D9: Sort the BCF ------------------------------------------------------
// STEP D10: Convert .bcf file to .vcf.gz file --------------------------------
// STEP D11: Index the vcf.gz -------------------------------------------------

process bcf_to_vcf {
    input:
    path(bcf)
    
    output:
    path "D11.vcf.gz", emit: vcf
    path "D11.vcf.gz.csi", emit: idx
    
    shell:
    '''
    bcftools sort !{bcf} | bcftools convert -Oz > D11.vcf.gz
    bcftools index D11.vcf.gz     
    '''
}

// STEP D12: Split vcf.gz file in chromosomes ---------------------------------
// STEP D13: Index all chroms .vcf.gz -----------------------------------------
process split_user_chrom {
    input:
    path(vcf)
    path(idx)
    each chr
    
    output:
    tuple val(chr), file('D12.vcf.gz'), file('D12.vcf.gz.csi'), emit: chrom 

    shell:
    '''
    bcftools view -r !{chr} !{vcf} -Oz -o D12.vcf.gz
    bcftools index D12.vcf.gz
    '''
}

// STEP D14: Perform phasing using shapeit4 -----------------------------------
// STEP D15: Index phased chromosomes -----------------------------------------

process phasing {
    container 'shapeit4' 

    input:
    tuple val(chr), file('D12.vcf.gz'), file('D12.vcf.gz.csi'), \
        file('genetic_maps.b37.tar.gz')  

    output:
    tuple val(chr), file('D14.vcf.gz'), file('D14.vcf.gz.csi'), emit: chrom

    shell:
    '''
    tar -xzf genetic_maps.b37.tar.gz
    gunzip chr!{chr}.b37.gmap.gz # decompress the chromosome we need 
    
    shapeit4 --input D12.vcf.gz \
        --map chr!{chr}.b37.gmap \
        --region !{chr} \
        --thread 1 \
        --output D14.vcf.gz \
        --log log_chr.txt     

    bcftools index D14.vcf.gz
    '''
}

// Imputation 
// =============================================================================
// Note: STEP D16 is taken care of by Dockerfile 
// STEP D17: Convert vcf reference genome into a .imp5 format for each chromosome

// extract chromosome digit from file name
// toInteger important for join()

process convert_imp5 { 
    container 'impute5'
    
    input:
    tuple val(chr), file('ref_chr.vcf.gz.csi'), file('ref_chr.vcf.gz') 

    output:
    tuple val(chr), file('1k_b37_reference_chr.imp5'), \
        file('1k_b37_reference_chr.imp5.idx'), emit: chrom

    shell:
    '''
    imp5Converter --h ref_chr.vcf.gz \
        --r !{chr} \
        --o 1k_b37_reference_chr.imp5
    '''
}

// STEP D18: Perform imputation using impute5 ---------------------------------
// join phased vcfs with imp5 based on chrom value 
// then combine so each tuple element has a shapeit4 map file 

process impute5 {
    container 'impute5'

    input:
    tuple chr, file('1k_b37_reference_chr.imp5'), \
        file('1k_b37_reference_chr.imp5.idx'), file('D14.vcf.gz'), \
        file('D14.vcf.gz.csi'), file('genetic_maps.b37.tar.gz') 
       
    output:
    path "imputed_chr${chr}.vcf.gz", emit: imputed

    shell:
    '''
    tar -xzf genetic_maps.b37.tar.gz
    gunzip chr!{chr}.b37.gmap.gz # decompress the chromosome we need 
    impute5 --h 1k_b37_reference_chr.imp5 \
        --m chr!{chr}.b37.gmap \
        --g D14.vcf.gz \
        --r !{chr} \
        --out-gp-field \
        --o imputed_chr!{chr}.vcf.gz
    '''
}

// Finished!

