setwd("C:/Users/David/Desktop/Capstone/mb/core")
library(apaTables)

bat=read.csv("Batting.csv", header = T)
sal=read.csv("Salaries.csv", header = T)
pit=read.csv("Appearances.csv",header = T)

#creating dummy for pitcher
pit$pitch=NULL
for(i in 1:104256){
if(pit$G_p[i]>4){pit$pitch[i]=1}else{pit$pitch[i]=0}
}

#creating dummy for Outfielder 
pit$outf=NULL
for(i in 1:104256){
  if(pit$G_of[i]>4){pit$outf[i]=1}else{pit$outf[i]=0}
}

#creating dummy for catcher 
pit$catch=NULL
for(i in 1:104256){
  if(pit$G_c[i]>4){pit$catch[i]=1}else{pit$catch[i]=0}
}
#everyone else is considered an infielder 

#On Base Percentage
bat$obp=NULL
for(i in 1:104324){
  bat$obp[i]=((bat$H[i]+bat$BB[i]+bat$HBP[i])/(bat$AB[i]+bat$BB[i]+bat$HBP[i]+bat$SF[i]))
}

#Slugging Percentage
#first have to calculate single hits 
bat$X1B=NULL
for(i in 1:104324){
  bat$X1B[i]=bat$H[i]-bat$X2B[i]-bat$X3B[i]-bat$HR[i]
}
bat$slug=NULL
for(i in 1:104324){
  bat$slug[i]=((bat$X1B[i]+2*bat$X2B[i]+3*bat$X3B[i]+4*bat$HR[i])/bat$AB[i])
}

#removing NAN from Bat
bat=na.omit(bat)

#labor market efficiency
newsal=merge(bat,sal,by=c("playerID", "yearID"))
newsal=merge(newsal,pit, by=c("playerID", "yearID"))

#removing unwanted variables 
newsal=newsal[,-c(4,5,26,27,30:47)] #salary per player per season/year (with stats)
newsal1=newsal

#adjusting for inflation with salary
cpi=read.csv("CPIAUCSL.csv")
cpi$inf=NULL
for(i in 1:34){
  cpi$inf[i]=(cpi$CPI[34]/cpi$CPI[i])
}

for(i in 1:25777){for(k in 1:34){if(newsal$yearID[i]==(1984+k)){newsal$salary[i]=newsal$salary[i]*cpi$inf[k]}else{newsal$salary[i]=newsal$salary[i]}}
}

#removing zero OBP & salary (more than 40 plate appearances)
newsal=newsal[newsal$obp != 0,]
newsal=newsal[newsal$salary != 0,]
newsal=newsal[newsal$AB >= 40,]
newsal=newsal[newsal$slug != 0,]

#moving salaries so it aligns with previous years stats
for(i in 1:15365){
  if(newsal$playerID[i+1]==newsal$playerID[i]){newsal$salary[i]=newsal$salary[i+1]}else{newsal=newsal[-i,]}
}

newsal1=newsal1[newsal1$obp != 0,]
newsal1=newsal1[newsal1$salary != 0,]
newsal1=newsal1[newsal1$AB >= 40,]
newsal1=newsal1[newsal1$slug != 0,]

for(i in 1:15365){
  if(newsal1$playerID[i+1]==newsal1$playerID[i]){newsal1$salary[i]=newsal1$salary[i+1]}else{newsal1=newsal[-i,]}
}

#saving and loading environments 
save.image(file='myEnvironment.RData')
load("myEnvironment.RData")

######################variable analysis#########################
library(MASS)
library(car)

#testing if we need to transform salary data
boxplot(newsal$salary)
p=powerTransform(cbind(salary)~1, newsal, family="bcPower")
summary(p)
symbox(newsal$salary)

#regression before aggregation
reg1=lm(log(newsal$salary)~newsal$obp+newsal$slug+newsal$AB+newsal$catch+newsal$pitch+newsal$outf)
summary(reg1)

