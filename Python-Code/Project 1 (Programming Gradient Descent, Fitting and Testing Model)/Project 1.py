import numpy as np
import matplotlib.pyplot as plt
from getDataset import getDataSet
from sklearn.linear_model import LogisticRegression

# Starting codes

# Fill in the codes between "%PLACEHOLDER#start" and "PLACEHOLDER#end"

# step 1: generate dataset
# 250 samples in total.

[X, y] = getDataSet()  # note that y contains only 1s and 0s,

# create figure for all charts to be placed on so can be viewed together
fig = plt.figure()


def func_DisplayData(dataSamplesX, dataSamplesY, chartNum, titleMessage):
    idx1 = (dataSamplesY == 0).nonzero()  # object indices for the 1st class
    idx2 = (dataSamplesY == 1).nonzero()
    ax = fig.add_subplot(1, 3, chartNum)
    # no more variables are needed
    plt.plot(dataSamplesX[idx1, 0], dataSamplesX[idx1, 1], 'r*')
    plt.plot(dataSamplesX[idx2, 0], dataSamplesX[idx2, 1], 'b*')
    # axis tight
    ax.set_xlabel('x_1')
    ax.set_ylabel('x_2')
    ax.set_title(titleMessage)


# plotting all samples
func_DisplayData(X, y, 1, 'All samples')

# number of training samples
nTrain = 120

###############################################
# WARNIN: 
import itertools, random
deck = list(range(0, 250))
random.shuffle(deck)
trainindex= deck[:120]
testindex=deck [120:]
#maxIndex = len(X)
#randomTrainingSamples = np.random.choice(maxIndex, nTrain, replace=False)
trainX = X[trainindex,:]
trainY = y[trainindex,:]
 
testX = X[testindex,:]               
testY = y[testindex,:]  
#############################################

# plot the samples you have pickup for training, check to confirm that both negative
# and positive samples are included.
func_DisplayData(trainX, trainY, 2, 'training samples')
func_DisplayData(testX, testY, 3, 'testing samples')

# show all charts
plt.show()


#  step 2: train logistic regression models
###############################################
#train a logistic model using the training data: trainX, and trainY.

# Using Sk learn to fit regression model 
clf = LogisticRegression()
# call the function fit() to train the class instance
clf.fit(trainX,trainY)

# visualize data using functions in the library pylab 
from pylab import scatter, show, legend, xlabel, ylabel
from numpy import where
pos = where(y == 1)
neg = where(y == 0)
scatter(X[pos, 0], X[pos, 1], marker='o', c='b')
scatter(X[neg, 0], X[neg, 1], marker='x', c='r')
xlabel('Feature 1: score 1')
ylabel('Feature 2: score 2')
legend(['Label:  Admitted', 'Label: Not Admitted'])
show()

#using self developed model to fit regression 
from util import Cost_Function, Gradient_Descent, Prediction 

theta = [0,0] #initial model parameters
alpha = 0.1 # learning rates
max_iteration = 1000 # maximal iterations


m = len(y) # number of samples

for x in range(max_iteration):
	# call the functions for gradient descent method
	new_theta = Gradient_Descent(X,y,theta,m,alpha)
	theta = new_theta
	if x % 200 == 0:
		# calculate the cost function with the present theta
		Cost_Function(X,y,theta,m)
		print('theta ', theta)	
		print('cost is ', Cost_Function(X,y,theta,m))

#Comparing Methods
#Calculating Sk learn Score
scikit_score = clf.score(testX,testY)

#Calculating gradient descent score 
score = 0
length = len(testX)
for i in range(length):
    prediction = round(Prediction(testX[i],theta))
    answer = testY[i]
    if prediction == answer:
        score += 1
	
my_score = float(score) / float(length)

print('Score of SK learn method:', scikit_score)
print('Score of Gradient Descent method:', my_score)
###############################################

 
 
# step 3: Use the model to get class labels of testing samples.
 

###############################################
# codes for making prediction, 
# with the learned model, apply the logistic model over testing samples
# hatProb is the probability of belonging to the class 1.
# y = 1/(1+exp(-Xb))
# yHat = 1./(1+exp( -[ones( size(X,1),1 ), X] * bHat )); ));
# WARNING: please DELETE THE FOLLOWING CODEING LINES and write your own codes for making predictions
gdyHat = [Prediction(row,theta) for row in testX]
gdyHat = np.array([float(int(val >= .6)) for val in gdyHat])
sklearnyhat = clf.predict(testX)
#PLACEHOLDER#end

