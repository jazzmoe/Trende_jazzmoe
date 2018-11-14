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
library(party)
library(rpart)
library(caTools)
library(caretEnsemble)

load("./data/Full.RData")

set.seed(415)
##################################################################
### Modelling ####################################################
##################################################################

Train2 <- Full[!is.na(Full$survived),]
Test2 <- Full[is.na(Full$survived),]

### define test and training in test set;
splitInd <- createDataPartition(y = Train2$survived, p = 0.25, list = FALSE)
Testing <- Train2[splitInd,]
Training <- Train2[-splitInd,]

### create a model ensemble of  "cforest", RF, GLMNET, rpart 
trControl <- trainControl(
  method  = "repeatedcv", 
  number = 10, repeats = 3, 
  verboseIter = TRUE,
  savePredictions = "final",
#  index = createResample(Testing$survived, 25),
  classProbs = TRUE)

# Y <- Training$survived
# X <- Training %>% select(c(SlogL, sex, cabin.class))

# child.class, title, embarked, fare.imp, GID, family.size, has.cabin, has.age, sibsp, parch
mod.list <- caretList(survived ~ SlogL + sex + cabin.class + age.imp + fare.imp + title + pclass, 
                      data = Train2,
                      trControl = trControl,
                      metric = "Accuracy",
                      methodList = c("ranger", "glmnet"),                    
                      tuneList = list(
                        glmnet2 = caretModelSpec(method = "glmnet", tuneGrid = 
                                              expand.grid(alpha = 0:1,
                                                          lambda = seq(0.0001, 1, length = 100))),
                        ranger2 = caretModelSpec(method = "ranger", tuneGrid = 
                                                   expand.grid(.mtry = c(1, 2, 3, 4, 5, 6, 7),
                                                               .splitrule = c("gini"),
                                                               .min.node.size = c(1, 2, 3)))))

# inspect models
resamps <- resamples(mod.list)
modelCor(resamps)
summary(resamps)
xyplot(resamps, metric = "Accuracy") 
dotplot(resamps, metric = "Accuracy")
densityplot(resamps, metric = "Accuracy")

# create and ENSEMBLE of the models
greedy.ens <- caretEnsemble(
  mod.list,
  metric = "Accuracy",
  trControl = trainControl(
    number = 10,
    classProbs = TRUE))

# inspect ensemble
summary(greedy.ens)
#varImp(greedy.ens)

# compare predictions from ensemble and models
mod.probs <- purrr::map(mod.list, ~ predict(.x, newdata = Testing, type = "prob")) %>% 
  purrr::map_df(., ~ .x[["Survived"]])
mod.probs$ens.prob <- 1-predict(greedy.ens, newdata = Testing, type = "prob")
cor(mod.probs)

# takes predicted probabilities and finds optimal threshhold to optimize AUC
# AUC of 0.5 is random model, AUC of 1 is perfect model
caTools::colAUC(mod.probs, Testing$survived, plotROC = TRUE)

# compare accuracy
predictions <- purrr::map(mod.list, ~ predict(.x, newdata = Testing, type = "raw")) 
predictions$ens.pred <- predict(greedy.ens, newdata = Testing, type = "raw")
acc <- purrr::map(predictions, ~ accuracy(.x, Testing$survived))
acc

# # caret stack: weights final predictions on linear combination of models
# according to their overall performance
ens.stack <- caretStack(
  mod.list,
  method = "glm",
  metric = "Accuracy",
  trControl = trainControl(
    method = "repeatedcv",
    number = 10,
    savePredictions = "final",
    classProbs = TRUE
  )
)

# investigate stacked model
stack.pred <- predict(ens.stack, newdata = Test2, type = "raw")
ens.pred <- predict(greedy.ens, newdata = Test2, type = "raw")
# ensemble and stack similar? why? difference of functions?

#########
## create submission
Test2$Survived <- predict(mod.list$ranger, newdata = Test2, type = "raw")
Submission <- Test2 %>% select(c("passengerid", "Survived")) %>%
  mutate(Survived = ifelse(Survived == "Died", 0, 1)) %>%
  rename(PassengerId = passengerid)

### make submission
write_excel_csv(Submission, path = "C:/Users/Moritz/OneDrive/submission.csv", col_names = TRUE)



#######





