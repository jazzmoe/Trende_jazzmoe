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

# EDA: exploratory data analysis

### Simple logistic regression
Mod1 <- glm(survived ~ sex + fare, data = Train, family = binomial)
summary(Mod1)
Train <- Train %>% mutate(surv.mod1 = ifelse(predict(Mod1, type = "response") > 0.6, 1, 0))
accuracy(Train$survived, Train$surv.mod1)

### random effects model
Mod2 <- glmer(survived ~ sex + fare + sibsp + (1 | pclass), data = Train, family = binomial)
summary(Mod2)
Train <- Train %>% mutate(surv.mod2 = ifelse(predict(Mod2, type = "response") > 0.6, 1, 0))
accuracy(Train$survived, Train$surv.mod2)

### machine learning logit (caret)
Mod3 <- train(survived ~ sex + fare + sibsp + pclass,  data = Train, method = "glm", family = "binomial")
Train <- Train %>% mutate(surv.mod3 = predict(Mod3, type = "prob"))