###############################################


# step 4: evaluation
# compare predictions yHat and and true labels testy to calculate average error and standard deviation
#gradient descent average error
testYDiff = np.abs(gdyHat - testY)
avgErr = np.mean(testYDiff)
stdErr = np.std(testYDiff)

print('average error Gradient descent: {} ({})'.format(avgErr, stdErr))

#sk learn average error
testYDiff = np.abs(sklearnyhat - testY)
avgErr = np.mean(testYDiff)
stdErr = np.std(testYDiff)

print('average error SKlearn: {} ({})'.format(avgErr, stdErr))


######################Code for accruracy and per class precision/recall##########################

def func_calConfusionMatrix(predY,trueY):
    #Accuracy
    correctvalues1=0
    for i in range(len(trueY)):
        if(trueY[i] == predY[i]):
            correctvalues1 += 1
    accuracy = (correctvalues1/len(trueY))

    #precision of class zero 
    correctvalues2= 0
    for i in range(len(trueY)):
        if(int(trueY[i]) == int(predY[i]) and int(trueY[i]) == 0):
            correctvalues2 += 1
    precisionzero = (correctvalues2 / len(predY[predY == 0]))
        
    #precision of class one
    correctvalues3 = 0
    for i in range(len(trueY)):
        if(int(trueY[i]) == int(predY[i]) and int(trueY[i]) == 1):
            correctvalues3 += 1
    precisionone = (correctvalues3 / len(predY[predY == 1]))
        
    #recall class zero 
    correctvalues4 = 0
    for i in range(len(trueY)):
        if(int(trueY[i]) == int(predY[i]) and int(trueY[i]) == 0):
            correctvalues4 += 1
    recallzero = correctvalues4 / len(trueY[trueY == 0])
    
    #recall class one
    correctvalues5 = 0
    for i in range(len(trueY)):
        if(int(trueY[i]) == int(predY[i]) and int(trueY[i]) == 1):
            correctvalues5 += 1
    recallone = correctvalues5 / len(trueY[trueY == 1])
        
    return accuracy, precisionzero , precisionone, recallzero, recallone


sklearntest = func_calConfusionMatrix(sklearnyhat,testY)
print('accuracy, precision of class zero, precision of class one, recall of class zero, and recall of class one (Sklearn model):')
print(sklearntest)
gdtest = func_calConfusionMatrix(gdyHat,testY)
print('accuracy, precision of class zero, precision of class one, recall of class zero, and recall of class one (gradient descent model):')
print(gdtest)


###########################Creating confusion matrix#####################

#Sklearn Confusion matrix
correctvalues1= 0
for i in range(len(testY)):
    if(int(sklearnyhat[i]) == 0 and int(testY[i]) == 0):
        correctvalues1 += 1
        
correctvalues2= 0
for i in range(len(testY)):
    if(int(sklearnyhat[i]) == 1 and int(testY[i]) == 1):
        correctvalues2 += 1    
        
correctvalues3= 0
for i in range(len(testY)):
    if(int(sklearnyhat[i]) == 1 and int(testY[i]) == 0):
        correctvalues3 += 1            
                
correctvalues4= 0
for i in range(len(testY)):
    if(int(sklearnyhat[i]) == 0 and int(testY[i]) == 1):
        correctvalues4 += 1            
        
confusionmatrix= [[correctvalues1,correctvalues3],[correctvalues4,correctvalues2]]
confusionmatrix=np.array(confusionmatrix)  
print('confusion matrix of SKlearn')    
print(confusionmatrix)        
        
#Gradient Descent matrix
correctvalues1= 0
for i in range(len(testY)):
    if(int(gdyHat[i]) == 0 and int(testY[i]) == 0):
        correctvalues1 += 1
        
correctvalues2= 0
for i in range(len(testY)):
    if(int(gdyHat[i]) == 1 and int(testY[i]) == 1):
        correctvalues2 += 1    
        
correctvalues3= 0
for i in range(len(testY)):
    if(int(gdyHat[i]) == 1 and int(testY[i]) == 0):
        correctvalues3 += 1            
                
correctvalues4= 0
for i in range(len(testY)):
    if(int(gdyHat[i]) == 0 and int(testY[i]) == 1):
        correctvalues4 += 1      

confusionmatrix= [[correctvalues1,correctvalues3],[correctvalues4,correctvalues2]]
confusionmatrix=np.array(confusionmatrix)  
print('confusion matrix of gradient descent')    
print(confusionmatrix)                
