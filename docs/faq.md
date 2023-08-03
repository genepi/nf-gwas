---
layout: page
title: "FAQ"
nav_order: 7
---

## FAQ

**How are VCF files converted to work with regenie?**

Michigan Imputation Server writes output files in VCF.GZ format. To enable VCF support in combination with regenie, we convert VCF files into the PGEN format. Please note that VCF files cannot be losslessly converted to BGEN.

To validate our approach, we run two GWA studies using (a) the original UK Biobank BGEN files and (b) VCF files created from the original BGEN files as an input (used command: `plink2 --bgen ukb_imp_chr6_v3.bgen ref-first --sample ukbXXX.sample --export vcf-iid bgz vcf-dosage=DS`).

The plot below shows that LOGP10 values between the two executions highly correlate.
![image](images/bgen_vs_vcf.jpg)
