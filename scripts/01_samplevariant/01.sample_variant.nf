// TODO: make sure parameters exist
// TODO: default sensible parameters? maybe a test data directory?
// TODO: single log file

params.infile = "../data/als_sub.vcf.gz"
params.outdir = "$baseDir/../../results"
params.famfile = "../data/subset.fam"
params.highldregion = "../data/highldregion_37.txt" // TODO: update me 

log.info """\
         snpQT step01: sample variant quality control
         input file: ${params.infile}
         outdir: ${params.outdir}
         fam file: ${params.famfile}
         """
         .stripIndent()

Channel
    .fromPath( params.infile )
    .ifEmpty { error "Cannot find: ${params.infile}" }
    .set { in_file } 

Channel
    .fromPath( params.famfile )
    .ifEmpty { error "Cannot find: ${params.famfile}" }
    .set { fam_file } 

Channel
    .fromPath( params.highldregion )
    .ifEmpty { error "Cannot find: ${params.highldregion}" }
    .set { high_ld_file } 


// STEP B1: Remove SNPs < 90% missingness --------------------------------------
process missingness {
  echo true

  input:
  file in_file
  file fam_file

  output:
  file "missingness.log" into missingness_logs
  file "plink_1*" into missingness_bfiles

  """
  plink --make-bed --vcf $in_file --out data &>/dev/null
  # the input stage will change as the pipeline is developed 
  echo 'Pipeline input: ' && grep 'pass' data.log
  cp $fam_file data.fam
  echo 'Step B1: missingness' >> log.txt
  plink --bfile data --geno 0.1 --make-bed  --out plink_1 &>/dev/null
  echo 'Missingness output: ' && grep 'pass' plink_1.log
  cat *.log > missingness.log
  """
}

// STEP B2: Check missingness rate ---------------------------------------------
// TODO: user set threshold
process plot_missingness {
  echo true
  publishDir params.outdir, mode: 'copy', overwrite: true, 
      pattern: "*.png"

  input:
  file missingness_bfiles

  output:
  file "sample_missingness.png"
  file "plink.imiss" into imiss_relatedness
  file "plink_3*" into missingness_bfiles_pruned

  """
  plink --bfile plink_1 --missing --out plink_2 &>/dev/null
  plot_sample_missingness.R plink_2.imiss
  # TODO user set mind threshold 
  plink --bfile plink_1  --make-bed --mind 0.02 --out plink_3 &>/dev/null
  mv plink_2.imiss plink.imiss # run_IBD_QC.pl
  """
}

// STEP B3: Remove samples with sex mismatch -----------------------------------
process check_sex {
    echo true

    input:
    file missingness_bfiles_pruned

    output:
    file "plink.sexcheck" into sexcheck 
    file "data_clean.bed" into sex_checked_bed
    file "data_clean.bim" into sex_checked_bim
    file "data_clean.fam" into sex_checked_fam

    // vcf to bed + fam https://www.biostars.org/p/313943/
    """
    plink --bfile plink_3 --check-sex &>/dev/null

    # Identify the samples with sex discrepancy 
    grep "PROBLEM" plink.sexcheck | awk '{print \$1,\$2}'> \
      problematic_samples.txt
    # Delete all problematic samples
    plink --bfile plink_3 --remove problematic_samples.txt --make-bed \
      --out data_clean &>/dev/null
    echo 'Check sex output: ' && grep 'pass' data_clean.log
    """
}

process plot_sex {
    publishDir params.outdir, mode: 'copy', overwrite: true

    input:
    file sexcheck 

    output:
    file "sexcheck.png"

    """
    plot_sex.R $sexcheck
    """
}

// STEP B4: Remove sex chromosomes ---------------------------------------------
process extract_autosomal {
    echo true

    input:
    file sex_checked_bed   
    file sex_checked_bim
    file sex_checked_fam

    output:
    file "autosomal.*" into autosomal, autosomal_het

    """
    # Extract only autosomal chromosomes (for studies that don't want to 
    # include sex chromosomes)
    awk '{ if (\$1 >= 1 && \$1 <= 22) print \$2 }' $sex_checked_bim > \
      autosomal_SNPs.txt 
    plink --bfile data_clean --extract autosomal_SNPs.txt --make-bed \
      --out autosomal &>/dev/null
    echo 'Extract autosomal output:' && grep 'pass' autosomal.log
    """ 
}

// STEP B5: Remove SNPs with extreme heterozygosity ----------------------------
process heterozygosity_rate {
    input:
    file high_ld_file 
    file autosomal

    output:
    file "only_indep_snps*" into plot_het
    file "independent_SNPs.prune.in" into ind_SNPs, ind_SNPs_popstrat

    """
    plink --bfile autosomal --exclude $high_ld_file --indep-pairwise 50 5 0.2 \
      --out independent_SNPs --range 
    plink --bfile autosomal --extract independent_SNPs.prune.in --het \
      --out only_indep_snps 
    """
}

process plot_heterozygosity { 
    publishDir params.outdir, mode: 'copy', overwrite: true, 
      pattern: "*.png"

    input: 
    file plot_het

    output:
    file "het_failed_samples.txt" into het_failed
    file "heterozygosity_rate.png"

    """
    plot_heterozygosity.R
    """
}

process heterozygosity_prune {
    echo true

    input:
    file autosomal_het
    file het_failed

    output:
    file "het_pruned.*" into het_pruned

    """
    cut -f 1,2 $het_failed > het_failed_plink.txt
    plink --bfile autosomal --make-bed --out het_pruned --remove \
      het_failed_plink.txt &>/dev/null
    echo 'Check heterozygosity rate:' && grep 'pass' het_pruned.log
    """
}

// STEP B6: Remove relatives ---------------------------------------------------
process relatedness {
    echo true
    container 'snpqt'
  
    input:
    file het_pruned
    file ind_SNPs
    file imiss_relatedness

    output:
    file "pihat_pruned*" into relatedness

    """
    plink --bfile het_pruned --extract $ind_SNPs --genome --min 0.125 \
      --out pihat_0.125 &>/dev/null
    # Identify all pairs of relatives with pihat > 0.125 and exclude one of the
    # relatives of each pair, having the most missingness. Output those failing
    # samples to pihat_failed_samples.txt
    run_IBD_QC.pl &>/dev/null
    plink --bfile het_pruned --remove pihat_failed_samples.txt \
      --make-bed --out pihat_pruned &>/dev/null
    echo 'Check relatedness:' && grep 'pass' pihat_pruned.log
    """
}

// STEP B7: Remove samples with missing phenotypes -----------------------------
process missing_phenotype {
    echo true
    container 'snpqt'

    input:
    file relatedness

    output:
    file "missing*" into missing_pheno, missing_pop_strat

    """
    plink --bfile pihat_pruned --prune --make-bed --out missing &>/dev/null
    echo 'Remove missing phenotypes:' && grep 'pass' missing.log 
    """
}

// STEP B8: Missingness per variant --------------------------------------------
// TODO

// STEP B9: Hardy_Weinberg equilibrium (HWE) -----------------------------------
// TODO

// STEP B10: Remove low minor allele frequency (MAF) ---------------------------
// TODO

// STEP B11: Test missingness in case / control status -------------------------
// TODO

// Finished! ------------------------------------------------------------------