setwd("C:/Users/David/Desktop/Grad school work/403B/project 3")
#problem 3
library(AER)
data("USConsump1979")
data3=USConsump1979
datadf=data.frame(data3)
attach(datadf)

#A)
#calculating investment 
investment=datadf$income-datadf$expenditure
datadf[,3]=investment
colnames(datadf)[3]<-"invest"
datadf

#B)
#Summary statistics and estimate underlying distrbution 
library(psych)
describe(datadf)
summary(datadf)


#C)
#regressing income on expenditure 
reg=lm(datadf$income~datadf$expenditure)
summary(reg)

#D)
#Running two stage regression with investment as instrument 
#stage1
reg1=lm(expenditure~investment)
summary(reg1)
reghat=fitted.values(reg1)

#stage2
reg2=lm(income~reghat)
summary(reg2)

#problem 4
#A)
library(iotools)
library(foreign)
data4=read.dta("fertil1.dta")
data45=read.table("fertil1.raw",header=F)

attach(data4)
reg=lm(kids~educ)
summary(reg)
reg=lm(kids~age+agesq+educ+black+east+west+farm+othrural+town+smcity+y76+y78+y80+y82+y84)
summary(reg)

#there is a negative relationship between fertility and education holding all other factors constant/fixed

#B)
#stage 1 (creating instrument)
iveduc=lm(educ~meduc+feduc+age+agesq+black+east+west+farm+othrural+town+smcity+y76+y78+y80+y82+y84)

educfitted=iveduc$fitted.values

#stage 2 (Implementing Instrument )
ivreg1=lm(kids~educfitted+age+agesq+black+east+west+farm+othrural+town+smcity+y76+y78+y80+y82+y84)
summary(ivreg1)

cor(educ,meduc+feduc)
cor(iveduc$fitted.values,meduc+feduc)

#C)
#including interaction term for education overtime 
ivreg1=lm(kids~educfitted+age+agesq+black+east+west+farm+othrural+town+smcity+y74+y76+y78+y80+y82+y84+
y74educ+y76educ+y78educ+y80educ+y82educ+y84educ)
summary(ivreg1)





















