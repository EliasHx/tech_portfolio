###############
## SESSION 2 ##
###############

library(readxl)
my_germ <- read_excel("path")
summary(my_germ)

# looking into "purpose" and "good_bad"
table(my_germ$purpose)
table(my_germ$good_bad)

# creating two scalers to better understand our dataframe
num_cust <- nrow(my_germ)
num_var <- ncol(my_germ)
my_germ_dim <- c(num_cust, num_var)

# implementing business logic using which()
which(my_germ$purpose == "X")
my_germ[ which(my_germ$purpose == "X") , c("purpose") ] <- "10"
my_germ$purpose <- as.numeric(my_germ$purpose)

# implementing business logic on good_bad
my_germ[ which(my_germ$good_bad == "good") ,c("good_bad") ] <- "1"   # 1 is business success
my_germ[ which(my_germ$good_bad == "bad") ,c("good_bad") ] <- "0"    # 0 is business failure
my_germ$good_bad <- as.numeric(my_germ$good_bad)


###############
## SESSION 3 ##
###############

# looking for descriptive statistics -- custom statistics
cust_desc <- function(my_var){
               my_min <- min(my_var)
               my_std <- sd(my_var)
               my_max <- max(my_var)
               my_mean <- mean(my_var)
               return(c(my_min, my_mean, my_std, my_max))
                             } # closing cust_desc function

#calling our function
cust_desc(my_var=my_germ$checking)
cust_desc(my_var=my_germ$duration)
cust_desc(my_var=my_germ$age)


# creating udf for our risk score:
risk_score_f <- function(w1, w2, w3, w4, var1, var2, var3, var4){
                    my_score <- w1*var1 + w2*var2 + w3*var3 + w4*var4
                    return(my_score)
                    } # closing the risk_score_f function
my_germ$prof_score <- risk_score_f(w1=0.1, var1=my_germ$age,
                                   w2=0.5, var2=my_germ$duration,
                                   w3=0.7, var3=my_germ$coapp,
                                   w4=-0.3, var4=my_germ$installp)

my_germ$team2_score <- risk_score_f(w1=3, var1=my_germ$purpose,
                                   w2=4, var2=my_germ$employed,
                                   w3=1, var3=my_germ$amount,
                                   w4=2, var4=my_germ$savings)

my_germ$team1_score <- risk_score_f(w1=0.2, var1=my_germ$employed,
                                   w2=0.4, var2=my_germ$duration,
                                   w3=0.5, var3=my_germ$history,
                                   w4=-0.7, var4=my_germ$amount)

cust_desc(my_var=my_germ$team1_score)
cust_desc(my_var=my_germ$team2_score)
cust_desc(my_var=my_germ$prof_score)


# dice game
dice_results <- c(3,4,4,3,6,3,3,1,5,1,1,4,5,5,3,2,1,6,6,4,5,2,4,5,4,6,6,6,6,3,6,6,5,1,6,3,5,2,2,1,3,3,1,1,1,2,3,1,2,6,1,3,4,6,5,5,1,4,6,5)
mean(dice_results)

# looking at different shapes of random variables
dice <- sample(1:6, size=100000, replace=TRUE)
mean(dice)
hist(dice)

# coin game
coin <- sample(c(0,1), size=100000, replace=TRUE)
mean(coin)
hist(coin)


###############
## SESSION 4 ##
###############

# exponential distribution
nyc <- rexp(n=100000, rate=0.5) #low lambda
mean(nyc)
hist(nyc)

sfo <- rexp(n=100000, rate=3) #medium lambda
mean(sfo)
hist(sfo)

jpn <- rexp(n=100000, rate=10) #high lambda
mean(jpn)
hist(jpn)

#investigating all the different variables in deutsche bank
my_germ <- as.data.frame(my_germ)
for(i in 1:ncol(my_germ)){
            hist(my_germ[,i])
                } #closing the for loop

# writing a udf to standardize our data
standard <- function(my_var){
              z_score <- ((my_var-mean(my_var))/sd(my_var)*10)+50
              return(z_score)
              } #closing the standard udf

cust_desc(standard(my_var=my_germ$checking))
cust_desc(standard(my_var=my_germ$duration))
cust_desc(standard(my_var=my_germ$age))