#2016-2010
newsal2016=newsal[newsal$yearID==2016|newsal$yearID==2015|newsal$yearID==2014|newsal$yearID==2013|newsal$yearID==2012|newsal$yearID==2011|newsal$yearID==2010,]
reg2016=lm(log(newsal2016$salary)~newsal2016$obp+newsal2016$slug+newsal2016$AB+newsal2016$catch+newsal2016$pitch+newsal2016$outf)
summary(reg2016)

#2009-2003
newsal2015=newsal[newsal$yearID==2009|newsal$yearID==2008|newsal$yearID==2007|newsal$yearID==2006|newsal$yearID==2005|newsal$yearID==2004|newsal$yearID==2003,]
reg2015=lm(log(newsal2015$salary)~newsal2015$obp+newsal2015$slug+newsal2015$AB+newsal2015$catch+newsal2015$pitch+newsal2015$outf)
summary(reg2015)

#2002-1996
newsal2014=newsal[newsal$yearID==2002|newsal$yearID==2001|newsal$yearID==2000|newsal$yearID==1999|newsal$yearID==1998|newsal$yearID==1997|newsal$yearID==1996,]
reg2014=lm(log(newsal2014$salary)~newsal2014$obp+newsal2014$slug+newsal2014$AB+newsal2014$catch+newsal2014$pitch+newsal2014$outf)
summary(reg2014)

#1995-1989
newsal2013=newsal[newsal$yearID==1995|newsal$yearID==1994|newsal$yearID==1993|newsal$yearID==1992|newsal$yearID==1991|newsal$yearID==1990|newsal$yearID==1989,]
reg2013=lm(log(newsal2013$salary)~newsal2013$obp+newsal2013$slug+newsal2013$AB+newsal2013$catch+newsal2013$pitch+newsal2013$outf)
summary(reg2013)

#1988-1982
newsal2012=newsal[newsal$yearID==1988|newsal$yearID==1987|newsal$yearID==1986|newsal$yearID==1985|newsal$yearID==1984|newsal$yearID==1983|newsal$yearID==1982,]
reg2012=lm(log(newsal2012$salary)~newsal2012$obp+newsal2012$slug+newsal2012$AB+newsal2012$catch+newsal2012$pitch+newsal2012$outf)
summary(reg2012)
###############################do the same thing but with dummies (rsquared)##########################
#get newsal to be not adjusted already
reg1=lm(log(newsal1$salary)~newsal1$obp+newsal1$slug+newsal1$AB+newsal1$catch+newsal1$pitch+newsal1$outf+factor(yearID), data=newsal1)
summary(reg1)

#2016-2013
newsal2016=newsal1[newsal1$yearID==2016|newsal1$yearID==2015|newsal1$yearID==2014|newsal1$yearID==2013|newsal1$yearID==2012|newsal1$yearID==2011|newsal1$yearID==2010,]
reg2016=lm(log(newsal2016$salary)~newsal2016$obp+newsal2016$slug+newsal2016$AB+newsal2016$catch+newsal2016$pitch+newsal2016$outf+factor(yearID), data=newsal2016)
summary(reg2016)

#2009-2003
newsal2015=newsal1[newsal1$yearID==2009|newsal1$yearID==2008|newsal1$yearID==2007|newsal1$yearID==2006|newsal1$yearID==2005|newsal1$yearID==2004|newsal1$yearID==2003,]
reg2015=lm(log(newsal2015$salary)~newsal2015$obp+newsal2015$slug+newsal2015$AB+newsal2015$catch+newsal2015$pitch+newsal2015$outf+factor(yearID), data=newsal2015)
summary(reg2015)

#2002-1996
newsal2014=newsal1[newsal1$yearID==2002|newsal1$yearID==2001|newsal1$yearID==2000|newsal1$yearID==1999|newsal1$yearID==1998|newsal1$yearID==1997|newsal1$yearID==1996,]
reg2014=lm(log(newsal2014$salary)~newsal2014$obp+newsal2014$slug+newsal2014$AB+newsal2014$catch+newsal2014$pitch+newsal2014$outf+factor(yearID), data=newsal2014)
summary(reg2014)

