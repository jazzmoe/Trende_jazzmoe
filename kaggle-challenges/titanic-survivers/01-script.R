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
library(RANN) # for preprocessing knnImpute


load("./data/Full.RData")

##################################################################
### Modelling ####################################################
##################################################################

Train2 <- Full[!is.na(Full$survived),]
Test2 <- Full[is.na(Full$survived),]

### define test and training in test set;

splitInd <- createDataPartition(y = Train2$survived, p = 0.2, list = FALSE)
Testing <- Train2[splitInd,]
Training <- Train2[-splitInd,]

### machine learning logit (caret) [random forest]
trainData <- trainControl(method = "repeatedcv", number = 10, savePredictions = TRUE, 
                          repeats = 5, classProbs = TRUE, verboseIter = TRUE)

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
# trainData <- trainControl(method = "repeatedcv", number = 10, 
#                           repeats = 10, classProbs = TRUE, verboseIter = TRUE, 
#                           summaryFunction = twoClassSummary)
# tuningGrid <- expand.grid(alpha = 0:1, lambda = seq(0.0001, 1, length = 20))
# Mod.glmnet <- train(survived ~ sex + as.factor(pclass) + age.imp + 
#                 fare + as.factor(embarked) + family.size + child + title,
#               data = Training, trControl = trainData, tuneGrid = tuningGrid, method = "glmnet")
# confusionMatrix(Mod.glmnet)
# Testing <- Testing %>% mutate(surv.pred.glmnet = predict.train(Mod.glmnet, newdata = Testing))
# accuracy(Testing$survived, Testing$surv.pred.glmnet)

#####################################
### create forecast / upload file ###
#####################################
# use best model here and apply on full Train data
trainData <- trainControl(method = "repeatedcv", number = 10, repeats = 10, verboseIter = TRUE)
tuningGrid <- expand.grid(.mtry = c(3, 4, 5, 7, 9, 11, 13),
                         .splitrule = c("gini"), # possible extra trees
                         .min.node.size = c(3, 4, 5, 6))
Mod.Submit <- train(survived ~ sex + pclass + family.size + child.class + SlogL + GID + 
                      title + age.imp + fare.imp + cabin.class,
                    metric = "Accuracy", data = Train2, trControl = trainData, 
                    method = "ranger", tuneGrid = tuningGrid)
confusionMatrix(Mod.Submit)
plot(Mod.Submit)
print(Mod.Submit)

# create submission
TestSub <- Test2 %>% mutate(Survived = predict.train(Mod.Submit, newdata = Test2)) %>% 
  rename(PassengerId = passengerid)
Submission <- TestSub[,c("PassengerId", "Survived")] %>% mutate(Survived = ifelse(Survived == "Died", 0, 1))
write_excel_csv(Submission, path = "C:/Users/Moritz/OneDrive/submission.csv", col_names = TRUE)

###############################################################
### model from kaggle kernel

set.seed(2017)
trControl <- trainControl(method  ="repeatedcv", number = 10, repeats = 5, verboseIter = TRUE)
tuningGrid <- expand.grid(.mtry = c(4, 5, 7, 9, 10),
                          .splitrule = c("gini"), # possible extra trees
                          .min.node.size = c(4, 5, 6))

mod.kernel <- train(survived ~ SlogL + sex + cabin.class + family.size, data = Train2,
                 metric = "Accuracy", trControl = trControl, method = "ranger") 
TestSub <- Test2 %>% mutate(Survived = predict.train(mod.kernel, newdata = Test2)) %>% 
  rename(PassengerId = passengerid)
confusionMatrix(mod.kernel)

Submission <- TestSub[,c("PassengerId", "Survived")] %>% mutate(Survived = ifelse(Survived == "Died", 0, 1))
write_excel_csv(Submission, path = "C:/Users/Moritz/OneDrive/submission.csv", col_names = TRUE)

## other rf better handling factors
library(party)
set.seed(415)
trControl <- trainControl(method  = "repeatedcv", number = 5, repeats = 3, verboseIter = TRUE)

mod.fit <- train(survived ~ SlogL + sex + cabin.class + as.factor(family.size), data = Train2,
                    metric = "Accuracy", trControl = trControl, method = "cforest",
                    controls = cforest_unbiased(ntree = 101, mtry = 3)) 
confusionMatrix(mod.fit)

TestSub <- Test2 %>% mutate(Survived = predict(mod.fit, newdata = Test2, OOB = TRUE)) %>% 
  rename(PassengerId = passengerid)
Submission <- TestSub[,c("PassengerId", "Survived")] %>% mutate(Survived = ifelse(Survived == "Died", 0, 1))
write_excel_csv(Submission, path = "C:/Users/Moritz/OneDrive/submission.csv", col_names = TRUE)
