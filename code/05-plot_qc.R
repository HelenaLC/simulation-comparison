suppressPackageStartupMessages({
    library(jsonlite)
    library(dplyr)
    library(ggplot2)
    library(purrr)
})

pat <- sprintf(".*,(.*),%s\\.rds", wcs$metric)
ids <- gsub(pat, "\\1", basename(args$sim))
lab <- fromJSON(args$con)[[wcs$metric]]$lab

res <- lapply(c(args$ref, args$sim), readRDS)
names(res) <- c("reference", ids)
df <- bind_rows(res, .id = "method")
df$method <- factor(df$method, names(.pal))

ps <- group_by(df, group, id) %>% 
    group_map(.keep = TRUE, ~{
        ggplot(.x, aes_string(wcs$metric,
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

pdf(args$fig, width = 7/2.54, height = 4/2.54, onefile = TRUE)
for (p in ps) print(p); dev.off()
