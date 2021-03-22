suppressPackageStartupMessages({
  library(variancePartition)
  library(jsonlite)
  library(SingleCellExperiment)
  library(scater)
})

x <- readRDS(args$sce)
# x <- readRDS("data/02-sub/CellBench,H1975.rds")
# form <- ~  lls+ (1|batch)



# y <- fromJSON("/config/subsets.json")[[wcs$refset]]
refset_type <- fromJSON("./config/subsets.json")[[wcs$refset]][[names(wcs)[2]]][["type"]]

if(refset_type =="k" || refset_type =="b"){
  
  x <- logNormCounts(x)
  i <- intersect(names(colData(x)) , c("batch", "cluster")) 
  if(i == "batch"){
    form <- ~   (1|batch)
    meta_sub <- as.data.frame(colData(x)[, c("batch")])
    colnames(meta_sub) <- "batch"
  }else{
      if(i == "cluster"){
        form <- ~   (1|cluster)
        meta_sub <- as.data.frame(colData(x)[, c("cluster")])
        colnames(meta_sub) <- "cluster"  
      }
    #tbd: if batch and cluster (until now we don't have such a dataset)
  }
  
  expr <- as.matrix(assays(x)$logcounts)
  varPart <- fitExtractVarPartModel(expr, form, data = meta_sub)
  
  qc <- data.frame(group ="global", id = "foo", cell_pve = varPart[,i])  
}else{
  qc <- NA
}




