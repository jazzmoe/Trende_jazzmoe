library(readxl)
setwd("C:/Users/User/Code/R/trende_jazzmoe/Trende_jazzmoe/worldBankDataViz")

dataset <- read_excel("dataInternetUsage.xls")

# find the row of a certain country. e.g. Germany
germany = as.double(dataset[which(dataset$`Data Source` == "Germany"), 5:62])
ghana = as.double(dataset[which(dataset$`Data Source` == "Ghana"), 5:62])
world = as.double(dataset[which(dataset$`Data Source` == "World"), 5:62])
years = as.double(dataset[3,5:62])
df = data.frame(years, germany, ghana, world)


## ggPlot magic
library(ggplot2)
d <- melt(df, id.vars="years")

# Everything on the same plot
ggplot(d, aes(years,value, col=variable)) + 
  geom_point() + 
  stat_smooth() +
  xlim(1989, 2017) +
  xlab("Year") + 
  ylab("Percentage of population") + 
  ggtitle("Internet usage [%]")

