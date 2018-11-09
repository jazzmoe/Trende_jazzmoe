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
names(Test) <- str_to_lower(names(Test))
Train <- Train %>% mutate(survived = as.factor(survived))
glimpse(Train)

# define test and training in test set
TrainTest <- sample_n(Train, size = round(0.2*(nrow(Train))))
TrainTrain <- Train[!(Train$passengerid %in% TrainTest$passengerid),]

#### EDA: exploratory data analysis
Train %>% ggplot() + geom_histogram(aes(x = age))
Train %>% ggplot() + geom_histogram(aes(x = fare))
Train %>% ggplot() + geom_bar(aes(x = sex))
Train %>% ggplot() + geom_bar(aes(x = pclass))

table(Train$sibsp, Train$survived)
chisq.test(Train$sibsp, Train$survived) # significant relationship

### Simple logistic regression
Mod1 <- glm(survived ~ sex + fare, data = TrainTrain, family = "binomial", na.action = na.omit)
TrainTest <- TrainTest %>% mutate(
  surv.mod1 = ifelse(predict(Mod1, newdata = TrainTest, type = "response") > 0.6, 1, 0),
  surv.mod1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(TrainTest$survived, TrainTest$surv.mod1)

# alternative / full model
Mod1.1 <- glm(survived ~ sex + fare + pclass + age, data = TrainTrain, family = "binomial")
TrainTest <- TrainTest %>% mutate(
  surv.mod1.1 = ifelse(predict(Mod1.1, newdata = TrainTest, type = "response") > 0.6, 1, 0),
  surv.mod1.1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(TrainTest$survived, TrainTest$surv.mod1.1)

### random effects model
Mod2 <- glmer(survived ~ sex + fare + sibsp + (1 | pclass), data = TrainTrain, family = binomial)
summary(Mod2)
TrainTest <- TrainTest %>% mutate(
  surv.mod2 = ifelse(predict(Mod2, newdata = TrainTest, type = "response") > 0.6, 1, 0))
accuracy(TrainTest$survived, TrainTest$surv.mod2)

# good source https://www.r-bloggers.com/evaluating-logistic-regression-models/
### machine learning logit (caret)
trainData <- trainControl(method = "cv", number = 10, savePredictions = TRUE)
Mod3 <- train(survived ~ sex + pclass + age + sibsp + parch + fare, 
              data = Train, trControl = trainData, method = "rf", nTree = 100,
              metric = "Accuracy", na.action = na.omit)
confusionMatrix(Mod3)
print(Mod3)
accuracy(Mod3$pred$pred, Mod3$pred$obs)
Mod3.pred <- ifelse(predict(Mod3, newdata = Test, type = "prob") > 0.5, 1, 0) %>% 
  as_tibble() %>% rename("Died" = `0`, "Survived" = `1`)


### create forecast
Bench <- cbind(SubTemp, modpred = Mod3.pred$Survived)
table(Bench$Survived, Bench$modpred)
