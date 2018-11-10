#####
# Nice markdown templates etc.
# install.packages("devtools")
# devtools::install_github("mikey-harper/example-rmd-templates")
# install.packages("rticles")
# devtools::install_github("rstudio/rticles")

# package collection: 
# "car"-package for additional applied regression tools
# "texreg" package for nice latex regression output
# install.packages("rmarkdown")
# install.packages()
#install.packages("viridis") # very fancy color scales

### Webscraping
# install dev version of RSelenium
devtools::install_github("ropensci/RSelenium")
# htmltab
# install.packages("htmltab")
# library(htmltab)
# vignette("htmltab")
# rvest

##### Load packages code
# install packages from CRAN
p.needed <- c("readr", # imports spreadsheet data (Wickham)
              "readxl", # imports .xls .xlsx(Wickham)
              "haven", # imports SPSS, Stata and SAS files (Wickham)
              "magrittr", #  for piping (Wickham)
              "plyr", # for consistent split-apply-combines
              "dplyr",  # provides data manipulating functions (Wickham)
              "stringr", # for string processing (Wickham)
              "ggplot2", # for graphics (Wickham)
              "tidyr", # for tidying data frames (Wickham)
              "forcats",  # tidyverse package for convenient factor handling
              "purrr", # pure and completing function programming package
              "httr", # talking to web APIs
              "scales", # supports scaling for graphs
              "viridis",
              "broom", # for tidying model output (Dave Robinson)
              "janitor", # for basic data tidying and examinations
              "reshape2", # reshape data(Wickham)
              "xtable", # generate table output
              "directlabels", # add direct labels to plots
              "stargazer", # generate nice model table
        #      "babynames", # dataset compiled by Hadley Wickham; 
        #      "nycflights13", # data on 336776 flights departing from NYC in 2013
              "lubridate", # handling dates of all kinds
              "maps", "maptools", "ggmap",
              "sjPlot", "sjmisc",
              "survey",
              "rvest", # whickham package for web scraping
              "data.table", # package for very large data (faster than other packages)
              "Metrics", # for useful functions and machine learning
              "knitr", # knitr to convert R output to markdown code
              "kableExtra", # kableExtra to cutomize kable() tables
              "tibble", # functions for handling tibbles
              "gridExtra", # package for placing plots next each other
              "cowplot", # # another package for nice plotting next to each other
              "boot", # bootstrapping toolbox
              "psych", # descriptive statistics like describe()
              "rmarkdown", # basic rmarkdown package
              "wesanderson",  # awesome color brewer
              "extrafont", # new nice fonts e.g. for ggplot)  
              "ggthemes",
              "margins", # to compute margins for logistic regression
              "sandwich", # to obtain heteroscedastic robust SEs
              "lmtest", # package for linear model testing
              "survival", # package for survival analysis
              "lme4", # Linear Mixed-Effects Models
              "ggpubr", # additional ggplot stuff | e.g common legends
              "sjstats", # simplified statistical computations) # nice additional gg themes
              "caret",
              "corrplot") #great correlation matrices

# install packages which are not in installed.packages()
packages <- rownames(installed.packages())
p.to.install <- p.needed[!(p.needed %in% packages)]
if (length(p.to.install) > 0) {
  install.packages(p.to.install)
  }

# load all p_needed
lapply(p.needed, require, character.only = TRUE)

rm(packages,p.needed, p.to.install)