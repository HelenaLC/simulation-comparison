suppressPackageStartupMessages({
  library(powsimR)
  library(SingleCellExperiment)
})

fun <- function(x){
  p <- estimateParam(countData = as.matrix(counts(x)), 
                         RNAseq = 'singlecell',
                         Protocol = 'UMI',
                         Distribution = 'NB',
                         Normalisation = 'scran',
                         GeneFilter = 0.1) # TODO check params 
  
  return(p)
}