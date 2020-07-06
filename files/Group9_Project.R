require(jsonlite)
require(httr)
require(data.table)
get_token <- function(username, password, url_site){
  
  post_body = list(username=username,password=password)
  post_url_string = paste0(url_site,'/token/')
  result = POST(post_url_string, body = post_body)
  
  # error handling (wrong credentials)
  if(result$status_code==400){
    print('Check your credentials')
    return(0)
  }
  else if (result$status_code==201){
    output = content(result)
    token = output$key
  }
  
  return(token)
}

get_data <- function(start_date='2020-03-20', token, url_site){
  
  post_body = list(start_date=start_date,username=username,password=password)
  post_url_string = paste0(url_site,'/dataset/')
  
  header = add_headers(c(Authorization=paste('Token',token,sep=' ')))
  result = GET(post_url_string, header, body = post_body)
  output = content(result)
  data = data.table::rbindlist(output)
  data[,event_date:=as.Date(event_date)]
  data = data[order(product_content_id,event_date)]
  return(data)
}


send_submission <- function(predictions, token, url_site, submit_now=F){
  
  format_check=check_format(predictions)
  if(!format_check){
    return(FALSE)
  }
  
  post_string="list("
  for(i in 1:nrow(predictions)){
    post_string=sprintf("%s'%s'=%s",post_string,predictions$product_content_id[i],predictions$forecast[i])
    if(i<nrow(predictions)){
      post_string=sprintf("%s,",post_string)
    } else {
      post_string=sprintf("%s)",post_string)
    }
  }
  
  submission = eval(parse(text=post_string))
  json_body = jsonlite::toJSON(submission, auto_unbox = TRUE)
  submission=list(submission=json_body)
  
  print(submission)
  # {"31515569":2.4,"32939029":2.4,"4066298":2.4,"6676673":2.4,"7061886":2.4,"85004":2.4} 
  
  if(!submit_now){
    print("You did not submit.")
    return(FALSE)      
  }
  
  
  header = add_headers(c(Authorization=paste('Token',token,sep=' ')))
  post_url_string = paste0(url_site,'/submission/')
  result = POST(post_url_string, header, body=submission)
  
  if (result$status_code==201){
    print("Successfully submitted. Below you can see the details of your submission")
  } else {
    print("Could not submit. Please check the error message below, contact the assistant if needed.")
  }
  
  print(content(result))
  
}

check_format <- function(predictions){
  
  if(is.data.frame(predictions) | is.data.frame(predictions)){
    if(all(c('product_content_id','forecast') %in% names(predictions))){
      if(is.numeric(predictions$forecast)){
        print("Format OK")
        return(TRUE)
      } else {
        print("forecast information is not numeric")
        return(FALSE)                
      }
    } else {
      print("Wrong column names. Please provide 'product_content_id' and 'forecast' columns")
      return(FALSE)
    }
    
  } else {
    print("Wrong format. Please provide data.frame or data.table object")
    return(FALSE)
  }
  
}

# this part is main code
subm_url = 'http://167.172.183.67'

u_name = "Group9"
p_word = "cyAmVBA2I7GSM8Mm"
submit_now = FALSE

username = u_name
password = p_word

token = get_token(username=u_name, password=p_word, url=subm_url)
data = get_data(token=token,url=subm_url)

predictions=unique(data[,list(product_content_id)])
predictions[,forecast:=2.3]
send_submission(predictions, token, url=subm_url, submit_now=F)




#********SELMAN*********
products<-unique(data$product_content_id)

#import the data into a list of xts objects
require(xts)
xdata<-list()
for(i in 1:length(products)){
  xdata[[products[i]]]<-xts(data[product_content_id==products[i],c(1,4:11)],
                            order.by = data[product_content_id==products[i]]$event_date)
}


