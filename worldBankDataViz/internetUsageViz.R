library(readxl)
setwd("C:/Users/User/Code/R/trende_jazzmoe/Trende_jazzmoe/worldBankDataViz")

dataset <- read_excel("dataInternetUsage.xls")

# find the row of a certain country. e.g. Germany
idxGermany = which(dataset$`Data Source` == "Germany")
dataGermany = dataset[idxGermany, 5:62]
plot(as.double(dataChar))


## ggPlot magic
library(ggplot2)
