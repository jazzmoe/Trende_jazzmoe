########################################
### Kaggle Challenge: Titanic Survivers

########################################
### Outline

########################################
### Setup

try(setwd("C:/Users/Moritz/OneDrive/GitHub/Trende_jazzmoe/kaggle-challenges/titanic-survivers"), silent = TRUE)

rm(list = ls())
source("packages.R")
source("functions.R")
# install.packages('e1071', dependencies=TRUE)
# install.packages("RANN") # for knearest neighbor imputation

load("./data/Full.RData")

##################################################################
### Modelling ####################################################
##################################################################

Train2 <- Full[!is.na(Full$survived),]
Test2 <- Full[is.na(Full$survived),]

### define test and training in test set;

splitInd <- createDataPartition(y = Train2$survived, p = 0.2, list = FALSE)
Testing <- Train[splitInd,]
Training <- Train[-splitInd,]

### Simple logistic regression
Mod1 <- glm(survived ~ sex + fare, data = Training, family = "binomial", na.action = na.omit)
Testing <- Testing %>% mutate(
  surv.mod1 = ifelse(predict(Mod1, newdata = Testing, type = "response") > 0.6, "Survived", "Died"),
  surv.mod1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(Testing$survived, Testing$surv.mod1)

# alternative / full model
Mod1.1 <- glm(survived ~ sex + fare + pclass + age.imp, data = Training, family = "binomial")
Testing <- Testing %>% mutate(
  surv.mod1.1 = ifelse(predict(Mod1.1, newdata = Testing, type = "response") > 0.6, "Survived", "Died"),
  surv.mod1.1 = ifelse(is.na(surv.mod1.1), 0, identity(surv.mod1.1)))
accuracy(Testing$survived, Testing$surv.mod1.1)

# alternative 2
Mod1.2 <- glm(survived ~ sex + pclass + embarked, data = Training, 
              family = "binomial", na.action = na.omit)
Testing <- Testing %>% mutate(
  surv.mod1.2 = ifelse(predict(Mod1.2, newdata = Testing, type = "response") > 0.6, "Survived", "Died"),
  surv.mod1.2 = ifelse(is.na(surv.mod1.2), 0, identity(surv.mod1.2)))
accuracy(Testing$survived, Testing$surv.mod1.2)

### random effects model
Mod2 <- glmer(survived ~ sex + pclass + fare + sibsp + embarked + age.imp + ticket.size + (1 | pclass), 
              data = Training, family = binomial)
#summary(Mod2)
Testing <- Testing %>% mutate(
  surv.mod2 = ifelse(predict(Mod2, newdata = Testing, type = "response") > 0.65, "Survived", "Died"))
accuracy(Testing$survived, Testing$surv.mod2)

# plot roc curve
library(caTools)
colAUC(predict(Mod2, newdata = Testing, type = "response"), Testing$survived, plotROC = TRUE)

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
trainData <- trainControl(method = "repeatedcv", number = 10, savePredictions = TRUE, 
                          repeats = 5, classProbs = TRUE, verboseIter = TRUE)

library(RANN) # for preprocessing knnImpute
Mod3 <- train(survived ~ sex + pclass + age.imp + 
                fare + embarked + family.size + 
                child + has.age + ticket.size + title,
              data = Training, trControl = trainData, method = "ranger",
              metric = "Accuracy", preProcess = c("knnImpute"))
#summary(Mod3)
confusionMatrix(Mod3)
print(Mod3)

# test on Testing
Testing <- Testing %>% mutate(surv.pred = predict.train(Mod3, newdata = Testing))
accuracy(Testing$survived, Testing$surv.pred)

### GLMNET MODEL
trainData <- trainControl(method = "repeatedcv", number = 10, 
                          repeats = 10, classProbs = TRUE, verboseIter = TRUE, 
                          summaryFunction = twoClassSummary)
tuningGrid <- expand.grid(alpha = 0:1, lambda = seq(0.0001, 1, length = 20))
Mod.glmnet <- train(survived ~ sex + as.factor(pclass) + age.imp + 
                fare + as.factor(embarked) + family.size + child + title,
              data = Training, trControl = trainData, tuneGrid = tuningGrid, method = "glmnet")
confusionMatrix(Mod.glmnet)
Testing <- Testing %>% mutate(surv.pred.glmnet = predict.train(Mod.glmnet, newdata = Testing))
accuracy(Testing$survived, Testing$surv.pred.glmnet)

#####################################
### create forecast / upload file ###
#####################################
# use best model here and apply on full Train data
trainData <- trainControl(method = "repeatedcv", number = 10, repeats = 10, verboseIter = TRUE)
tuningGrid <- expand.grid(.mtry = c(3, 4, 5, 7, 9, 11, 13),
                         .splitrule = c("gini"), # possible exzra trees
                         .min.node.size = 5)
Mod.Submit <- train(survived ~ sex + pclass + age.imp + 
                      fare + embarked + family.size + child + title,
                    metric = "Accuracy", data = Train, trControl = trainData, 
                    method = "ranger", tuneLength = 9, tuneGrid = tuningGrid)
confusionMatrix(Mod.Submit)
plot(Mod.Submit)

# create submission
TestSub <- Test %>% mutate(Survived = predict.train(Mod.Submit, newdata = Test)) %>% 
  rename(PassengerId = passengerid)
Submission <- TestSub[,c("PassengerId", "Survived")] %>% mutate(Survived = ifelse(Survived == "Died", 0, 1))
write_excel_csv(Submission, path = "C:/Users/Moritz/OneDrive/submission.csv", col_names = TRUE)
