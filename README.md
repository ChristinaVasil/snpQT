[![nextflow](https://img.shields.io/badge/nextflow-%E2%89%A521.04.3-brightgreen.svg)](http://nextflow.io)
[![MIT license](https://img.shields.io/github/license/nebfield/snpqt)](https://raw.githubusercontent.com/nebfield/snpQT/master/LICENSE.md)
[![Documentation Status](https://readthedocs.org/projects/ansicolortags/badge/?version=latest)](https://snpqt.readthedocs.io/en/latest/)
[![DOI](https://zenodo.org/badge/227099400.svg)](https://zenodo.org/badge/latestdoi/227099400)

# snpQT

<p align="center">
  <a href="https://snpqt.readthedocs.io/en/latest/">
  <img width="300" height="300" src="https://raw.githubusercontent.com/nebfield/snpQT/master/docs/img/logo.png">
  </a>
</p>

snpQT (pronounced snip-cutie) makes your single-nucleotide polymorphisms cute. Also, it provides support for processing human genomic variants to do:
* human genome build conversion (b37 -> b38 and/or b38 -> b37)
* sample quality control
* population stratification
* variant quality control
* pre-imputation quality control
* local imputation
* post-imputation quality control
* genome-wide association studies

within an automated nextflow pipeline. We run a collection of versioned
bioinformatics software in Singularity and Docker containers or Anaconda and Environment Modules environments to
improve reliability and reproducibility.

## Who is snpQT for?

`snpQT` might be useful for you if:

* you want a clean genomic dataset using a reproducible, fast and comprehensive pipeline
* you are interested to identify significant SNP associations to a trait
* you want to identify and remove outliers based on their ancestry
* you wish to perform imputation locally
* you wish to prepare your genomic dataset for imputation in an external server (following a comprehensive QC and a pre-imputation QC preparation)

## What do you need to get started?

* you have already called your variants using human genome build 37 or 38
* your variants are in VCF or `plink` bfile format
* your variants have "rs" ids
* your samples have either a binary or a quantitative phenotype

If this sounds like you, check out our online documentation at: https://snpqt.readthedocs.io/en/latest/

`snpQT` definitely won't be useful for you if:

* you want to do quality control on raw sequence reads 
* you want to call variants from raw sequence reads 
* you are working on family GWAS data
* you're not working with human genomic data 

## Citation

If you find `snpQT` useful please cite:

Vasilopoulou C, Wingfield B, Morris AP and Duddy W. snpQT: flexible, reproducible, and comprehensive quality control and imputation of genomic data [version 2; peer review: 2 approved, 1 approved with reservations]. F1000Research 2021, 10:567 [https://doi.org/10.12688/f1000research.53821.2](https://doi.org/10.12688/f1000research.53821.2)

## License and third-party software 

`snpQT` is distributed under [an MIT license](https://github.com/nebfield/snpQT/blob/master/LICENSE.md). Our pipeline wouldn't be possible without the following amazing third-party software:

| Software                                                        | Version   | Reference                                                                                                                                                                   | License            |
|-----------------------------------------------------------------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------|
| [EIGENSOFT](https://www.hsph.harvard.edu/alkes-price/software/) | 7.2.1     | Price, Alkes L., et al. "Principal components analysis corrects for stratification in genome-wide association studies." Nature genetics 38.8 (2006): 904-909.               | Custom open source |
| [impute5](https://www.dropbox.com/sh/mwnceyhir8yze2j/AADbzP6QuAFPrj0Z9_I1RSmla?dl=0)                       | 1.1.4       | Rubinacci, Simone, Olivier Delaneau, and Jonathan Marchini. "Genotype imputation using the positional burrows wheeler transform." PLoS Genetics 16.11 (2020): e1009049.APA  | Academic use only  |
| [nextflow](https://nextflow.io)                                 | 21.04.3   | Di Tommaso, Paolo, et al. "Nextflow enables reproducible computational workflows." Nature biotechnology 35.4 (2017): 316-319.                                               | GPL3               |
| [picard](https://broadinstitute.github.io/picard/)              | 2.24.0    |                                                                                                                                                                             | MIT                |
| [PLINK](https://www.cog-genomics.org/plink/1.9/)                | 1.90b6.18 | Purcell, Shaun, et al. "PLINK: a tool set for whole-genome association and population-based linkage analyses." The American journal of human genetics 81.3 (2007): 559-575. | GPL3               |
| [PLINK2](https://www.cog-genomics.org/plink/2.0/)               | 2.00a2.3  | Chang CC, Chow CC, Tellier LCAM, Vattikuti S, Purcell SM, Lee JJ (2015) Second-generation PLINK: rising to the challenge of larger and richer datasets. GigaScience, 4.     | GPL3               |
| [samtools](https://samtools.github.io)                          | 1.11      | Danecek, Petr et al. "Twelve years of SAMtools and BCFtools." GigaScience, 10(2), 1-4, 2021                                                                                                                                                                           | MIT                |
| [bcftools](https://samtools.github.io/bcftools/bcftools.html)   |     1.9      | Danecek, Petr et al. "Twelve years of SAMtools and BCFtools." GigaScience, 10(2), 1–4, 2021 | MIT                |
| [shapeit4](https://odelaneau.github.io/shapeit4/)               | 4.1.3     | Delaneau, Olivier, et al. "Accurate, scalable and integrative haplotype estimation." Nature communications 10.1 (2019): 1-10.                                               | MIT                |
| [snpflip](https://github.com/biocore-ntnu/snpflip)              | 0.0.6     |  https://github.com/biocore-ntnu/snpflip                                                                                                                                                                           | MIT                |

We also use countless other bits of software like R, the R tidyverse, etc. 

Full documentation is available at: https://snpqt.readthedocs.io/en/latest/
