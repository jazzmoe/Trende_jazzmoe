########################################
### Kaggle Challenge: Titanic Survivers

########################################
### Outline

########################################
### Setup
rm(list = ls())
source("packages.R")
source("functions.R")
# install.packages('e1071', dependencies=TRUE)

############
### Code ###
############

### Load data
Train <- read_csv("./data/train.csv")
Test <- read_csv("./data/test.csv")
SubTemp <- read_csv("./data/gender_submission.csv")

### Data prep
names(Train) <- str_to_lower(names(Train))
names(Test) <- str_to_lower(names(Test))
Train <- Train %>% mutate(survived = as.factor(survived),
                          pclass1 = ifelse(pclass == 1, 1, 0),
                          pclass2 = ifelse(pclass == 2, 1, 0),
                          pclass3 = ifelse(pclass == 3, 1, 0),
                          has.cabin = ifelse(!is.na(cabin), 1, 0))
Test <- Test %>% mutate(pclass1 = ifelse(pclass == 1, 1, 0),
                        pclass2 = ifelse(pclass == 2, 1, 0),
                        pclass3 = ifelse(pclass == 3, 1, 0),
                        has.cabin = ifelse(!is.na(cabin), 1, 0))                          
### EDA: EXPLORATORY DATA ANALYSIS

# CORR MATRIX: variable correlations | corr matrices
TrainCorr <- Train[,c("survived", "pclass", "sex", "age", "sibsp", 
                      "parch", "fare", "embarked", "has.cabin")]
pairs.panels(TrainCorr) # corr coefficient
CorrMat <- purrr::map_dfc(TrainCorr, ~ as.integer(.x)) %>% cor(.)
# corrplot.mixed(TrainCorr, lower.col = "black", number.cex = .7)

### CHECK NAs
naTrainFrame <- purrr::map_df(Train, ~ sum(is.na(.x)))
naTestFrame <- purrr::map_df(Test, ~ sum(is.na(.x)))

### INSPECT VARIABLES
p.raw <- Train %>% ggplot()

# SURVIVED
p.survived <- p.raw + geom_bar(aes(x = survived))

# SEX
p.sex <- p.raw + geom_bar(aes(x = sex))

# SIBSP & PARCH
sibsp.surv <- table(Train$sibsp, Train$survived)
parch.surv <- table(Train$parch, Train$survived)
subsp.surv.chisq <- chisq.test(Train$sibsp, Train$survived) # significant relationship

Train <- Train %>% mutate(family.size = (sibsp + parch),
                          fam.zero = ifelse(family.size == 0, 1, 0),
                          fam.onetwo = ifelse(family.size == 1 | family.size == 2, 1, 0),
                          fam.three = ifelse(family.size == 3, 1, 0),
                          fam.fourmore = ifelse(family.size > 3, 1, 0))
family.size.surv <- table(Train$family.size, Train$survived)
Test <- Test %>% mutate(family.size = (sibsp + parch),
                   fam.zero = ifelse(family.size == 0, 1, 0),
                   fam.onetwo = ifelse(family.size == 1 | family.size == 2, 1, 0),
                   fam.three = ifelse(family.size == 3, 1, 0),
                   fam.fourmore = ifelse(family.size > 3, 1, 0))

# AGE

# survival rate higher when age != NA
Train <- Train %>% mutate(has.age = ifelse(is.na(age), 0, 1))
Test <- Test %>% mutate(has.age = ifelse(is.na(age), 0, 1))

# impute missing age Train and Test | once by imputed values once by sample mean
ageSet <- Train[!is.na(Train$age),]
mod.age <- lm(log(age) ~ survived + pclass + sibsp + fam.onetwo + fam.three + fam.fourmore + fare, 
              data = ageSet)
