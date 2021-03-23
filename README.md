# Simulation comparison

## Motivation

Besides being able to evaluate our own developments on `muscat`'s simulation framework, the motivation behind this is three-fold:

1. Though each method includes some comparison to others, to our knowledge,  
there is **no independent benchmark** of scRNA-seq simulators. 
2. Evaluation is mostly limited to one dimension (1D), i.e. comparing 1D distributions.  
**2D comparisons** (e.g. mean-variance) are rarely quantified and (if at all) visual.
3. While many methods claim to be able to simulate **clusters and batches**,  
these capabilities are not benchmarked at all or not thoroughly enough. 

## Setup

### Contents

* `config.yaml` specifies the R library and version to use
* `code` contains all R scripts used in the *Snakemake* workflow
* `data` contains raw, filtered and simulated scRNA-seq datasets,  
as well as simulation parameter estimates
* `results` and `plots` contain all outputs (.rds) and figures (.pdf)
* `config` contains two .json files that specify method (`config/methods.json`) and subset (`config/subsets.json`) configurations

### Methods & datasets

We currently include the following methods:

Name        | clusters  | batches
:---------: | :-------: | :-----:
BASiCS      | no        | yes
scDesign    | no        | no
scDesign2   | yes       | no
splatter    | no        | no
SPsimSeq    | no        | yes
SymSim      | no        | yes
POWSC       | yes       | no
powsimR     | no        | no

*Note that we did not evaluate `splatter`'s ability to simulate batches and clusters, since it cannot estimate cluster-/batch-effects from a reference data and relies entirely one user-defined input parameters.*

...and datasets:

Name        | clusters  | batches
:---------: | :-------: | :-----:
CellBench   | 3         | 3
Kang18      | 6         | 8
Mereu20     | 7         | 13
panc8       | 9         | 5

Methods are tagged with one or many of the following labels, according to which scenario(s) they can accommodate: 

* `n` for none: no clusters or batches
* `b` for batch: multiple batches, no clusters
* `k` for cluster: multiple clusters, no batches

Similarly, we tag dataset subsets (see below) with one of these labels. This allows running each method on subsets they are capable of simulating.

## Computational workflow

### Preprocessing

**1. Data retrieval**

Each `code/00-get_data-<dataset_id>.R` script retrieves a publicly available scRNA-seq dataset through from which a *SingleCellExperiment* is constructed and written to `data/00-raw/<dataset_id>.rds`

**2. Filtering**

`code/01-fil_data.R` is applied to each raw dataset as to 

  * retain only cell metadata (`colData` columns) of interest, i.e. cluster and batch identifiers
  * exclude cluster, batches or cluster-batch combinations with fewer than 50 cells (depending on the dataset's complexity)
  * keep genes with a count of at least 1 in at least 10 cells, and remove cells with fewer than 100 detected genes 
  
Filtered data are written to `data/01-fil/<dataset_id>.rds`

**3. Subsetting**

Because different methods can accommodate only some features (e.g. multiple clusters or batches, both or neither), `code/02-sub_data.R` creates specific subsets in `data/02-sub/<dataset_id>.<subset_id>,rds`. We term these *ref(erence)set*s (i.e. `<dataset_id>.<subset_id> = <refset_id>`), as they serve as the input reference data for simulation

### Simulation

**1. Parameter estimation**

Simulation parameters are estimated with `code/03-est_pars.R`, which in term sources a `code/03-est_pars-<method_id>.R` script that executes a method's parameter estimation function(s). In cases where no separate estimation takes place, this returns NULL. Parameter estimates for each combination of refset and method are written to `data/04-est/<refset_id>,<method_id>.rds`.

**2. Data simulation**

Data is simulated with `code/04-sim_data.R`, which in term sources a `code/04-sim_data-<method_id>.R` script that executes a method's simulation function. Simulations for each combination of refset and method are written to `data/05-sim/<refset_id>,<method_id>.rds`.

### Quality control

Various quality control (QC) metrics are calculated with `code/05-calc_qc.R`, which in term sources a set of `code/05-gene/cell_qc-<metric_id>.R` scripts. QC results for reference and simulated data are written to `results/qc_ref|sim-<refset_id>,<metric_id>.rds`. At current, we consider:

**1. Feature-level QC metrics**

* `frq`: detection frequency, i.e. fraction of non-zero counts
* `avg/var`: average/variance of logCPM
* `cor`: feature-to-feature correlation

**2. Sample-level QC metrics**

* `frq`: detection frequency, i.e. fraction of non-zero counts
* `lls`: log-transformed library size
* `cor`: sample-to-sample correlation
* `sil`: Silhouette width
* `pve`: percent variance explained

Noteworthily, we compute each QC metric for up to three different groupings of cells (depending on the refset's complexity): 

1. globally, i.e. across all cells
2. at the batch-level, i.e. for each cluster
3. at the cluster-level, i.e. for each batch

### Evaluation

We compare QC metrics between reference and simulated data in both one- (`code/06-eval_1d.R`) and two-dimensional settings (`code/06-eval_2d.R`). For the latter, every combination of feature- and sample-level metrics is considered. Furthermore, metrics are evaluated for each cell grouping, i.e. we perform a test globally, for each cluster and batch (again, depending on the refset's complexity). Test results are written to `results/stat_1d,<test_id>-<refset_id>,<metric_id>.rds` for 1D, and `results/stat_2d,<test_id>-<refset_id>,<metric1_id>,<metric2_id>.rds` for 2D tests.

**1. One-dimensional statistics**

* Kolmogorov-Smirnov (KS) test

**2. Two-dimensional statistics**

* two-dimensional KS test
* Earth Mover's Distance (EMD)

Finally, results for each statistic are combined across all refsets and methods via `code/06-comb_1/2d.R`, resulting in one table of results for each statistic under `results/06-comb_1/2d-<test_id>.rds`.

