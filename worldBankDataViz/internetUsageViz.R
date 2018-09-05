# clean workspace
rm(list=ls())

source("packages.R")
source("functions.R")

# Setting Working directory
try(setwd("C:/Users/User/Code/R/trende_jazzmoe/Trende_jazzmoe/worldBankDataViz"), silent = TRUE)
try(setwd("C:/Users/Moritz/Desktop/GitHub Repositories/Trende_jazzmoe/worldBankDataViz"), silent = TRUE)

# load data
dataset <- read_excel("dataInternetUsage.xls", skip = 3, col_names = TRUE) 

## Prep
data.m <- dataset %>% 
  gather(year, internet.usage.pct, matches("[0-9]")) %>%
  mutate(internet.usage.pct = round(internet.usage.pct, 2),
         year = as.numeric(year)) %>%
  select(-c(`Indicator Code`,`Indicator Name`)) %>%
  rename(country = `Country Name`, ccode = `Country Code`)

data.plot <- data.m[data.m$country %in% c("World", 
                                          "Latin America", 
                                          "South Asia", 
                                          "Sub-Saharan Africa", 
                                          "North America", 
                                          "European Union", 
                                          "Germany")
                    ,] 

# plot the data
data.plot %>% group_by(country) %>%
ggplot(aes(year, internet.usage.pct, color = country)) + 
  geom_point() + 
  stat_smooth() +
  theme_minimal() +
  xlim(1989, 2017) +
  xlab("Year") + 
  ylab("Percentage of population") + 
  ggtitle("Internet usage [%]")

### STUFF

# data.m.nest <- data.m %>% select(-`ccode`) group_by(`country`) %>%
#   nest()

# find the row of a certain country. e.g. Germany
# years = as.double(dataset[3,5:62])
# 
# germany = as.double(dataset[which(dataset$`Data Source` == "Germany"), 5:62])
# eu = as.double(dataset[which(dataset$`Data Source` == "European Union"), 5:62])
# north_america = as.double(dataset[which(dataset$`Data Source` == "North America"), 5:62])
# sub_saharan_africa = as.double(dataset[which(dataset$`Data Source` == "Sub-Saharan Africa"), 5:62])
# south_asia = as.double(dataset[which(dataset$`Data Source` == "South Asia"), 5:62])
# latin_america = as.double(dataset[which(dataset$`Data Source` == "Latin America"), 5:62])
# world = as.double(dataset[which(dataset$`Data Source` == "World"), 5:62])# 
