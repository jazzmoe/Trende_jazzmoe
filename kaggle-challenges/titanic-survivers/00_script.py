import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

# Data import
filepath = "/home/alex/Code/Trende_jazzmoe/kaggle-challenges/titanic-survivers/data/train.csv"
trainData = pd.read_csv(filepath)

filepath = "/home/alex/Code/Trende_jazzmoe/kaggle-challenges/titanic-survivers/data/test.csv"
testData = pd.read_csv(filepath)

# Data Analysis
from sklearn.model_selection import GridSearchCV, cross_val_score
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn import svm

X_train = np.asarray(trainData.Fare).reshape(-1,1)
X_test = np.asarray(testData.Fare )
y_true = np.asarray(trainData.Survived)

y_pred = clf.predict(X_train)
acc = accuracy_score(y_true, y_pred)
print('Accuracy = ' + str(100*round(acc,2)) + '%')
