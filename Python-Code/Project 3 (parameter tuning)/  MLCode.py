# -*- coding: utf-8 -*-
"""
Created on Thu Feb 28 14:35:35 2019

@author: David Contento
"""

##getting data##
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
data=pd.read_csv('newdata.csv')

##cleaning data##
#splitting string binaries ("yes","no") into dummies  
data=pd.get_dummies(data, columns=['school','Pstatus','famsize','schoolsup',
                                      'famsup','activities','paid','internet',
                                      'nursery','higher','romantic','address','sex'])   

#removing unnecessary dummy variables                                               
del data['school_GP']                                                   
del data['Pstatus_A']                                                   
del data['famsize_GT3']                                                   
del data['schoolsup_no']                                                   
del data['famsup_no']                                                   
del data['activities_yes']  
del data['paid_yes']    
del data['internet_no']                                                      
del data['nursery_no']                                                      
del data['higher_no']
del data['romantic_no']
del data['sex_M']
del data['address_U']
del data['Mjob']
del data['Fjob']
del data['guardian']
del data['reason']

#splitting dependent variable into its own variable
score1=data['G1']
score2=data['G2']
score3=data['G3']

finalscore=[]
for i in range(len(score1)):
    finalscore.append((score1[i]+score2[i]+score3[i])/3)

del data['G1']                                                      
del data['G2']
del data['G3']

newdata=data.values
feat=['age', 'Medu', 'Fedu', 'traveltime', 'studytime', 'failures', 'famrel', 'freetime', 'goout',
       'Dalc', 'Walc', 'health', 'absences', 'school_MS', 'Pstatus_T', 'famsize_LE3',
       'schoolsup_yes', 'famsup_yes', 'activities_no', 'paid_no', 'internet_yes', 'nursery_yes',
       'higher_yes', 'romantic_yes', 'address_R', 'sex_F']
#visualzing test data 
t=np.hstack(finalscore)
plt.hist(t, bins='auto')
plt.show()

#summary statistics 
pd.set_option('display.max_rows', 10)
pd.set_option('display.max_columns', 30)
pd.set_option('display.width', 100)
data.describe()

#Splitting data into training and testing set 
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
        newdata, finalscore, test_size=0.33, random_state=1)

X_train, X_val, y_train, y_val = train_test_split(
        X_train, y_train, test_size=0.28, random_state=1)

K=y_val
###Fitting Models###

############ Fitting SKlearn #########################
from sklearn.linear_model import LinearRegression
import seaborn as sns
clf=LinearRegression()
clf.fit(X_train,y_train)

fig1, ax=plt.subplots(figsize=(27,9))
fig1=sns.barplot(ax=ax, x=feat, y=clf.coef_)
plt.show()

############# Fitting SVM ##########################

from sklearn.svm import SVR
y_train = list(map(int, y_train))
y_val = list(map(int, y_val))


#determining corrects C parameter 
c_range = range(1,15)
svm_c_error = []
for c_value in c_range:
    model = SVR(kernel='linear', C=c_value)
    model.fit(X=X_train, y=y_train)
    error = 1. - model.score(X_val, y_val)
    svm_c_error.append(error)
plt.plot(c_range, svm_c_error)
plt.title('Linear SVM')
plt.xlabel('c values')
plt.ylabel('error')
plt.show()

cmin=min(svm_c_error)
minimum=[]
for i in range(14):
    if (cmin == svm_c_error[i]):
        minimum.append(i)
        
c_value=minimum[0]

#determining appropriate Kernel
kernel_types = ['linear', 'poly', 'rbf']
svm_kernel_error = []
for kernel_value in kernel_types:
    model = SVR(kernel=kernel_value, C=c_value)
    model.fit(X=X_train, y=y_train)
    error = 1. - model.score(X_val, y_val)
    svm_kernel_error.append(error)
plt.plot(kernel_types, svm_kernel_error)
plt.title('SVM by Kernels')
plt.xlabel('Kernel')
plt.ylabel('error')
plt.xticks(kernel_types)
plt.show()

