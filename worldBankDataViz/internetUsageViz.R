library(readxl)
setwd("C:/Users/User/Code/R/trende_jazzmoe/Trende_jazzmoe/worldBankDataViz")

dataset <- read_excel("dataInternetUsage.xls")

# find the row of a certain country. e.g. Germany
years = as.double(dataset[3,5:62])

germany = as.double(dataset[which(dataset$`Data Source` == "Germany"), 5:62])
eu = as.double(dataset[which(dataset$`Data Source` == "European Union"), 5:62])
north_america = as.double(dataset[which(dataset$`Data Source` == "North America"), 5:62])
sub_saharan_africa = as.double(dataset[which(dataset$`Data Source` == "Sub-Saharan Africa"), 5:62])
south_asia = as.double(dataset[which(dataset$`Data Source` == "South Asia"), 5:62])
latin_america = as.double(dataset[which(dataset$`Data Source` == "Latin America"), 5:62])
world = as.double(dataset[which(dataset$`Data Source` == "World"), 5:62])

df = data.frame(years, germany, eu, north_america, latin_america, sub_saharan_africa, sout_asia, world)


## ggPlot magic
library(ggplot2)
d <- melt(df, id.vars="years")

# Everything on the same plot
ggplot(d, aes(years,value, col=variable)) + 
  geom_point() + 
  stat_smooth() +
  theme_bw() +
  xlim(1989, 2017) +
  xlab("Year") + 
  ylab("Percentage of population") + 
  ggtitle("Internet usage [%]")

