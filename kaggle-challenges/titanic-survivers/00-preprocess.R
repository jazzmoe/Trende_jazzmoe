########################################
### Setup

try(setwd("C:/Users/Moritz/OneDrive/GitHub/Trende_jazzmoe/kaggle-challenges/titanic-survivers"), silent = TRUE)

rm(list = ls())
source("packages.R")
source("functions.R")
# install.packages('e1071', dependencies=TRUE)
# install.packages("RANN") # for knearest neighbor imputation

set.seed(132)

### Load data
Train <- read_csv("./data/train.csv")
Test <- read_csv("./data/test.csv")
SubTemp <- read_csv("./data/gender_submission.csv")


### Data prep
names(Train) <- str_to_lower(names(Train))
names(Test) <- str_to_lower(names(Test))

Full <- Test %>% mutate(survived = as.integer(NA)) %>% 
  dplyr::union(Train) %>% mutate(dset = ifelse(is.na(survived), "Test", "Train")) %>% 
  select(dset, survived, everything()) %>%  
  mutate(survived = factor(survived, labels = c("Died", "Survived")),
         pclass = factor(pclass, labels = c("First", "Second", "Third")),
         has.cabin = ifelse(!is.na(cabin), 1, 0),
         embarked = factor(embarked),
         sex = factor(sex),
         dset = factor(dset))

### CHECK NAs
naFrame <- purrr::map_df(Full, ~ sum(is.na(.x))) # missings in cabin, age, embarked and fare
# -> need imputation

### INSPECT and TRANSFORM VARIABLES

# SIBSP & PARCH
Full <- Full %>% mutate(family.size = (sibsp + parch),
                        fam.zero = ifelse(family.size == 0, 1, 0),
                        fam.onetwo = ifelse(family.size == 1 | family.size == 2, 1, 0),
                        fam.three = ifelse(family.size == 3, 1, 0),
                        fam.fourmore = ifelse(family.size > 3, 1, 0))

# impute missing fare
trainData <- trainControl(method = "repeatedcv", number = 7, repeats = 5); 
mod.fare   <- train(fare ~ pclass + sex + embarked + sibsp + parch,
                    data = Full %>% filter(!is.na(fare)), 
                    trControl = trainData, method = "rpart", na.action = na.pass, tuneLength = 5);
Full <- Full %>% mutate(fare.imp = ifelse(is.na(fare), predict(mod.fare, Full), fare))
print(mod.fare$results)

# break fare into percentiles
Full <- Full %>% mutate(fare.pctile = as.factor(ntile(Full$fare, 5)))
# make a fare factor variable
Full <- Full %>% mutate(fare.fct = as.factor(fare))

# AGE

# calculate a has.age variable
Full <- Full %>% mutate(has.age = ifelse(is.na(age), 0, 1))

# impute missing age Train and Test | once by imputed values once by sample median
ageSet <- Full[!is.na(Full$age),]
ageSet <- ageSet[!is.na(ageSet$survived),]

# survived good predictor but can't be used since not for test data available
# imputing age here
trainData <- trainControl(method = "repeatedcv", number = 10, repeats = 5, verboseIter = TRUE)
mod.age <- train(log(age) ~ pclass + sibsp + fam.onetwo + fam.three + fam.fourmore + fare.imp, 
                 data = ageSet, method = "ranger", trControl = trainData)
print(mod.age$results)

Full <- Full %>% mutate(age.fit = exp(predict(mod.age, newdata = Full)),
                        age.imp = ifelse(is.na(age), age.fit, age),
                        age.na.median = ifelse(is.na(age), median(age, na.rm = TRUE), age))

impute <- preProcess(Full, method = c("knnImpute"))
Full$age.knn <- predict(impute, Full, type = "response")$age

# make percentile age
Full <- Full %>% mutate(age.pctile = ntile(age.imp, 5))

