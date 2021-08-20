# Parameter file

The parameter file controls nearly every part of the `snpQT` pipeline, including:

* The input data location
* Which combination of workflows to run (imputation, quality control, etc.)
* Parameters for important workflow processes 
* The output data location

It's important that you understand what each parameter means. Different data
sets will require different parameters if you want to do sensible quality
control and analysis.

We recommend using a parameter file instead of specifying parameters at the
[command line](https://www.nextflow.io/docs/latest/config.html) because:

* You'll have a permanent record of your specified parameters. If you wanted to
  publish an analysis you could include this file as a supplement.
* `snpQT` has a lot of parameters. Specifying them all on the command line can
  be confusing!

To make things easier we have provided an example parameters.yaml file with
`snpQT`:

```
---
  # input parameters -----------------------------------------------------------
  # fam filepath is mandatory for all workflows
  fam: 'data/toy.fam'

  # if you're doing build conversion, input data needs to be a VCF filepath
  # (otherwise set to false)
  vcf: 'data/toy.vcf.gz'

  # if you're not doing build conversion, input data needs a bed / bim filepath
  bed: false
  bim: false
  
  # output parameters ----------------------------------------------------------
  results: "$baseDir/results/"
  
  # workflow parameters --------------------------------------------------------
  convert_build: false
  qc: false
  pop_strat: false 
  impute: false
  pre_impute: false
  post_impute: false
  gwas: false

  # build conversion parameters ------------------------------------------------
  input_build: 38
  output_build: 37
  mem: 16

  # qc & popstrat parameters ---------------------------------------------------
  sexcheck: true
  keep_sex_chroms: true
  mind: 0.02
  indep_pairwise: '50 5 0.2'
  variant_geno: 0.02
  king_cutoff: 0.125
  hwe: 1e-7
  maf: 0.05
  missingness: 10e-7
  racefile: super 
  racecode: " "
  parfile: false 
  pca_covars: 3  
  rm_missing_pheno: false 
  heterozygosity: true 

  # gwas parameters ------------------------------------------------------------
  covar_file: false
  linear: false

  # imputation parameters ------------------------------------------------------
  # 128GB memory per chrom
  impute_chroms: 1 

  # postimputation parameters --------------------------------------------------
  info: 0.7
  impute_maf: 0.01

  # dummy parameters to silence nextflow warnings ------------------------------
  help: false
  download_db: false
```