#building a normalization UDF with min-max rescaling
normalize <- function(my_var){
                min_max <- (my_var-min(my_var))/(max(my_var)-min(my_var))
                return(min_max)
                  } #closing normalize udf

my_germ$checking_norm <- normalize(my_var=my_germ$checking)
my_germ$duration_norm <- normalize(my_var=my_germ$duration)
my_germ$history_norm <- normalize(my_var=my_germ$history)
my_germ$purpose_norm <- normalize(my_var=my_germ$purpose)
my_germ$amount_norm <- normalize(my_var=my_germ$amount)
my_germ$savings_norm <- normalize(my_var=my_germ$savings)
my_germ$employed_norm <- normalize(my_var=my_germ$employed)
my_germ$installp_norm <- normalize(my_var=my_germ$installp)
my_germ$coapp_norm <- normalize(my_var=my_germ$coapp)
my_germ$age_norm <- normalize(my_var=my_germ$age)
my_germ$existcr_norm <- normalize(my_var=my_germ$existcr)



###############
## SESSION 5 ##
###############


# splitting into training and testing with random smapling
# creating training index
train_idx <- sample(1:num_cust, size=0.8*num_cust)
my_germ_train <- my_germ[ train_idx , ]
my_germ_test <- my_germ[ -train_idx , ]


# building our first predictive model -- machine learning
my_linear <- lm(amount ~ age , data=my_germ_train )
summary(my_linear)


# designing logistic regression-- UNITS
my_logit <- glm(good_bad ~ duration+amount+age+checking+savings+coapp+telephon+installp, 
                data=my_germ_train, family='binomial')   #binomial indicates logistic regression

summary(my_logit)

# interpretation for 'checking' 
exp(6.207e-01)-1   # = 1.86023
# for every unit increase in checking accounts, the odds for business success
# for the dependent variable "good_bad" increases by 86%


# interpretation for 'duration'
exp(-2.912e-02)-1  # -0.0287001
# for every month increase in duration, the odds for business success
# decreases by 2.87%


# designing a UNITLESS model:
my_logit_norm <- glm(good_bad ~ duration_norm + amount_norm + 
                       age_norm +checking_norm + savings_norm +coapp_norm +
                       installp_norm, 
                data=my_germ_train, family='binomial')   #binomial indicates logistic regression

summary(my_logit_norm)

## WE DO NOT CALCULATE EXP FOR THESE COEFFICIENTS BECAUSE THEY ARE NORMALIZED.
## WE CHECK THE COEFFICIENTS AND THEN GO BACK TO THE NORMAL MODEL WITH UNITS
## TO CALCULATE HOW MUCH THE ODDS FOR BUSINESS SUCCESS CHANGE WITH 1 MORE UNIT




###############
## SESSION 6 ##
###############


# implementing the confusion matrix
my_prediction <- predict(my_logit, my_germ_test, type="response")

library(caret)

confusionMatrix( data= as.factor(as.numeric(my_prediction>0.5)),
                 reference= as.factor(as.numeric(my_germ_test$good_bad)) )
# data is the test subset
# reference is the original set


# codifying a GINI Decision Tree
library(rpart)
library(rpart.plot)

# copy-paste logit with units
my_tree <- rpart(good_bad ~ duration+amount+age+checking+savings+coapp+telephon+installp, 
                data=my_germ_train, method="class", cp=0.015)   #class indicated classification
rpart.plot(my_tree)


tree_predict <- predict(my_tree, my_germ_test, type="prob")

confusionMatrix( data= as.factor(as.numeric(tree_predict[,2]>0.5)) ,         # data is the test
                 reference= as.factor(as.numeric(my_germ_test$good_bad)) )   # reference is the original




###############
## SESSION 7 ##
###############


# comparing both models logit and tree on one framework
# AUC ROC -- lift and gains

library(ROCR)

# put logit in rocr
logit_rocr <- prediction(my_prediction, my_germ_test$good_bad)
perf_logit <- performance(logit_rocr, "tpr", "fpr")     
 #tpr = true positive rate
 #fpr = false positive rate
plot(perf_logit, lty=3, lwd=3)

# put tree in rocr
tree_rocr <- prediction(tree_predict[,2], my_germ_test$good_bad)
perf_tree <- performance(tree_rocr, "tpr", "fpr")
plot(perf_tree, lty=3, lwd=3, col="green", add=TRUE)
 
 
