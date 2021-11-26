---
layout: page
title: "Development"
permalink: /development/
nav_order: 5
has_children: true
---

## Development

```
git clone https://github.com/genepi/gwas-regenie
cd gwas-regenie
docker build -t genepi/gwas-regenie . # don't ignore the dot
nextflow run main.nf -profile test,development
```