# compute a child dummy
Full <- Full %>% mutate(child = factor(ifelse(age.imp <= 14, 1, 0), labels = c("Adult", "Child")))

table(Full$child, Full$survived, Full$pclass)
# it also seems that especially in class 1 and 2 children survived, not in class 3
Full <- Full %>% mutate(child.class = factor(ifelse(age.imp <= 14 & pclass != "Third", 1, 0), 
                                             labels = c("Adult", "Child")))

# EMBARKED
Full[is.na(Full$embarked),]
# both missing embarked survived; thus replace by location with lowest death rate C
# alternative argument would be replacing by S because that's the most common value
Full <- Full %>% mutate(embarked = ifelse(is.na(embarked), "S", embarked))

# careful: embarked might lead to overfitting; relationsship might be more due to class
# or other factors: causality is questionable

# NAME | create a variable for title
Full$title <- gsub("^.*, (.*?)\\..*$", "\\1", Full$name)
table(Full$title)

# Reassign rare titles
officer <- c('Capt', 'Col', 'Don', 'Major', 'Rev', 'Dr')
royalty <- c('Dona', 'Lady', 'the Countess', 'Sir', 'Jonkheer')

# Reassign mlle, ms, and mme, and rare
Full$title[Full$title == 'Mlle']        <- 'Miss' 
Full$title[Full$title == 'Ms']          <- 'Miss'
Full$title[Full$title == 'Mme']         <- 'Mrs' 
Full$title[Full$title %in% royalty]  <- 'Royalty'
Full$title[Full$title %in% officer]  <- 'Officer'

table(Full$title)

# CABIN
cabin.class <- Full$cabin %>% str_sub(., 1, 1)
cabin.class[is.na(cabin.class)] <- "Z"
Full$cabin.class <- as.factor(cabin.class)

# TICKET

classifyTickets <- function(x) {
  ticket.unique <- rep(0, nrow(x))
  tickets <- unique(x$ticket)
  for (i in 1:length(tickets)) {
    current.ticket <- tickets[i]
    party.indexes <- which(x$ticket == current.ticket)
    
    for (k in 1:length(party.indexes)) {
      ticket.unique[party.indexes[k]] <- length(party.indexes)
    }
  }
  x$ticket.unique <- ticket.unique
  x$ticket.size <- NA
  x$ticket.size[x$ticket.unique == 1]   <- 'Single'
  x$ticket.size[x$ticket.unique < 5 & x$ticket.unique >= 2]   <- 'Small'
  x$ticket.size[x$ticket.unique >= 5]   <- 'Big'
  x$ticket.size <- factor(x$ticket.size, levels = c("Single", "Small", "Big"))
  return(x)
}

Full <- classifyTickets(Full)

### CREATE Group Belonging Variable
# ticket and fare groups
Full$ticket.freq <- ave(seq(nrow(Full)), Full$ticket,  FUN = length)
Full$fare.freq <- ave(seq(nrow(Full)), Full$fare, FUN = length)

# name groups by sourname
Full$surname <- purrr::map_chr(Full$name, ~ word(.x, 1)) %>% 
  purrr::map_chr(., ~ str_sub(.x, start = 1, end = -2))

### make groups
maxgrp <- 12
# Family groups larger than 1
Full$GID <- paste0(Full$surname, as.character(Full$family.size + 1))
Full$GID[Full$family.size == 0] <- 'Single'
# Ticket group
group <-(Full$GID == 'Single') & (Full$ticket.freq > 1) & (Full$ticket.freq < maxgrp)
Full$GID[group] <- Full$ticket[group]
# Fare group
group <- (Full$GID == 'Single') & (Full$fare.freq > 1) & (Full$fare.freq < maxgrp)
Full$GID[group] <- Full$fare.fct[group]
# make factor
Full$GID <- factor(Full$GID)

# BUILD SLogL
# define function to compute log likelihood of a/(1-a)
logl <- function(a) {
  a <- max(a,0.1); # avoids log(0)
  a <- min(a,0.9); # avoids division by 0
  return (log(a/(1-a)));
}