#1995-1989
newsal2013=newsal1[newsal1$yearID==1995|newsal1$yearID==1994|newsal1$yearID==1993|newsal1$yearID==1992|newsal1$yearID==1991|newsal1$yearID==1990|newsal1$yearID==1989,]
reg2013=lm(log(newsal2013$salary)~newsal2013$obp+newsal2013$slug+newsal2013$AB+newsal2013$catch+newsal2013$pitch+newsal2013$outf+factor(yearID), data=newsal2013)
summary(reg2013)

#1988-1982
newsal2012=newsal1[newsal1$yearID==1988|newsal1$yearID==1987|newsal1$yearID==1986|newsal1$yearID==1985|newsal1$yearID==1984|newsal1$yearID==1983|newsal1$yearID==1982,]
reg2012=lm(log(newsal2012$salary)~newsal2012$obp+newsal2012$slug+newsal2012$AB+newsal2012$catch+newsal2012$pitch+newsal2012$outf+factor(yearID), data=newsal2012)
summary(reg2012)

library(lfe)
reg1=felm(log(salary)~obp+slug+AB+catch+pitch+outf| yearID, data=newsal1)
summary(reg1)

reg2=felm(log(salary)~obp+slug+AB+catch+pitch+outf| yearID, data=newsal2016)
summary(reg2)

reg3=felm(log(salary)~obp+slug+AB+catch+pitch+outf| yearID, data=newsal2015)
summary(reg3)

reg4=felm(log(salary)~obp+slug+AB+catch+pitch+outf| yearID, data=newsal2014)
summary(reg4)

reg5=felm(log(salary)~obp+slug+AB+catch+pitch+outf| yearID, data=newsal2013)
summary(reg5)

reg6=felm(log(salary)~obp+slug+AB+catch+pitch+outf| yearID, data=newsal2012)
summary(reg6)

#########change these after adding in time dummies############
#plotting labor returns on over time (valuation of stats)
library(ggplot2)
library(reshape2)
onbase=c(reg2012$coefficients[2],reg2013$coefficients[2],reg2014$coefficients[2],reg2015$coefficients[2],reg2016$coefficients[2])
slugging=c(reg2012$coefficients[3],reg2013$coefficients[3],reg2014$coefficients[3],reg2015$coefficients[3],reg2016$coefficients[3])
time=c(2012,2013,2014,2015,2016)
ds=data.frame(time,slugging,onbase)

ggplot(ds, aes(time))+geom_line(aes(y=onbase, color="obp"), size=1)+
  geom_line(aes(y=slugging, color="slugging"), size=1)+ylab("Impact on Log Salary")+
  geom_point(aes(y=onbase),color="red",shape = 18,size=3)+geom_point(aes(y=slugging),color="blue",shape = 18,size=3)+
  ggtitle("Returns to On-Base and Slugging percentage")+geom_hline(yintercept = 0)+
  scale_color_discrete(name = "Legend", labels = c("On base Percentage","Slugging"))+ 
  scale_x_continuous(labels=c("1982-1988","1989-1995","1996-2002","2003-2009","2010-2016"))

####################history#########################
hist=read.csv("History.csv", header=T)
gamelog=read.table("GL2010.txt", sep = ",")

chc=hist[hist$Tm=="CHC",]
library(lubridate)
library(vars)

#creating TS object
chc$Year=lubridate::ymd(chc$Year,truncated = 2L)
chc=chc[,-1]
wins=ts(chc[,4], start=1888,freq=1)
slug=ts(chc[,24],start=1888,freq=1)
slug=slug[-1]
slug=append(slug,1)
slug=ts(slug)
obp=ts(chc[,23],start=1888,freq=1)
obp=obp[-1]
obp=append(obp,1)
obp=ts(obp)
        
time=cbind(wins,slug)
time=data.frame(time)

#VAR model (slugging)
regvar=VAR(time)
summary(regvar)