#pad the data with last observed until tomorrow (CAN BE IMPROVED TO EXTRAPOLATION)
for(i in 1:8){
  l<-last(index(xdata[[i]]))
  while(l<=Sys.Date()){
    l<-l+1
    xdata[[i]]<-rbind(xdata[[i]],xts(coredata(last(xdata[[i]])),l))
  }
}



#function to generate trend component at index myindex as a linear model of length h+1 until two days before
lasttrend<-function(series,h,myindex){
  rangelast<- (myindex-2-h):(myindex-2)
  localmodel<-lm(series[as.Date(rangelast)]$sold_count ~ as.integer(index(series[as.Date(rangelast)])),na.action="na.omit")
  as.numeric(localmodel$coefficients[1]+localmodel$coefficients[2]*as.integer(myindex))
}



#generate trend component as linear model prediction of HHHH+1 observations ending two days ago
HHHH<-21 #I found 21 to be good by balancing p value and residuals on an example, and visually it is fine.
for(i in 1:8){
  xdata[[i]]<-cbind(xdata[[i]],trend=NA)
  for (j in (HHHH+3):dim(xdata[[i]])[1]){
    xdata[[i]][j,"trend"]<-lasttrend(xdata[[i]],HHHH,index(xdata[[i]][j]))
  }
}

#fit missing prices with cubic spline interpolation
for(i in 1:8){
  xdata[[i]][which(xdata[[i]][,"price"]<0),"price"]<-NA
  xdata[[i]][,"price"]<-na.spline(xdata[[i]][,"price"])
}

#********YUSUF*********

#install.packages("gtrendsR")
products
require(gtrendsR)
#import google trends data
gtrends <- xts()
gtrends_m <- xts()
tformat(gtrends) = "%Y-%m-%d"
tformat(gtrends_m) = "%Y-%m-%d"
search <- c("Tayt", "Şarj Edilebilir Diş Fırçası", "Mont", "Islak Mendil", 
            "Bikini", "Kablosuz  Kulaklık", "Elektrikli Süpürge", "Yüz Temizleyici")
for(i in 1:8){
  r<-gtrends(search[i], geo="TR",time="today+5-y")$interest_over_time
  r[,1] <- as.Date(r[,1], format = "%Y-%m-%d")
  date <- r[,1]
  date <- as.Date(setdiff(date,last(date,"3 months")),format = "%Y-%m-%d")
  date <- as.Date(setdiff(date,last(date,"1 week")),format = "%Y-%m-%d")
  gtrends<-cbind(gtrends,xts(r[,2], order.by = r[,1])[date])
  x<-gtrends(search[i], geo="TR",time="today 3-m")$interest_over_time
  x[,1] <- as.Date(x[,1], format = "%Y-%m-%d")
  gtrends_m<-cbind(gtrends_m,xts(x[,2], order.by = x[,1]))
}
colnames(gtrends)<-c("1","2","3","4","5","6","7","8")
colnames(gtrends_m)<-c("1","2","3","4","5","6","7","8")
gtrends <- rbind(gtrends, gtrends_m)


#********SELMAN*********

#AT THIS POINT, IT COULD BE BENEFICIAL TO REPLACE REPEATED VALUES FOR PREDICTORS OF LAST THREE DAYS IN THE TABLES
#WITH THEIR RESPECTIVE WINTERS PREDICTED VALUES IN TERMS OF PAST DATA
#AT LEAST GIVE THE LAST WEEKS VALUES INSTEAD OF THE LAST OBSERVED VALUE

#ALSO ADD COLUMNS FOR REGRESSORS OF 7 DAYS AGO AND 2 DAYS AGO FOR EVERY DAY

#NOTICE FOR GTRENDS:
#GTRENDS GO BACK 5 YEARS AND LAST 90 DAYS COULD BE DOWNLOADED DAILY SO THIS DATA SHOULD BE WINTERS-EXTRAPOLATED USING THE gtrends TABLE NOT XDATA



