suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

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
  
res <- lapply(args$res, readRDS)
refsets <- gsub(".*-(.*),.*\\.rds", "\\1", basename(args$res))
metrics <- gsub(".*,(.*)\\.rds", "\\1", basename(args$res))
ns <- vapply(res, nrow, numeric(1))
df <- mutate(bind_rows(res),
             refset = rep.int(refsets, ns),
             metric = rep.int(metrics, ns), 
             x_label = paste(group,id, sep = "."))


# df_sub <- df %>%
#         filter(., refset== refsets[2]) %>%
#         filter(., metric=="gene_avg")%>%
#         mutate(x_label= paste(.$group,.$id, sep = "."))
# 
# ggplot(df_sub, aes(x=x_label, y = stat, color=method))+
#   geom_point() + 
#   scale_y_reverse()

p <- ggplot(df, aes(x=x_label, y= stat, color=method)) +
  scale_y_reverse()+
  facet_grid(metric ~ refset) +
  geom_point()+
  theme(axis.text.x = element_text(angle = 90)) +
  xlab(element_blank())+
  ylab("KS statistic")



# p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()

ggsave(args$fig, p)