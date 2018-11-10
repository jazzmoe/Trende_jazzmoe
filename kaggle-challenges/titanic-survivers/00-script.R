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
                          
### define test and training in test set;
splitInd <- createDataPartition(y = Train$survived, p = 0.2, list = FALSE)
Testing <- Train[splitInd,]
Training <- Train[-splitInd,]

#### EDA: exploratory data analysis

# single variables
p1 <- Train %>% ggplot() + geom_histogram(aes(x = age))
p2 <- Train %>% ggplot() + geom_histogram(aes(x = fare))
p3 <- Train %>% ggplot() + geom_bar(aes(x = sex))
p4 <- Train %>% ggplot() + geom_bar(aes(x = pclass))
p5 <- Train %>% ggplot() + geom_boxplot(aes(pclass, fare, group = pclass))

# variable correlations | corr matrices
TrainCorr <- Train[,c("survived", "pclass", "sex", "age", "sibsp", 
                      "parch", "fare", "embarked", "has.cabin")]
pairs.panels(TrainCorr) # corr coefficient

CorrMat <- purrr::map_dfc(TrainCorr, ~ as.integer(.x)) %>% cor(.)
# corrplot.mixed(TrainCorr, lower.col = "black", number.cex = .7)


# test for statistical dependence
sibsp.surv <- table(Train$sibsp, Train$survived)
subsp.surv.chisq <- chisq.test(Train$sibsp, Train$survived) # significant relationship

emb.surv <- table(Train$embarked, Train$survived)
emb.surv.chisq <- chisq.test(Train$embarked, Train$survived) # significant relationship

cabin.surv <- table(Train$has.cabin, Train$survived)
cab.surv.chisq <- chisq.test(Train$has.cabin, Train$survived) # significant relationship

### treating NAs
# impute age by running a regression on age
naFrame <- purrr::map_df(Train, ~ sum(is.na(.x)))

##################################################################
### Simple logistic regression
Mod1 <- glm(survived ~ sex + fare, data = Training, family = "binomial", na.action = na.omit)
Testing <- Testing %>% mutate(
  surv.mod1 = ifelse(predict(Mod1, newdata = Testing, type = "response") > 0.6, 1, 0),
  surv.mod1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(Testing$survived, Testing$surv.mod1)

# alternative / full model
Mod1.1 <- glm(survived ~ sex + fare + pclass + age, data = Training, family = "binomial")
Testing <- Testing %>% mutate(
  surv.mod1.1 = ifelse(predict(Mod1.1, newdata = Testing, type = "response") > 0.6, 1, 0),
  surv.mod1.1 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1)))
accuracy(Testing$survived, Testing$surv.mod1.1)

# alternative 2
Mod1.2 <- glm(survived ~ sex + pclass + embarked, data = Training, 
              family = "binomial", na.action = na.omit)
Testing <- Testing %>% mutate(
  surv.mod1.2 = ifelse(predict(Mod1.2, newdata = Testing, type = "response") > 0.6, 1, 0),
  surv.mod1.2 = ifelse(is.na(surv.mod1), 0, identity(surv.mod1.2)))
accuracy(Testing$survived, Testing$surv.mod1.2)

### random effects model
Mod2 <- glmer(survived ~ sex + fare + sibsp + (1 | pclass), data = Training, family = binomial)
summary(Mod2)
Testing <- Testing %>% mutate(
  surv.mod2 = ifelse(predict(Mod2, newdata = Testing, type = "response") > 0.6, 1, 0))
accuracy(Testing$survived, Testing$surv.mod2)

# good source https://www.r-bloggers.com/evaluating-logistic-regression-models/
### machine learning logit (caret) [random forest]
trainData <- trainControl(method = "repeatedcv", number = 10, savePredictions = TRUE, repeats = 5)
Mod3 <- train(survived ~ sex + pclass + fare + age + embarked + has.cabin, 
              data = Training, trControl = trainData, method = "rf", nTree = 100,
              metric = "Accuracy", na.action = na.omit, tuneLength = 5)
summary(Mod3)
confusionMatrix(Mod3)
print(Mod3)

# test on Testing (without age)
Mod3.pred <- predict(Mod3, newdata = Testing)
accuracy(Testing$survived[which(!is.na(Testing$age))], Mod3.pred)

### create forecast
#How to forecast NAs in age an other independent vars
#Bench <- cbind(SubTemp, modpred = Mod3.pred$Survived) 
#table(Bench$Survived, Bench$modpred)