kmin=min(svm_kernel_error)
minimum=[]
for i in range(2):
    if (kmin == svm_kernel_error[i]):
        minimum.append(i)
        
bestkernel=kernel_types[minimum[0]]

clv=SVR(C=c_value, kernel=bestkernel)
clv.fit(X_train,y_train)

################## Random Forest ###################### 
from sklearn.ensemble import RandomForestRegressor

#determining appropriate number of trees
trees=range(1,250)
foresterror = []
for i in trees:
    regr = RandomForestRegressor(random_state=0, n_estimators=i, max_depth=10)
    regr.fit(X_train,y_train)
    error = 1. - regr.score(X_val, y_val)
    foresterror.append(error)
plt.plot(trees, foresterror)
plt.title('Errors by number of trees')
plt.xlabel('number of trees')
plt.ylabel('error')
plt.show()

rmin=min(foresterror)
minimum=[]
for i in range(249):
    if (rmin == foresterror[i]):
        minimum.append(i)
    
rtrees=minimum[0]

#determining appropriate max depth
trees=range(1,30)
deptherror = []
for i in trees:
    regr = RandomForestRegressor(random_state=0, n_estimators=rtrees, max_depth=i)
    regr.fit(X_train,y_train)
    error = 1. - regr.score(X_val, y_val)
    deptherror.append(error)
plt.plot(trees, deptherror)
plt.title('Errors by max_depth')
plt.xlabel('max depth')
plt.ylabel('error')
plt.show()

rmin=min(deptherror)
minimum=[]
for i in range(29):
    if (rmin == deptherror[i]):
        minimum.append(i)
    
maxdepth=minimum[0]

#we can choose max depth this way or by looking at when it stabalizes
regr = RandomForestRegressor(random_state=0, n_estimators=rtrees, max_depth=maxdepth)
regr.fit(X_train,y_train)

###############using testing data to create predicitons with models################# 

#predicting using Random Forest
rdfyhat=regr.predict(X_val)

J=np.hstack(rdfyhat)
plt.hist([J,K], bins='auto', label=['Random Forest','Real Values'])
plt.legend(loc='upper right')
plt.title("Histogram of Random Forest Predictions")
plt.show()

#predicting using SKlearn 
sklearnyhat = clf.predict(X_val)

L=np.hstack(sklearnyhat)
plt.hist([L,K], bins='auto', label=['Linear Regression','Real Values'])
plt.legend(loc='upper right')
plt.title("Histogram of linear Regression Prediction")
plt.show()

#predicting Using SVM 
svmyhat= clv.predict(X_val)

N=np.hstack(svmyhat)
plt.hist([N,K], bins='auto', label=['SVM','Real Values'])
plt.legend(loc='upper right')
plt.title("Histogram of SVM predictions vs Real")
plt.show()

####################Comparing model errors#######################
#calculating prediction error of each model 

#Error of Random Forest
testYDiff = np.abs(rdfyhat - y_val)
avgErr = np.mean(testYDiff)
stdErr = np.std(testYDiff)

print('average error Random Forest: {} ({})'.format(avgErr, stdErr))

#Error of Sklearn 
testYDiff = np.abs(sklearnyhat - y_val)
avgErr = np.mean(testYDiff)
stdErr = np.std(testYDiff)

print('average error SKlearn: {} ({})'.format(avgErr, stdErr))

#Error of SVM
testYDiff = np.abs(svmyhat - y_val)
avgErr = np.mean(testYDiff)
stdErr = np.std(testYDiff)

print('average error SVM: {} ({})'.format(avgErr, stdErr))


##################after valdiating we use test data to confirm the best model is well specified ##################
#predict using test data
rdfyhat=regr.predict(X_test)

#comparing error to test data 
testYDiff = np.abs(rdfyhat - y_test)
avgErr = np.mean(testYDiff)
stdErr = np.std(testYDiff)

print('average error Random Forest (test data): {} ({})'.format(avgErr, stdErr))

#when we all clicking like golden state 
#and you and you team are the motorcade 
#if you know you know 










