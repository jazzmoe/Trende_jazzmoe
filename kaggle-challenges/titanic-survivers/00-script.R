########################################
### Kaggle Challenge: Titanic Survivers

########################################
### Outline

########################################
### Setup

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

# Variable Notes
# pclass: A proxy for socio-economic status (SES)
# 1st = Upper
# 2nd = Middle
# 3rd = Lower
# 
# age: Age is fractional if less than 1. If the age is estimated, is it in the form of xx.5
# 
# sibsp: The dataset defines family relations in this way...
# Sibling = brother, sister, stepbrother, stepsister
# Spouse = husband, wife (mistresses and fiancés were ignored)
# 
# parch: The dataset defines family relations in this way...
# Parent = mother, father
# Child = daughter, son, stepdaughter, stepson
# Some children travelled only with a nanny, therefore parch=0 for them.

### Data prep
names(Train) <- str_to_lower(names(Train))
Train <- Train %>% mutate(survived = as.factor(survived))
glimpse(Train)

# define test and training in test set
TrainTest <- sample_n(Train, size = round(0.2*(nrow(Train))))
Train <- Train[!(Train$passengerid %in% TrainTest$passengerid),]

# EDA: exploratory data analysis

### Simple logistic regression
Mod11 <- glm(survived ~ sex + fare, data = Train, family = "binomial", na.action = na.omit)
TrainTest <- TrainTest %>% mutate(
  surv.mod1 = ifelse(predict(Mod1, newdata = TrainTest, type = "response") > 0.5, 1, 0),
  surv.mod1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(TrainTest$survived, TrainTest$surv.mod1)

# alternative / full model
Mod11.1 <- glm(survived ~ sex + fare + pclass + age + parch + sibsp, data = Train, family = "binomial")
summary(Mod1.1)
TrainTest <- TrainTest %>% mutate(
  surv.mod1.1 = ifelse(predict(Mod1.1, newdata = TrainTest, type = "response") > 0.5, 1, 0),
  surv.mod1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(TrainTest$survived, TrainTest$surv.mod1.1)

# compare models
lrtest(Mod1, Mod11.1) # probably missings in Mod1.1


### random effects model
Mod2 <- glmer(survived ~ sex + fare + sibsp + (1 | pclass), data = Train, family = binomial)
summary(Mod2)
Train <- Train %>% mutate(surv.mod2 = ifelse(predict(Mod2, type = "response") > 0.6, 1, 0))
accuracy(Train$survived, Train$surv.mod2)

# good source https://www.r-bloggers.com/evaluating-logistic-regression-models/
### machine learning logit (caret)
trainData <- trainControl(method = "boot", number = 10, savePredictions = TRUE)
Mod3 <- train(survived ~ sex + fare + pclass + age + parch + sibsp, 
              data = Train, trControl = trainData, method = "glm", family = "binomial",
              metric = "Accuracy", na.action = na.omit)
Mod3$pred
summary(Mod3)
print(Mod3)
