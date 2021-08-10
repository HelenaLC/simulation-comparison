FROM r-base

RUN apt-get -y update
RUN apt-get -y install git

RUN R -e "install.packages('remotes')"
RUN R -e "install.packages('BiocManager')"

# datasets

RUN R -e "BiocManager::install('CellBench')"
RUN R -e "BiocManager::install('ExperimentHub')"
RUN R -e "install.packages('Seurat')"
RUN R -e "remotes::install_github('satijalab/seurat-data')"
RUN R -e "BiocManager::install('TENxPBMCData')"

# methods

RUN R -e "BiocManager::install('BASiCS')"
RUN R -e "BiocManager::install('scDD')"
RUN R -e "BiocManager::install('splatter')"
RUN R -e "BiocManager::install('SPsimSeq')"
RUN R -e "BiocManager::install('zinbwave')"

RUN R -e "remotes::install_github('JINJINT/ESCO')"
RUN R -e "remotes::install_github('HelenaLC/muscat', 'devel')"
RUN R -e "remotes::install_github('suke18/POWSC')"
RUN R -e "remotes::install_github('bvieth/powsimR')"
RUN R -e "remotes::install_github('Vivianstats/scDesign')"
RUN R -e "remotes::install_github('JSB-UCLA/scDesign2')"
RUN R -e "remotes::install_gitlab('sysbiobig/sparsim')"
RUN R -e "remotes::install_github('YosefLab/SymSim')"
RUN R -e "remotes::install_github('statOmics/zingeR')"

# other

RUN R -e "install.packages('dplyr')"
RUN R -e "install.packages('emdist')"
RUN R -e "install.packages('jsonlite')"
RUN R -e "install.packages('matrixStats')"
RUN R -e "install.packages('Peacock.test')"
RUN R -e "install.packages('purrr')"
RUN R -e "install.packages('tidyr')"

RUN R -e "BiocManager::install('scater')"
RUN R -e "BiocManager::install('scran')"
RUN R -e "BiocManager::install('SingleCellExperiment')"
RUN R -e "BiocManager::install('variancePartition')"
RUN R -e "BiocManager::install('waddR')"

# plotting

RUN R -e "install.packages('ggplot2')"
RUN R -e "install.packages('ggpubr')"
RUN R -e "install.packages('ggrastr')"
RUN R -e "install.packages('patchwork')"
RUN R -e "install.packages('RColorBrewer')"
RUN R -e "install.packages('tidytext')"
