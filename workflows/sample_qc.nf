// Quality control workflow

// enable dsl2
nextflow.preview.dsl = 2

// import modules
include {variant_missingness} from '../modules/qc.nf' // B1
include {individual_missingness} from '../modules/qc.nf' // B2
include {plot_missingness} from '../modules/qc.nf' // B2
include {check_sex} from '../modules/qc.nf' // B3
include {plot_sex} from '../modules/qc.nf' // B3
include {extract_autosomal} from '../modules/qc.nf' // B4
include {heterozygosity_rate} from '../modules/qc.nf' // B5
include {plot_heterozygosity} from '../modules/qc.nf' // B5
include {heterozygosity_prune} from '../modules/qc.nf' // B5
include {relatedness} from '../modules/qc.nf' // B6
include {missing_phenotype} from '../modules/qc.nf' // B7

// workflow component for snpqt pipeline
workflow sample_qc {
  take:
    ch_inbed
    ch_inbim
    ch_infam
    
  main:
    variant_missingness(ch_inbed, ch_inbim, ch_infam)
    individual_missingness(variant_missingness.out.bed, variant_missingness.out.bim, variant_missingness.out.fam)
    plot_missingness(individual_missingness.out.imiss)
    check_sex(individual_missingness.out.bed, individual_missingness.out.bim, individual_missingness.out.fam)
    plot_sex(check_sex.out.sexcheck)
    extract_autosomal(check_sex.out.bed, check_sex.out.bim, check_sex.out.fam)
    Channel
      .fromPath("$baseDir/db/PCA.exclude.regions.b37.txt", checkIfExists: true)
      .set{exclude}
    heterozygosity_rate(extract_autosomal.out.bed, extract_autosomal.out.bim, extract_autosomal.out.fam, exclude)
    plot_heterozygosity(heterozygosity_rate.out.het)
    heterozygosity_prune(extract_autosomal.out.bed, extract_autosomal.out.bim, extract_autosomal.out.fam, plot_heterozygosity.out.failed)
    relatedness(heterozygosity_prune.out.bed, heterozygosity_prune.out.bim, heterozygosity_prune.out.fam, heterozygosity_rate.out.ind_snps, individual_missingness.out.imiss)
    missing_phenotype(relatedness.out.bed, relatedness.out.bim, relatedness.out.fam)

  emit:
    bed = missing_phenotype.out.bed
    bim = missing_phenotype.out.bim
    fam = missing_phenotype.out.fam
    plots = concat(plot_missingness.out.figure, plot_sex.out.figure, plot_heterozygosity.out.figure)
} 