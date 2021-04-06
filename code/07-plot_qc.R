suppressPackageStartupMessages({
    library(jsonlite)
    library(dplyr)
    library(ggplot2)
    library(purrr)
})

# wcs <- list(type = "cell", metric = "sil")
# args <- list(
#     ref = "results/qc_ref-panc8.indrop_alpha,cell_sil.rds",
#     sim = list.files("results", "qc_sim-panc8.indrop_alpha,cell_sil", full.names = TRUE))

df <- .read_res(args$ref, args$sim)

if (is.null(df)) {
    ggsave(args$fig, ggplot(), width = 5, height = 5, units = "cm")
} else {

type_metric <- paste(wcs$type, wcs$metric, sep = "_")

ps <- df %>% 
    group_by(group_id) %>% 
    group_map(.keep = TRUE, ~{
        ggplot(.x, 
            aes(value, ..density../max(..density..), col = method)) +
            geom_density(key_glyph = "point") +
            scale_color_manual(values = .pal) +
            scale_y_continuous(breaks = c(0, 1)) +
            .prettify() + theme(aspect.ratio = 2/3) +
            guides(col = guide_legend(NULL,
                override.aes = list(size = 2, alpha = 1))) +
        labs(x = type_metric, y = "scaled density", 
            title = paste0("level: ", .x$group[1], ", group: ", .x$id[1]))
    })

pdf(args$fig, width = 7, height = 5, onefile = TRUE)
for (p in ps) print(p); dev.off()

}
