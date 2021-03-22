suppressPackageStartupMessages({
    library(jsonlite)
    library(dplyr)
    library(ggplot2)
    library(purrr)
})

# wcs <- list(refest = 'panc8', indrop_alpha=NA, type="gene", metric="avg")
# args <- list(ref=c( "results/qc_ref-panc8,indrop_alpha,gene_avg.rds"),
#              sim=c( "results/qc_sim-panc8,indrop_alpha,gene_avg,splatter.rds", "results/qc_sim-panc8,indrop_alpha,gene_avg,SPsimSeq.rds", "results/qc_sim-panc8,indrop_alpha,gene_avg,SymSim.rds"))
# 
# wcs <- list(refest = 'CellBench', H1975=NA, type="cell", metric="cms")
# args <- list(ref=c( "results/qc_ref-CellBench,H1975,cell_cms.rds"),
#              sim=c( "results/qc_sim-CellBench,H1975,cell_cms,BASiCS.rds", "results/qc_sim-CellBench,H1975,cell_cms,SPsimSeq.rds"))



metric_str = paste0(wcs$type, '_', wcs$metric)
# pat <- sprintf(".*,(.*),%s\\.rds", wcs$metric)
pat <- sprintf(".*,%s,", metric_str)

ids <- gsub(pat, "\\1", basename(args$sim))
ids <- gsub(".rds", "\\1", ids)
ids
# lab <- fromJSON(args$con)[[wcs$metric]]$lab
lab <- metric_str


res <- lapply(c(args$ref, args$sim), readRDS)

if(!is.na(res)){

names(res) <- c("reference", ids)
df <- bind_rows(res, .id = "method")
df$method <- factor(df$method, names(.pal))

ps <- group_by(df, group, id) %>% 
    group_map(.keep = TRUE, ~{
        ggplot(.x, aes_string(metric_str,
            "..density../max(..density..)", col = "method")) +
            geom_density(key_glyph = "point") +
            scale_color_manual(values = .pal) +
            scale_y_continuous(breaks = c(0, 1)) +
            .prettify() + theme(aspect.ratio = 2/3) +
            guides(col = guide_legend(NULL,
                override.aes = list(size = 2, alpha = 1))) +
        labs(x = lab, y = "scaled density", title = paste0(
            "level: ", .x$group[1], ", group: ", .x$id[1]))
    })

# pdf(args$fig, width = 7/2.54, height = 4/2.54, onefile = TRUE)
pdf(args$fig, width = 7, height = 5, onefile = TRUE)
for (p in ps) print(p); dev.off()

}else{
    
    df <- data.frame()
    p <- ggplot(df) + geom_point() + xlim(0, 10) + ylim(0, 100)
    ggsave(args$fig, p, width = 15, height = 20, units = "cm")
}