#VAR model (OBP)
time=cbind(wins,obp)
time=data.frame(time)

regvar=VAR(time)
summary(regvar)

#granger test
grangertest(wins~slug)
grangertest(wins~obp)

#slug and OBP on wins 
regwin=lm(log(hist$Wtm)~hist$SLG+hist$OBP)
summary(regwin)

#######################Team efficiency####################
library(Lahman)
teams=read.csv("teams.csv", header=T)
teams=teams[,c(1:4,6:7,9:10,15,22,29,43)]
teams$winpercentage=NULL
for(i in 1:2865){
teams$winpercentage[i]=(teams$W[i]/teams$G[i])
}
attend=teams 

#plotting salaries and win percentage (entire data set)
salaries = as.data.table(Salaries)
salaries = salaries[, c("lgID", "teamID", "salary1M") := 
                      list(as.character(lgID), as.character(teamID), salary / 1e6L)]
payroll = salaries[, .(payroll = sum(salary1M)), by=.(teamID, yearID)]
teamPayroll = merge(teams, payroll, by=c("teamID","yearID"))

paysalary=lm(teamPayroll$winpercentage~teamPayroll$payroll)
summary(paysalary)

ggplot(teamPayroll,aes(x=payroll,y=winpercentage))+
  geom_point()+geom_smooth(method='lm',formula=y~x)+xlab("Payroll (In millions)")+ylab("Win Percentage")+
  ggtitle("Effect of Payroll on Winning")

#splitting data into different dates and plotting 
data1=teamPayroll[teamPayroll$yearID>=1985 & teamPayroll$yearID<1995,]
data2=teamPayroll[teamPayroll$yearID>=1995 & teamPayroll$yearID<2005,]
data3=teamPayroll[teamPayroll$yearID>=2005 & teamPayroll$yearID<=2016,]
ggplot(teamPayroll, aes(x=payroll,y=winpercentage))+geom_point(data=data1, aes(color="myline1"))+
  geom_point(data=data2,aes(color="myline2"))+geom_point(data=data3,aes(color="myline3"))+
  geom_smooth(data = data1, method='lm',aes(x=payroll,y=winpercentage),formula=y~x, color="red")+
  geom_smooth(data = data2, method='lm',aes(x=payroll,y=winpercentage),formula=y~x, color="green")+
  geom_smooth(data = data3, method='lm',aes(x=payroll,y=winpercentage),formula=y~x, color="blue")+
  xlab("Payroll (In millions)")+ylab("Win Percentage")+ggtitle("Effect of Payroll on Winning Over Time")+
  scale_color_discrete(name = "Legend", labels = c("1985-1994", "1995-2004", "2005-2016"))
  
#change in how payroll affects wins overtime
coef=NULL
lmodelsEach = vector("list", length = length(YEARS))
for(i in 1:32) {
  data = teamPayroll[teamPayroll$yearID==i+1984,]
  lmodelsEach=lm(formula = winpercentage ~ payroll, data = data)
  coef[i]=lmodelsEach$coefficients[2]
}
years=seq(1985,2016)
beta=data.frame(years,coef)

ggplot(beta,aes(x=years,y=coef))+geom_point()+geom_line(size=1)+xlab("Years")+ylab("Coefficient of Payroll")+
  ggtitle("Coefficient of Payroll on Winning Percentage over time")
#####talk about the 2002 luxury tax and how it influenced regressions####

############################### team salary and winning plot over the past five years######################
data1=teamPayroll[teamPayroll$yearID==2016|teamPayroll$yearID==2015|teamPayroll$yearID==2014,]
datareg1=lm(data1$W~data1$payroll)
summary(datareg1)

data2=teamPayroll[teamPayroll$yearID==2013|teamPayroll$yearID==2012|teamPayroll$yearID==2011,]
datareg2=lm(data2$W~data2$payroll)
summary(datareg2)

data3=teamPayroll[teamPayroll$yearID==2010|teamPayroll$yearID==2009|teamPayroll$yearID==2008,]
datareg3=lm(data3$W~data3$payroll)
summary(datareg3)

