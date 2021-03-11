suppressPackageStartupMessages({
  library(SymSim)
  library(SingleCellExperiment)
})

fun <- function(x){
  batch <- x$batch
  x <- x$optimal_param
  
  true_counts <- SimulateTrueCounts(ncells_total = x$ncells_total,
                                            ngenes = x$ngenes,
                                            gene_effects_sd = x$gene_effects_sd, 
                                            gene_effect_prob = x$gene_effect_prob,
                                            Sigma = x$Sigma,
                                            scale_s = x$scale_s,
                                            prop_hge = x$prop_hge, 
                                            randseed = 1234)
  data("gene_len_pool")
  gene_len <- sample(gene_len_pool, x$ngenes, replace = FALSE) # TODO: this is random, maybe there is a better solution? 
  
  observed_counts <- True2ObservedCounts(true_counts = true_counts$counts, 
                                         meta_cell = true_counts$cell_meta,
                                         alpha_mean = x$alpha_mean, 
                                         alpha_sd = x$alpha_sd,
                                         depth_mean = x$depth_mean,
                                         depth_sd = x$depth_sd,
                                         nPCR1 = x$nPCR1,
                                         protocol = x$protocol,
                                         gene_len = gene_len
                                         )
  
  if (x$nbatch > 1) {
    sim <- DivideBatches(observed_counts_res = observed_counts, nbatch = x$nbatch)
    sim <- SingleCellExperiment(list(counts=sim$counts),
                                colData=DataFrame(batch=batch))
  } else {
    sim <- observed_counts
    sim <- SingleCellExperiment(list(counts=sim$counts))
  }
  
  return(sim)
}