SLogL.sex.pclass <- Train %>% 
  dplyr::group_by(sex, pclass) %>% 
  dplyr::summarize(SlogL = logl(mean(survived))) %>% ungroup %>% 
  mutate(pclass = factor(pclass, labels = c("First", "Second", "Third")),
         sex = as.factor(sex))
print(SLogL.sex.pclass)

Full <- left_join(Full, SLogL.sex.pclass, by = c("sex", "pclass"))

### adjust logL for certain groups

#increase logL for groups with survivors
Full$survived2 <- ifelse(is.na(Full$survived), NA, ifelse(Full$survived == "Died", 0, 1))
ticket.stats <- Full %>% group_by(ticket) %>% 
  summarize(l = length(survived2), 
            na = sum(is.na(survived2)), 
            c = sum(survived2, na.rm=T))

for (i in 1:nrow(ticket.stats)) {
  plist <- which(Full$ticket == ticket.stats$ticket[i])
  if(ticket.stats$na[i] > 0 & ticket.stats$l[i] > 1 & ticket.stats$c[i] > 0) {
    Full$SlogL[plist] <- Full$SlogL[plist] + 3
  }
}

# penalizing singles
sconst <- -2.1
Full$SlogL[Full$GID == "Single"] <- Full$SlogL[Full$GID == "Single"] - sconst

# penalizing large groups
Full$SlogL[Full$ticket.freq ==  7] <- Full$SlogL[Full$ticket.freq == 7]  - 3
Full$SlogL[Full$ticket.freq ==  8] <- Full$SlogL[Full$ticket.freq == 8]  - 1
Full$SlogL[Full$ticket.freq ==  9] <- Full$SlogL[Full$ticket.freq == 9]  - 3

ggplot(Full[Full$dset == "Train",], aes(x=pclass, y=SlogL)) + 
  geom_jitter(aes(color=survived)) + 
  facet_grid(. ~ ticket.freq,  labeller=label_both) + 
  labs(title="SLogL vs Pclass vs TFreq")

# higher likelihood for minors
Full$SlogL[Full$child.class == "Child"] <- 8

### EDA: EXPLORATORY DATA ANALYSIS | Analyze now survived relations with Train set

p.raw <- Full[!is.na(Full$survived),] %>% ggplot() # for plot purposes

# SURVIVED
p.survived <- p.raw + geom_bar(aes(x = survived))

# CABIN
cabin.surv <- table(Full$has.cabin, Full$survived)
cab.surv.chisq <- chisq.test(Full$has.cabin, Full$survived) # significant relationship

# PCLASS
p.pclass <- p.raw + geom_bar(aes(x = pclass))

# SEX
p.sex <- p.raw + geom_bar(aes(x = sex))

# FAMILY + PARCH + SIBSP
family.size.surv <- table(Full$family.size, Full$survived)

sibsp.surv <- table(Full$sibsp, Full$survived)
parch.surv <- table(Full$parch, Full$survived)
subsp.surv.chisq <- chisq.test(Full$sibsp, Full$survived) # significant relationship

# FARE
p.fare <- p.raw + geom_histogram(aes(x = fare))

# AGE 
p.age1 <- p.raw + geom_histogram(aes(x = age))
p.age2 <- p.raw + geom_boxplot(aes(y = age, x = survived))

# CORR MATRIX: variable correlations | corr matrices
Corr <- Full[,c("survived", "pclass", "sex", "age", "sibsp", 
                "parch", "fare", "embarked", "has.cabin")]
pairs.panels(Corr) # corr coefficient
CorrMat <- purrr::map_dfc(Corr, ~ as.integer(.x)) %>% cor(.)
# corrplot.mixed(TrainCorr, lower.col = "black", number.cex = .7)

save(Full, file = "./data/Full.RData")
