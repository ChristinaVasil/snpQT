// Imputation workflow
nextflow.preview.dsl = 2

// import modules
include {set_chrom_code} from '../modules/imputation.nf'
include {run_snpflip} from '../modules/popStrat.nf' // D1, reuse C4
include {flip_snps} from '../modules/popStrat.nf' // D2, D4, reuse C4
include {fix_duplicates} from '../modules/imputation.nf' // D3
include {to_bcf} from '../modules/imputation.nf' // D5 - D7
include {check_ref_allele} from '../modules/imputation.nf' // D8
include {bcf_to_vcf} from '../modules/imputation.nf' // D9 - D11
include {parse_logs} from '../modules/qc.nf'

// workflow component for snpqt pipeline
workflow preImputation {
  take:
    ch_bed
    ch_bim
    ch_fam

  main:
    set_chrom_code(ch_bed, ch_bim, ch_fam)
    Channel
      .fromPath("$baseDir/db/h37_squeezed.fasta", checkIfExists: true)
      .set { g37 }
    run_snpflip(set_chrom_code.out.bed, set_chrom_code.out.bim, set_chrom_code.out.fam, g37)
    flip_snps(ch_bed, ch_bim, ch_fam, run_snpflip.out.rev, run_snpflip.out.ambig)
    fix_duplicates(flip_snps.out.bed, flip_snps.out.bim, flip_snps.out.fam)
    to_bcf(fix_duplicates.out.bed, fix_duplicates.out.bim, fix_duplicates.out.fam)
    Channel
      .fromPath("$baseDir/db/All_20180423.vcf.gz", checkIfExists: true)
      .set{ dbsnp }
    Channel
      .fromPath("$baseDir/db/All_20180423.vcf.gz.tbi", checkIfExists: true)
      .set{ dbsnp_idx }
    check_ref_allele(to_bcf.out.bcf, dbsnp, dbsnp_idx, g37)
    bcf_to_vcf(check_ref_allele.out.bcf)
    // logs = fix_duplicates.out.log.concat(to_bcf.out.log).collect()
    // parse_logs("pre_imputation", logs, "pre_imputation_log.txt")

  emit:
    vcf = bcf_to_vcf.out.vcf
	idx = bcf_to_vcf.out.idx

}  