summary(mod.age)
Train <- Train %>% mutate(age.fit = exp(predict(mod.age, newdata = Train, type = "response")),
                          age.imp = ifelse(is.na(age), age.fit, age),
                          age.na.mean = ifelse(is.na(age), mean(age, na.rm = TRUE), age))
# for test
mod.age.test <- lm(log(age) ~ pclass + sibsp + fam.onetwo + fam.three + fam.fourmore + fare, 
                   data = Test)
Test <- Test %>% mutate(fare = ifelse(is.na(fare), mean(fare, na.rm = TRUE), fare),
                        age.fit = exp(predict(mod.age.test, newdata = Test, type = "response")),
                        age.imp = ifelse(is.na(age), age.fit, age),
                        age.na.mean = ifelse(is.na(age), mean(age, na.rm = TRUE), age))

p.age1 <- p.raw + geom_histogram(aes(x = age))
p.age2 <- p.raw + geom_boxplot(aes(y = age, x = survived))

# compute a child dummy
Train <- Train %>% mutate(child = as.factor(ifelse(age.imp <= 18, 1, 0)))
Test <- Test %>% mutate(child = as.factor(ifelse(age.imp <= 18, 1, 0)))

p.child <- p.raw + geom_boxplot(aes(y = survived, x = child))

# FARE
p.fare <- p.raw + geom_histogram(aes(x = fare))

# PCLASS
p.pclass <- p.raw + geom_bar(aes(x = pclass))

# CABIN
cabin.surv <- table(Train$has.cabin, Train$survived)
cab.surv.chisq <- chisq.test(Train$has.cabin, Train$survived) # significant relationship

# EMBARKED
Train[is.na(Train$embarked),]
# both missing embarked survived; thus replace by location with lowest death rate C
# alternative argument would be replacing by S because that's the most common value
Train <- Train %>% mutate(embarked = ifelse(is.na(embarked), "C", embarked))

emb.surv <- table(Train$embarked, Train$survived)
emb.surv.chisq <- chisq.test(Train$embarked, Train$survived) # significant relationship

# NAME
Train$title <- gsub("^.*, (.*?)\\..*$", "\\1", Train$name)
Test$title <- gsub("^.*, (.*?)\\..*$", "\\1", Test$name)
table(Train$title)
table(Test$title)
# Reassign rare titles
officer <- c('Capt', 'Col', 'Don', 'Major', 'Rev', 'Dr')
royalty <- c('Dona', 'Lady', 'the Countess', 'Sir', 'Jonkheer')

# Reassign mlle, ms, and mme, and rare
Train$title[Train$title == 'Mlle']        <- 'Miss' 
Train$title[Train$title == 'Ms']          <- 'Miss'
Train$title[Train$title == 'Mme']         <- 'Mrs' 
Train$title[Train$title %in% royalty]  <- 'Royalty'
Train$title[Train$title %in% officer]  <- 'Officer'
Test$title[Test$title == 'Mlle']        <- 'Miss' 
Test$title[Test$title == 'Ms']          <- 'Miss'
Test$title[Test$title == 'Mme']         <- 'Mrs' 
Test$title[Test$title %in% royalty]  <- 'Royalty'
Test$title[Test$title %in% officer]  <- 'Officer'
table(Train$title)
table(Test$title)

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

Train <- classifyTickets(Train)
Test <- classifyTickets(Test)

# variable interactions
p.fare.pclass <- p.raw + geom_boxplot(aes(pclass, fare, group = pclass))

library(gridExtra)
p.eda <- arrangeGrob(p.survived, p.sex, p.age1, p.fare, p.pclass, p.fare.pclass, 
             top = "Exploratory Data Analysis", 
             nrow = 2)

### CHECK NAs again: no left but in cabin
naTrainFrame <- purrr::map_df(Train, ~ sum(is.na(.x)))
naTestFrame <- purrr::map_df(Test, ~ sum(is.na(.x)))

##################################################################
### Modelling ####################################################
##################################################################