#merge google trends data to xts structures
for(i in 1:8){
  xdata[[i]]<-cbind(xdata[[i]],gtrends[,i])
  colnames(xdata[[i]])[length(colnames(xdata[[i]]))]<-"gtrends"
  xdata[[i]][,"gtrends"]<-na.locf(xdata[[i]][,"gtrends"])   #last observaion carry forward for weekly trends data
}

xdata_lag <- list()
for(i in 1:8){
  xdata_lag[[i]] <- lag(xdata[[i]][,-2], k = 2)
  xdata_lag[[i]] <- cbind(xdata_lag[[i]], xdata[[i]][,2])
}



#Add seasonal component for sales (CAN BE ADDED FOR OTHER PREDICTORS AS WELL)
oneweek<-xts(NA,Sys.Date())
twoweeks<-xts(NA,Sys.Date())
threeweeks<-xts(NA,Sys.Date())

for(i in 1:8){
  xdata_lag[[i]]<-cbind(xdata_lag[[i]],oneweek,twoweeks,threeweeks)
  range<-which(!is.na(xdata_lag[[i]][,"sold_count"]))
  for(j in range){
    if(j<22)next
    xdata_lag[[i]][j,"oneweek"]<-xdata_lag[[i]][j-7,"sold_count"]
    xdata_lag[[i]][j,"twoweeks"]<-xdata_lag[[i]][j-14,"sold_count"]
    xdata_lag[[i]][j,"threeweeks"]<-xdata_lag[[i]][j-21,"sold_count"]
  }
  xdata[[i]]<-cbind(xdata[[i]],oneweek,twoweeks,threeweeks)
  range<-which(!is.na(xdata[[i]][,"sold_count"]))
  for(j in range){
    if(j<22)next
    xdata[[i]][j,"oneweek"]<-xdata[[i]][j-7,"sold_count"]
    xdata[[i]][j,"twoweeks"]<-xdata[[i]][j-14,"sold_count"]
    xdata[[i]][j,"threeweeks"]<-xdata[[i]][j-21,"sold_count"]
  }
}  
products
View(xdata[[1]])
View(xdata_lag[[1]])

#BUILDING LINEAR MODEL!!!!!
predict<-rep(0,8)
predict_old <- rep(0,8)

#********YUSUF*********

#model generating function
mymodel<-function(xtable,range){
  df<-data.frame(coredata(xtable))   #first try a model of everything:
  try<-lm(sold_count ~ .-1,data=df[range,]-1)
  vars <- vector()
  while(mean(summary(try)$coefficients[,4] < 0.05) != 1){
    max <- max(summary(try)$coefficients[,4])
    vars<-append(vars,names(which(summary(try)$coefficients[,4] == max)))
    new<-as.formula(paste("sold_count ~.-", paste(vars,collapse="-"),"-1")) 
    try <- lm(new,data=df[range,])
  }
  try
} 

#********SELMAN*********
models<-lapply(xdata_lag,mymodel,1:(dim(xdata_lag[[8]])[1]-1))
oldmodel <- lapply(xdata,mymodel,1:(dim(xdata_lag[[8]])[1]-3))

lapply(models,summary)
lapply(oldmodel,summary)
real<-rep(0,8)
#predict
for(i in 1:8){
  predict[i]<-predict(models[[i]],newdata=last(data.frame(coredata(xdata_lag[[i]]))))
  predict_old[i] <- predict(oldmodel[[i]],newdata=last(data.frame(coredata(xdata[[i]]))))
  real[i]<-last(xdata_lag[[i]])$sold_count
}
predict
for(i in 1:8){
  if(predict[i] <0){
    predict[i] <- 0
  }
}
products
predict_old
real

#from observations
predict[1] <- predict_old[1]
predict[2] <- predict_old[2]
predict[3] <- predict_old[3]
predict[5] <- predict_old[5]



result<-data.frame(product_content_id=products,forecast=predict)
result<-as.data.table(result)
send_submission(result, token, url=subm_url, submit_now=T)
