# Simulation comparison

## Setup

### Contents

* `config.yaml` specifies the R library and version to use
* `code` contains all R scripts used in the *Snakemake* workflow
* `data` contains raw, filtered and simulated scRNA-seq datasets,  
as well as simulation parameter estimates
* `meta` contains two *.json* files that specify simulation method (`methods.json`) and reference subset (`subsets.json`) configurations
* `outs` contains all results from computations (typically `data.frame`s) as *.rds* files
* `figs` contains all visual outputs as *.pdf* files, and corresponding `ggplot` objects as *.rds* files (for subsequent arrangement into 'super'-figures)

### Methods & datasets

Simulation methods are tagged with *one or many* of the following labels, according to which scenario(s) they can accommodate: 

* `n` for none: no clusters or batches
* `b` for batch: multiple batches, no clusters
* `k` for cluster: multiple clusters, no batches
* `g` for groups: two groups of cells, e.g. batches/clusters/conditions

Similarly, we tag subsets (see below) with *exactly one* of these labels. This allows running each method on subsets they are capable of simulating.

## Workflow

### Preprocessing

**1. Data retrieval**

Each `code/00-get_data-<datset_id>.R` script retrieves a publicly available scRNA-seq dataset through from which a *SingleCellExperiment* is constructed and written to `data/00-raw/<datset_id>.rds`

**2. Filtering**

`code/01-fil_data.R` is applied to each raw dataset as to 

  * remove batches, cluster, or batch-cluster instances with fewer than 50 cells (depending on the dataset's complexity)
  * keep genes with a count of at least 1 in at least 10 cells, and remove cells with fewer than 100 detected genes 
  
Filtered data are written to `data/01-fil/<datset_id>.rds`.

**3. Subsetting**

Because different methods can accommodate only some features (e.g. multiple batches or clusters, both or neither), `code/02-sub_data.R` creates specific subsets in `data/02-sub/<datset_id>.<subset_id>,rds`. We term these *ref(erence)set*s (i.e. `<datset_id>.<subset_id> = <refset_id>`), as they serve as the input reference data for simulation.

### Simulation

**1. Parameter estimation**

Simulation parameters are estimated with `code/03-est_pars.R`, which in term sources a `code/03-est_pars-<method_id>.R` script that executes a method's parameter estimation function(s). In cases where no separate estimation takes place, this returns `NULL`. Parameter estimates for each combination of `<refset_id.<method_id> = <simset_id>` are written to `data/04-est/<simset_id>.rds`.

**2. Data simulation**

Data is simulated with `code/04-sim_data.R`, which in term sources a `code/04-sim_data-<method_id>.R` script that executes a method's simulation function. Simulations for each combination of `<refset_id>` and `method_id` are written to `data/05-sim/<refset_id>,<method_id>.rds`.

### Quality control

Various quality control (QC) summaries are computed with `code/05-calc_qc.R`, which in term sources a set of `code/05-calc_qc-<metric_id>.R` scripts. QC results for reference and simulated data are written to `outs/qc_ref-<refset_id>,<metric_id>.rds` and `outs/qc_sim-<simset_id>,<metric_id>.rds`, respectively. At current, we consider:

**1. Gene-level summaries**

* `frq`: detection frequency, i.e. fraction of non-zero counts
* `avg/var`: average/variance of logCPM
* `cv`: coefficient of variation
* `cor`: gene-to-gene correlation

**2. Cell-level summaries**

* `frq`: detection frequency, i.e. fraction of non-zero counts
* `lls`: log-transformed library size (total counts)
* `cor`: cell-to-cell correlation

**3. Global summaries**

* `sw`: Silhouette width (using batch/cluster labels as classes)
* `pve`: percent variance explained (of gene expression = logCPM, by batch/cluster)

Noteworthily, we compute each summary for different groupings of cells (depending on the dataset's complexity): 

1. globally, i.e. across all cells
2. at the batch-level, i.e. for each batch
3. at the cluster-level, i.e. for each cluster

Global summaries are computed at the batch-/cluster-level only, as they require a grouping variable. 

### Evaluation

We compare summaries between reference and simulated data in both one- (`code/06-stat_1d.R`) and two-dimensional settings (`code/06-statl_2d.R`). For the latter, every combination of gene- and cell-level metrics is considered, excluding correlations and global summaries. Furthermore, metrics are evaluated for each cell grouping, i.e. we perform a test globally, for each batch and cluster (again, depending on the dataset's complexity). Test results are written to `outs/stat_1d,<refset_id>,<metric_id>,<stat1d_id>.rds` for 1D, and `outs/stat_2d,<refset_id>,<metric1_id>,<metric2_id>,<stat2d_id>.rds` for 2D tests.

**1. One-dimensional statistics**

* Kolmogorov-Smirnov (KS) test
* Wasserstein metric

**2. Two-dimensional statistics**

* two-dimensional KS test
* Earth Mover's Distance (EMD)

### Visualization

Finally, results are collected across `refset_id`s and `method_id`s (jointly or separated by type), and visualized in various ways using as set of `07-plot_x.R` scripts. Output figures are written to `figs` as *.pdf* files, along with the corresponding `ggplot` objects as *.rds* files. 

## Customisation

### Datasets

In principle, any dataset for which a `code/00-get_data-<dataset_id>.R` script exists will be accessible to the workflow. However, data will only be retrieved if the dataset appears in `meta/subsets.json`. Hence,

**Removing**

To exclude a dataset from the workflow, i) (re)move the corresponding `code/00-get_data-<dataset_id>.R` script; or, ii) remove or comment out any associated `meta/subsets.json` entries.

**Adding**

Similarly, a new dataset can be added by supplying an adequate `code/00-get_data-<dataset_id>.R` script, and adding an entry to the `meta/subsets.json` configuration that specifies the subset ID, the number of genes/cells to sample (`NULL` for all), which batch(es)/cluster(s) to retain, as well as the resulting subset's type (one of n,b,k,g).

### Methods

The *Snakemake* will automatically include any simulation method for which a `code/03-est_pars-<method_id>.R` and `code/04-sim_data-<method_id>.R` script exists. Secondly, `meta/methods.json` will determine on which type(s) of dataset(s) each method should be run. Thus, 

**Removing**

To exclude a method from the workflow, either i) set `"<method_id>": "x"` in the `meta/methods.json` file (or anything other than n,b,k,g); or, ii) (re)move the parameter estimation and/or simulation script from the `code` directory.

**Adding**

Analogous to the above, adding a method to the benchmark requires i) adding a `code/03-est_pars-<method_id>.R` and `code/04-sim-data-<method_id>.R` script; and, ii) adding an entry for the `method_id` to the `meta/methods.json` file. Importantly, the R script for parameter estimation should handle batches (`colData` column `batch`), clusters (`colData` column `cluster`), both or neither. And the method's type(s) should be specified accordingly (`n` for neither, `b/k` for batches/clusters, `g` for groups), e.g. `"<method_id>": ["n", "k"]` for a method that supports 'singular' datasets, as well as ones with multiple clusters.