data4=teamPayroll[teamPayroll$yearID==2007|teamPayroll$yearID==2006|teamPayroll$yearID==2005,]
datareg4=lm(data4$W~data4$payroll)
summary(datareg4)

data5=teamPayroll[teamPayroll$yearID==2004|teamPayroll$yearID==2003|teamPayroll$yearID==2002,]
datareg5=lm(data5$W~data5$payroll)
summary(datareg5)

data6=teamPayroll[teamPayroll$yearID==2001|teamPayroll$yearID==2000|teamPayroll$yearID==1999,]
datareg6=lm(data6$W~data6$payroll)
summary(datareg6)

data7=teamPayroll[teamPayroll$yearID==1998|teamPayroll$yearID==1997|teamPayroll$yearID==1996,]
datareg7=lm(data7$W~data7$payroll)
summary(datareg7)

data8=teamPayroll[teamPayroll$yearID==1995|teamPayroll$yearID==1994|teamPayroll$yearID==1993,]
datareg8=lm(data8$W~data8$payroll)
summary(datareg8)

data9=teamPayroll[teamPayroll$yearID==1992|teamPayroll$yearID==1991|teamPayroll$yearID==1990,]
datareg9=lm(data9$W~data9$payroll)
summary(datareg9)

data10=teamPayroll[teamPayroll$yearID==1989|teamPayroll$yearID==1988|teamPayroll$yearID==1987,]
datareg10=lm(data10$W~data10$payroll)
summary(datareg10)

coef1=NULL
for(i in 1:32){
  data=teamPayroll[teamPayroll$yearID==(i+1984),]
  datareg=lm(data$W~data$payroll)
  coef1[i]=datareg$coefficients[2]
}
time=c(1985:2016)
dc=data.frame(time,coef1)

ggplot(dc, aes(x=time))+geom_line(aes(y=coef1), color="black", size=1)+
  geom_point(aes(y=coef1),color="black",shape = 18,size=3)+ggtitle("Effect of payroll on winning (coefficients)")+xlab("Time (1985-2016)")+ 
  geom_vline(xintercept=2003, color="red")+geom_vline(xintercept=1997, color="blue")

################maybe test for strucutal break#####################



#########################does winning increase attendance##############################
attendreg=lm(log(attend$attendance)~log(attend$winpercentage))
summary(attendreg)

ggplot(attend,aes(x=winpercentage,y=attendance))+
  geom_point()+geom_smooth(method='lm',formula=y~x)+xlab("Win Percentage")+ylab("Attendance")+
  ggtitle("Effect of winning percentage on attendance")

attendreg=lm(log(teamPayroll$attendance)~log(teamPayroll$winpercentage)+log(teamPayroll$payroll)+log(teamPayroll$R))
summary(attendreg)
#attendance over time? (VAR model if winning percentage causes attendence?)
#show overtime how payroll and winning percentage affect attendance?
#grangercause
grangertest(attend$attendance~attend$winpercentage,data=attend)






####################aggregation######################
#salary per player over career
saltotal=aggregate(newsal, by=list(playerID=newsal$playerID), mean)
#fixing dummies 
for(i in 1:5005){
  if(saltotal$pitch[i]>.25){saltotal$pitch[i]=1}else{saltotal$pitch[i]=0}
}
for(i in 1:5005){
  if(saltotal$outf[i]>.25){saltotal$outf[i]=1}else{saltotal$outf[i]=0}
}
for(i in 1:5005){
  if(saltotal$catch[i]>.25){saltotal$catch[i]=1}else{saltotal$catch[i]=0}
}

row_sub=NULL
for(i in 5005){
  if(saltotal$obp[i]!=0){row_sub[i]=(i)}else{row_sub[i]=row_sub[i]}
}

#regression 2
attach(saltotal)
reg2=lm(log(salary)~obp+slug+AB+catch+pitch+outf)
summary(reg2)

#for VAR maybe lagging it will work?






























