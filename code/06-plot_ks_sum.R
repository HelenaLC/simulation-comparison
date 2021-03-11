suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})


# setwd("~/Desktop/LabRotation_Robinson/simulation-comparison")
# source("code/utils.R")
# args <- list(
#   res= c("results/ks-panc8,indrop_alpha,gene_avg.rds"
#          , "results/ks-CellBench,H1975,gene_avg.rds"
#          , "results/ks-panc8,indrop_alpha,gene_frq.rds"
#          , "results/ks-CellBench,H1975,gene_frq.rds"
#          ,"results/ks-panc8,indrop_alpha,gene_var.rds"
#          ,"results/ks-CellBench,H1975,gene_var.rds"
#          , "results/ks-panc8,indrop_alpha,cell_frq.rds"
#          , "results/ks-CellBench,H1975,cell_frq.rds"
#          , "results/ks-panc8,indrop_alpha,cell_lls.rds"
#          , "results/ks-CellBench,H1975,cell_lls.rds" ) ,
#   fig= "plots/ks_sum.pdf"
# )

this_refset <- paste(wcs$refset,names(wcs)[2] ,sep=",")
res <- lapply(args$res, readRDS)
refsets <- gsub(".*-(.*),.*\\.rds", "\\1", basename(args$res))
metrics <- gsub(".*,(.*)\\.rds", "\\1", basename(args$res))
ns <- vapply(res, nrow, numeric(1))


 df <- bind_rows(res) %>%
        mutate(., refset = rep.int(refsets, ns),
               metric = rep.int(metrics, ns)) %>%
        filter(., refset == this_refset) %>%
        mutate(.,x_label = paste(group,id, sep = "."))
 
 
 p <- ggplot(df, aes(x=x_label, y= stat, color=method)) +
   geom_point()+
   scale_y_reverse()+
   facet_grid(vars(metric), scale ="fixed") +
   theme(axis.text.x = element_text(angle = 90)) +
   xlab(element_blank())+
   ylab("KS statistic")+
   ggtitle(this_refset)


ggsave(args$fig, p,width = 15, height = 20, units = "cm")