### define test and training in test set;
splitInd <- createDataPartition(y = Train$survived, p = 0.2, list = FALSE)
Testing <- Train[splitInd,]
Training <- Train[-splitInd,]

### Simple logistic regression
Mod1 <- glm(survived ~ sex + fare, data = Training, family = "binomial", na.action = na.omit)
Testing <- Testing %>% mutate(
  surv.mod1 = ifelse(predict(Mod1, newdata = Testing, type = "response") > 0.6, 1, 0),
  surv.mod1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(Testing$survived, Testing$surv.mod1)

# alternative / full model
Mod1.1 <- glm(survived ~ sex + fare + pclass + age.imp, data = Training, family = "binomial")
Testing <- Testing %>% mutate(
  surv.mod1.1 = ifelse(predict(Mod1.1, newdata = Testing, type = "response") > 0.6, 1, 0),
  surv.mod1.1 = ifelse(is.na(surv.mod1.1), 0, identity(surv.mod1.1)))
accuracy(Testing$survived, Testing$surv.mod1.1)

# alternative 2
Mod1.2 <- glm(survived ~ sex + pclass + embarked, data = Training, 
              family = "binomial", na.action = na.omit)
Testing <- Testing %>% mutate(
  surv.mod1.2 = ifelse(predict(Mod1.2, newdata = Testing, type = "response") > 0.6, 1, 0),
  surv.mod1.2 = ifelse(is.na(surv.mod1.2), 0, identity(surv.mod1.2)))
accuracy(Testing$survived, Testing$surv.mod1.2)

### random effects model
Mod2 <- glmer(survived ~ sex + pclass + fare + sibsp + embarked + age.imp + ticket.size + (1 | pclass), 
              data = Training, family = binomial)
summary(Mod2)
Testing <- Testing %>% mutate(
  surv.mod2 = ifelse(predict(Mod2, newdata = Testing, type = "response") > 0.6, 1, 0))
accuracy(Testing$survived, Testing$surv.mod2)

### random forest model
# library('randomForest')
# set.seed(123)
# Mod.rf <- randomForest(survived ~ as.factor(Train$sex) + pclass + age.imp +
#                          fare + as.factor(Train$embarked) + family.size + child + has.age + ticket.size, 
#                        data = Train)
# print(Mod.rf)
# Test <- Test %>% mutate(surv.mod.rf = predict(Mod.rf, newdata = Test))
# accuracy(Test$survived, Test$surv.mod.rf)

### machine learning logit (caret) [random forest]
trainData <- trainControl(method = "repeatedcv", number = 10, savePredictions = TRUE, repeats = 10)
Mod3 <- train(survived ~ sex + pclass + age.imp + 
                fare + embarked + family.size + 
                child + has.age + ticket.size + title,
              data = Training, trControl = trainData, method = "rf", nTree = 101,
              metric = "Accuracy", na.action = na.omit, tuneLength = 5)
summary(Mod3)
confusionMatrix(Mod3)
print(Mod3)

# test on Testing
Testing <- Testing %>% mutate(surv.pred = predict.train(Mod3, newdata = Testing))
accuracy(Testing$survived, Testing$surv.pred)

#####################################
### create forecast / upload file ###
#####################################
# use best model here and apply on full Train data
Mod.Submit <- train(survived ~ sex + pclass + age.imp + 
                      fare + embarked + family.size + child + 
                      has.age + ticket.size + title,
                    metric = "Accuracy", data = Train, trControl = trainData, 
                    method = "rf", nTree = 101, tuneLength = 5)
confusionMatrix(Mod.Submit)

# create submission
TestSub <- Test %>% mutate(Survived = predict.train(Mod.Submit, newdata = Test)) %>% 
  rename(PassengerId = passengerid)
Submission <- TestSub[,c("PassengerId", "Survived")]
write_excel_csv(Submission, path = "C:/Users/Moritz/OneDrive/submission.csv", col_names = TRUE)
