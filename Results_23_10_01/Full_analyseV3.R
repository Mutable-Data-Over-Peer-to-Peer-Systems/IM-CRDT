
###################################################################################################
###################################################################################################
#usage : 
# Rscript analyseCSV.R  ${Output_folder} ${file_of_input_files} 
# input file :
# nb_peers,nb_update,Version,Mean,system
# 5,100,1,360,IPFS+CRDT
# 10,1000,1,450,IPFS_ALONE
# ...,...,...,...
###################################################################################################
###################################################################################################

library(conflicted)  
# library(dplyr)
library(ggplot2)
library(tidyverse)
# install.packages(plotmath)
library(grDevices)

conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")


pdf("Rplots.pdf",width=11, height=7)

#pdf("Rplots.pdf",width=11, height=11)


##############################- Retrieving data so it can be used -##############################

# IM-CRDT

data_Frame_IM_CRDT = data.frame(CID=character(0),maxlatency=numeric(0),mean_latency=numeric(0),mean_time_retrieve=numeric(0),mean_time_compute=numeric(0),time_add_IPFS=numeric(0),mean_time_pubsub=numeric(0),numUpdates=numeric(0),numberPeers=numeric(0),numberPeerUpdating=numeric(0),System=character(0))

for (nb_peers in c(2, 5, 10, 20, 50) )
{
 for (nb_Peers_Updating in c(1, 2, 5, 10, 20) )
  {
    if (nb_peers >= nb_Peers_Updating)
    {
      for (nb_Updates in c(10, 100, 1000) )
      {
        file=paste("DATA_Experience/IM-CRDT/output_",nb_peers,"Peers_",nb_Peers_Updating,"Updater_",nb_Updates,"Updates.csv", sep = "")
        print(file)
        a = read.csv(file)
        b <- a %>%
          add_column(numUpdates = nb_Updates) %>%
          add_column(numberPeers = nb_peers) %>%
          add_column(numberPeerUpdating = nb_Peers_Updating) %>%
          add_column(System = "IM-CRDT")
        data_Frame_IM_CRDT= rbind(data_Frame_IM_CRDT, b)

      }
    }
  } 
}


write.table(data_Frame_IM_CRDT, "DATA_Experience/totalDATAFRAME_IM-CRDT.csv")


sizes_IM_CRDT=read.csv("DATA_Experience/size_IM_CRDT.csv")
sizes_IM_CRDT <- sizes_IM_CRDT %>%
  add_column(System = "IM-CRDT")

sizes_IPFS_ALONE=read.csv("DATA_Experience/size_IPFS.csv")
sizes_IPFS_ALONE <- sizes_IPFS_ALONE %>%
  add_column(System = "IPFS")





# IPFS

data_Frame_IPFS_Alone = data.frame(CID=character(0),maxlatency=numeric(0),mean_latency=numeric(0),mean_timeRetrieve=numeric(0),mean_timeSend=numeric(0),mean_time_pubsub=numeric(0),numUpdates=numeric(0),numberPeers=numeric(0),numberPeerUpdating=numeric(0),System=character(0))

for (nb_peers in c(2, 5, 10, 20, 50) )
{
    for (nb_Updates in c(10, 100, 1000) )
    {    
        file=paste("DATA_Experience/IPFS_Alone/output_",nb_peers,"Peers_1Updater_",nb_Updates,"Updates.csv", sep = "")
        print(file)
        a = read.csv(file)
        b <- a %>%
          add_column(numUpdates = nb_Updates) %>%
          add_column(numberPeers = nb_peers) %>%
          add_column(numberPeerUpdating = 1) %>%
          add_column(System = "IPFS Alone")
        data_Frame_IPFS_Alone= rbind(data_Frame_IPFS_Alone, b)

    }
}


write.table(data_Frame_IPFS_Alone, "DATA_Experience/totalDATAFRAME_IPFS_Alone.csv")




##############################- Comparison between IM-CRDT and IPFS Alone -##############################
# 10 Updates


data_IM_CRDT = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1)

data_IPFS_Alone = filter(data_Frame_IPFS_Alone, System == "IPFS Alone"  & numberPeerUpdating == 1)


data_IM_CRDT= data.frame(maxlatency=data_IM_CRDT$"maxlatency", System=data_IM_CRDT$"System", numberPeers=data_IM_CRDT$"numberPeers", numUpdates=data_IM_CRDT$"numUpdates")

data_IPFS_Alone= data.frame(maxlatency=data_IPFS_Alone$"maxlatency", System=data_IPFS_Alone$"System", numberPeers=data_IPFS_Alone$"numberPeers", numUpdates=data_IPFS_Alone$"numUpdates")


data=rbind(data_IM_CRDT,data_IPFS_Alone)
data$numberPeers = as.character(data$numberPeers)

# grouped boxplot

wrap_names <- as_labeller(c('10'="10 updates", '100'="100 updates", '1000'="1000 updates"))

p <- data %>%
  mutate(numberPeers = fct_relevel(numberPeers, "2", "5", "10", "20", "50")) %>%
  ggplot( aes(x=numberPeers, y=maxlatency, fill=System)) +
    theme(text = element_text(size =40), legend.position="bottom",legend.title=element_blank() ) +
    geom_boxplot(outlier.shape = NA) +
    facet_wrap(~numUpdates, labeller = wrap_names) +
    scale_fill_discrete(labels = c("IM-CRDT", "IPFS")) +
    xlab("Number of replicas")+
    ylab("Maximum latency (ms)") +
    scale_y_continuous(limits = c(0,600)) 

#     geom_boxplot(outlier.shape = NA, fill=System) 

plot(p)

for (nbp in c(2,5,10,20,50))
{
  for (nbu in c(10,100,1000))
  {
    data_IM_CRDT = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1 & numberPeers == nbp & numUpdates == nbu)

    data_IPFS_Alone = filter(data_Frame_IPFS_Alone, System == "IPFS Alone"  & numberPeerUpdating == 1 & numberPeers == nbp & numUpdates == nbu)


#     print(paste(nbp, nbu, median(data_IM_CRDT$"maxlatency") / median(data_IPFS_Alone$"maxlatency") ))
#     print(paste(median(data_IM_CRDT$"maxlatency"),median(data_IPFS_Alone$"maxlatency") ))
  }
}
# print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-10UPDATES-50Peers-1 VS 20 updater=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")
data_IM_CRDT1 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1 & numberPeers == 50 & numUpdates == 10)
data_IM_CRDT2 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 20 & numberPeers == 50 & numUpdates == 10)
# print(paste(nbp, nbu,  median(data_IM_CRDT1$"maxlatency") /median(data_IM_CRDT2$"maxlatency")  ))
# print(paste(median(data_IM_CRDT1$"maxlatency"),median(data_IM_CRDT2$"maxlatency") ))

# print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-100/1000UPDATES-50Peers-1 VS 20 updater=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")

# print("100Updates")
data_IM_CRDT1 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1 & numberPeers == 50 & numUpdates == 100)
data_IM_CRDT2 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 20 & numberPeers == 50 & numUpdates == 100)
# print(paste(nbp, nbu, median(data_IM_CRDT2$"maxlatency") / median(data_IM_CRDT1$"maxlatency")  ))
# print(paste(median(data_IM_CRDT1$"maxlatency"),median(data_IM_CRDT2$"maxlatency") ))

# print("1000Updates")
data_IM_CRDT1 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1 & numberPeers == 50 & numUpdates == 1000)
data_IM_CRDT2 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 20 & numberPeers == 50 & numUpdates == 1000)
# print(paste(nbp, nbu,  median(data_IM_CRDT2$"maxlatency")  / median(data_IM_CRDT1$"maxlatency")  ))
# print(paste(median(data_IM_CRDT1$"maxlatency"),median(data_IM_CRDT2$"maxlatency") ))


# ggplot(data_IPFS_Alone, aes(x=numberPeers, y=maxlatency)) + 
#     geom_boxplot(outlier.shape = NA, fill=System) 




##############################- Test of scalability of IM-CRDT -##############################


# grouped boxplot
data_Frame_IM_CRDT$numberPeers = as.character(data_Frame_IM_CRDT$numberPeers)
data_Frame_IM_CRDT$numberPeerUpdating = as.character(data_Frame_IM_CRDT$numberPeerUpdating)

# pdf("test.pdf",width=15.7, height=7)
wrap_names <- as_labeller(c('10'="10 updates/peer", '100'="100 updates/peer", '1000'="1000 updates/peer"))

p <- data_Frame_IM_CRDT %>%
  mutate(numberPeerUpdating = fct_relevel(numberPeerUpdating, "1" , "2", "5", "10", "20")) %>%
  mutate(numberPeers = fct_relevel(numberPeers, "2" , "5", "10", "20", "50")) %>%
  ggplot( aes(x=numberPeerUpdating, y=maxlatency / 1000, fill=numberPeers)) +
    theme( text = element_text(size =27), legend.position="bottom") +
    geom_boxplot(outlier.shape = NA) +
    facet_wrap(~numUpdates, labeller = wrap_names) +
    labs(fill = "Number of replicas") + 
    xlab("Number of peers updating")+
    ylab("Maximum latency (s) log scale") +
    scale_y_log10(labels=function(n){format(n, scientific = FALSE)}) 
    # theme()

plot(p)


##############################- evolution of different times -##############################





# create a dataset
specie <- c(rep(1 , 4) , rep(2 , 4) , rep(3 , 4) , rep(4 , 4), rep(5, 4) )
condition <- rep(c("Pubsub", "Add", "Retrieve" , "Compute" ) , 5)


CSVFrameCRDT_IPFS    = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1)
CSVFrameCRDT_IPFS_2  = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 2)
CSVFrameCRDT_IPFS_5  = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 5)
CSVFrameCRDT_IPFS_10 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 10)
CSVFrameCRDT_IPFS_20 = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 20)
CSVFrameCRDT_IPFS$"mean_time_pubsub" = CSVFrameCRDT_IPFS$"mean_time_pubsub" * 1000000 
CSVFrameCRDT_IPFS_2$"mean_time_pubsub" = CSVFrameCRDT_IPFS_2$"mean_time_pubsub" * 1000000 
CSVFrameCRDT_IPFS_5$"mean_time_pubsub" = CSVFrameCRDT_IPFS_5$"mean_time_pubsub" * 1000000 
CSVFrameCRDT_IPFS_10$"mean_time_pubsub" = CSVFrameCRDT_IPFS_10$"mean_time_pubsub" * 1000000 
CSVFrameCRDT_IPFS_20$"mean_time_pubsub" = CSVFrameCRDT_IPFS_20$"mean_time_pubsub" * 1000000 
write.table(CSVFrameCRDT_IPFS, "DATA_Experience/IM-CRDT_20Peers/Mean_steps_time_1updater.csv")
write.table(CSVFrameCRDT_IPFS_2, "DATA_Experience/IM-CRDT_20Peers/Mean_steps_time_2updater.csv")
write.table(CSVFrameCRDT_IPFS_5, "DATA_Experience/IM-CRDT_20Peers/Mean_steps_time_5updater.csv")
write.table(CSVFrameCRDT_IPFS_10, "DATA_Experience/IM-CRDT_20Peers/Mean_steps_time_10updater.csv")
write.table(CSVFrameCRDT_IPFS_20, "DATA_Experience/IM-CRDT_20Peers/Mean_steps_time_20updater.csv")
#print("CSVFrameCRDT_IPFS_20")
# print(CSVFrameCRDT_IPFS_20)

## Value in Nano seconds
value = abs(c(    mean(CSVFrameCRDT_IPFS$"time_add_IPFS", na.rm=TRUE)      , mean(CSVFrameCRDT_IPFS$"mean_time_pubsub", na.rm=TRUE)  , mean(CSVFrameCRDT_IPFS$"mean_time_retrieve", na.rm=TRUE)    , mean(CSVFrameCRDT_IPFS$"mean_time_compute", na.rm=TRUE)    ,
    		mean(CSVFrameCRDT_IPFS_2$"time_add_IPFS", na.rm=TRUE)  , mean(CSVFrameCRDT_IPFS_2$"mean_time_pubsub", na.rm=TRUE)  , mean(CSVFrameCRDT_IPFS_2$"mean_time_retrieve", na.rm=TRUE)  , mean(CSVFrameCRDT_IPFS_2$"mean_time_compute", na.rm=TRUE)  ,
    		mean(CSVFrameCRDT_IPFS_5$"time_add_IPFS", na.rm=TRUE)  , mean(CSVFrameCRDT_IPFS_5$"mean_time_pubsub", na.rm=TRUE)  , mean(CSVFrameCRDT_IPFS_5$"mean_time_retrieve", na.rm=TRUE)  , mean(CSVFrameCRDT_IPFS_5$"mean_time_compute", na.rm=TRUE)  ,
    	   	mean(CSVFrameCRDT_IPFS_10$"time_add_IPFS", na.rm=TRUE) , mean(CSVFrameCRDT_IPFS_10$"mean_time_pubsub", na.rm=TRUE), mean(CSVFrameCRDT_IPFS_10$"mean_time_retrieve", na.rm=TRUE) , mean(CSVFrameCRDT_IPFS_10$"mean_time_compute", na.rm=TRUE) ,
    		mean(CSVFrameCRDT_IPFS_20$"time_add_IPFS", na.rm=TRUE) , mean(CSVFrameCRDT_IPFS_20$"mean_time_pubsub", na.rm=TRUE) , mean(CSVFrameCRDT_IPFS_20$"mean_time_retrieve", na.rm=TRUE) , mean(CSVFrameCRDT_IPFS_20$"mean_time_compute", na.rm=TRUE)  ) )
    		
    		
write.table(data, "Mean_steps_time.csv")
    		
    		
## value in milli seconds		
value = abs(c(   mean(CSVFrameCRDT_IPFS$"mean_time_pubsub", na.rm=TRUE)   / 1000 ,   mean(CSVFrameCRDT_IPFS$"time_add_IPFS", na.rm=TRUE) / 1000  , mean(CSVFrameCRDT_IPFS$"mean_time_retrieve", na.rm=TRUE)   / 1000, mean(CSVFrameCRDT_IPFS$"mean_time_compute", na.rm=TRUE)    / 1000,
    		 mean(CSVFrameCRDT_IPFS_2$"mean_time_pubsub", na.rm=TRUE) / 1000 ,   mean(CSVFrameCRDT_IPFS_2$"time_add_IPFS", na.rm=TRUE) / 1000, mean(CSVFrameCRDT_IPFS_2$"mean_time_retrieve", na.rm=TRUE) / 1000, mean(CSVFrameCRDT_IPFS_2$"mean_time_compute", na.rm=TRUE)  / 1000,
    		 mean(CSVFrameCRDT_IPFS_5$"mean_time_pubsub", na.rm=TRUE) / 1000 ,   mean(CSVFrameCRDT_IPFS_5$"time_add_IPFS", na.rm=TRUE) / 1000, mean(CSVFrameCRDT_IPFS_5$"mean_time_retrieve", na.rm=TRUE) / 1000, mean(CSVFrameCRDT_IPFS_5$"mean_time_compute", na.rm=TRUE)  / 1000,
    	   	 mean(CSVFrameCRDT_IPFS_10$"mean_time_pubsub", na.rm=TRUE)/ 1000 ,   mean(CSVFrameCRDT_IPFS_10$"time_add_IPFS", na.rm=TRUE)/ 1000, mean(CSVFrameCRDT_IPFS_10$"mean_time_retrieve", na.rm=TRUE)/ 1000, mean(CSVFrameCRDT_IPFS_10$"mean_time_compute", na.rm=TRUE) / 1000,
    		 mean(CSVFrameCRDT_IPFS_20$"mean_time_pubsub", na.rm=TRUE)/ 1000 ,   mean(CSVFrameCRDT_IPFS_20$"time_add_IPFS", na.rm=TRUE)/ 1000, mean(CSVFrameCRDT_IPFS_20$"mean_time_retrieve", na.rm=TRUE)/ 1000, mean(CSVFrameCRDT_IPFS_20$"mean_time_compute", na.rm=TRUE) / 1000  ) )
data <- data.frame(specie,condition,value)


print(data)





ggplot(data, aes(fill=condition, y=value, x=specie)) + 
    scale_fill_discrete(breaks= "" ) + #c("Add", "Pubsub", "Retrieve", "Compute")) +
    theme(text = element_text(size = 29), legend.position="bottom") +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.75, vjust = 0.5)) +
    scale_x_continuous(,breaks = seq(1, 5, 1), labels = c(1,2,5,10,20))+
    xlab("Number of peers updating")+
    ylab(expression(atop("mean time (micro seconds)",atop("logscale")))) +
#    scale_fill_discrete(labels = c("Add", "Pubsub", "Retrieve", "Compute")) +
    labs(fill = "") + 
    facet_wrap(~factor(condition, levels=c("Add", "Pubsub", "Retrieve", "Compute")), ncol = 4) +
    geom_bar( stat="identity") + 
    scale_y_log10(labels=function(n){format(n, scientific = FALSE,big.mark=",")}) 
#    coord_flip()




##############################- evolution of Compute time specifically -##############################


specieCompute <- c(rep(1 , 1) , rep(2 , 1) , rep(3 , 1) , rep(4 , 1), rep(5, 1) )
conditionCompute <- rep(c("mean_time_compute" ), 5)
valueCompute = abs(c(mean(CSVFrameCRDT_IPFS$"mean_time_compute") ,
    mean(CSVFrameCRDT_IPFS_2$"mean_time_compute"),
    mean(CSVFrameCRDT_IPFS_5$"mean_time_compute"),
    mean(CSVFrameCRDT_IPFS_10$"mean_time_compute"),
    mean(CSVFrameCRDT_IPFS_20$"mean_time_compute")))
dataCompute<- data.frame(specieCompute,conditionCompute,valueCompute)
# print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-Compute time values=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")

# print(dataCompute)


ggplot(dataCompute, aes(y=valueCompute / 1000, x=specieCompute)) + 
    theme(text = element_text(size = 30), legend.position="bottom") +
    scale_x_continuous(,breaks = seq(1, 5, 1), labels = c(1,2,5,10,20))+
    xlab("Number of peers updating")+
    ylab("Compute time (micro s)") +
    geom_line() +
    geom_point()





##############################- evolution of retrieve times -##############################


# colnames(data_IPFS_Alone)[which(names(df) == "mean_timeRetrieve")] <- "mean_time_retrieve"


data_IM_CRDT = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1)

data_IPFS_Alone = filter(data_Frame_IPFS_Alone, System == "IPFS Alone"  & numberPeerUpdating == 1)


data_IM_CRDT= data.frame(mean_time_retrieve=data_IM_CRDT$"mean_time_retrieve"/1000000, System=data_IM_CRDT$"System", numberPeers=data_IM_CRDT$"numberPeers", numUpdates=data_IM_CRDT$"numUpdates")

data_IPFS_Alone= data.frame(mean_time_retrieve=data_IPFS_Alone$"mean_timeRetrieve"/1000000, System=data_IPFS_Alone$"System", numberPeers=data_IPFS_Alone$"numberPeers", numUpdates=data_IPFS_Alone$"numUpdates")


data=rbind(data_IM_CRDT,data_IPFS_Alone)
data$numberPeers = as.character(data$numberPeers)


# print(data)
# grouped boxplot

wrap_names <- as_labeller(c('10'="10 updates", '100'="100 updates", '1000'="1000 updates"))

p <- data %>%
  mutate(numberPeers = fct_relevel(numberPeers, "2", "5", "10", "20", "50")) %>%
  ggplot( aes(x=numberPeers, y=mean_time_retrieve, fill=System)) +
    theme(text = element_text(size = 40), legend.position="bottom", legend.title=element_blank()) +
    geom_boxplot(outlier.shape = NA) +
    facet_wrap(~numUpdates, labeller=wrap_names) +
    xlab("Number of replicas")+
    ylab("Mean retrieve time (ms)") +
    scale_fill_discrete(labels = c("IM-CRDT", "IPFS")) +
    scale_y_continuous(limits = c(0,275)) 

#     geom_boxplot(outlier.shape = NA, fill=System) 

plot(p)




##############################- Size comparison between IM-CRDT and IPFS -##############################

data=rbind(sizes_IM_CRDT,sizes_IPFS_ALONE)

TOTAL_size_IM_CRDT=0 
TOTAL_size_IPFS=0 
mean_IM_CRDT=0
mean_IPFS=0

for (k in 1:nrow(sizes_IM_CRDT)) {
  TOTAL_size_IM_CRDT=TOTAL_size_IM_CRDT+sizes_IM_CRDT$"size"[k]
}

for (k in 1:nrow(sizes_IPFS_ALONE)) {
  if (sizes_IPFS_ALONE$"size"[k] > TOTAL_size_IPFS){
    TOTAL_size_IPFS=sizes_IPFS_ALONE$"size"[k]
  }
  mean_IPFS=mean_IPFS+sizes_IPFS_ALONE$"size"[k]
}
mean_IM_CRDT = TOTAL_size_IM_CRDT / nrow(sizes_IM_CRDT)
mean_IPFS=mean_IPFS / nrow(sizes_IPFS_ALONE)

TOTAL_size_IM_CRDT=TOTAL_size_IM_CRDT+1083988 # add initial size which isn't counted before so it doesn't impact the real mean size
                                              # Not needed for IPFS because sent sizes only grows, so it doesn't disapear


values=c(TOTAL_size_IM_CRDT,mean_IM_CRDT,TOTAL_size_IPFS,mean_IPFS)
type=c("Total Size","Update size","Total Size","Update size")
system=c("IM-CRDT","IM-CRDT","IPFS","IPFS")
data=data.frame(values,type,system)

# print(data)

p <- data %>%
  ggplot( aes(x=system, y=values, fill=system)) +
    theme(text = element_text(size = 20), legend.position="bottom") +
    geom_bar(stat="identity") +
    facet_wrap(~type) +
    xlab("System")+
    ylab("Size (byte) log scale") +
    # scale_fill_discrete(labels = c("IM-CRDT", "IPFS")) +
    scale_y_log10() 

plot(p)


# data_IM_CRDT = filter(data_Frame_IM_CRDT, System == "IM-CRDT"  & numberPeerUpdating == 1)

# data_IPFS_Alone = filter(data_Frame_IPFS_Alone, System == "IPFS Alone"  & numberPeerUpdating == 1)


# data_IM_CRDT= data.frame(maxlatency=data_IM_CRDT$"maxlatency", System=data_IM_CRDT$"System", numberPeers=data_IM_CRDT$"numberPeers", numUpdates=data_IM_CRDT$"numUpdates")

# data_IPFS_Alone= data.frame(maxlatency=data_IPFS_Alone$"maxlatency", System=data_IPFS_Alone$"System", numberPeers=data_IPFS_Alone$"numberPeers", numUpdates=data_IPFS_Alone$"numUpdates")


# p <- data_Frame_IM_CRDT %>%
#   mutate(numberPeerUpdating = fct_relevel(numberPeerUpdating, "1" , "2", "5", "10", "20")) %>%
#   ggplot( aes(x=numberPeerUpdating, y=maxlatency, fill=numberPeers)) +
#     geom_bar(position="dodge", stat="identity") +
#     facet_wrap(~numUpdates) +
#     scale_y_log10()


# plot(p)


##############################- Comparison between IM-CRDT and IPFS Alone -##############################





# create a dataset
# specie <- c(rep(1 , 4) , rep(2 , 4) , rep(3 , 4) , rep(4 , 4), rep(5, 4) )
# condition <- rep(c("mean_time_retrieve" , "mean_time_compute" , "time_add_IPFS", "mean_time_pubsub") , 5)
# value <- 
# abs(c(mean(CSVFrameCRDT_IPFS$"mean_time_retrieve") / 1000000,mean(CSVFrameCRDT_IPFS$"mean_time_compute") / 1000000,mean(CSVFrameCRDT_IPFS$"time_add_IPFS") / 1000000,mean(CSVFrameCRDT_IPFS$"mean_time_pubsub"),
# mean(CSVFrameCRDT_IPFS_2$"mean_time_retrieve") / 1000000,mean(CSVFrameCRDT_IPFS_2$"mean_time_compute") / 1000000,mean(CSVFrameCRDT_IPFS_2$"time_add_IPFS") / 1000000,mean(CSVFrameCRDT_IPFS_2$"mean_time_pubsub"),
# mean(CSVFrameCRDT_IPFS_5$"mean_time_retrieve") / 1000000,mean(CSVFrameCRDT_IPFS_5$"mean_time_compute") / 1000000,mean(CSVFrameCRDT_IPFS_5$"time_add_IPFS") / 1000000,mean(CSVFrameCRDT_IPFS_5$"mean_time_pubsub"),
# mean(CSVFrameCRDT_IPFS_10$"mean_time_retrieve") / 1000000,mean(CSVFrameCRDT_IPFS_10$"mean_time_compute" / 1000000),mean(CSVFrameCRDT_IPFS_10$"time_add_IPFS") / 1000000,mean(CSVFrameCRDT_IPFS_10$"mean_time_pubsub"),
# mean(CSVFrameCRDT_IPFS_20$"mean_time_retrieve") / 1000000,mean(CSVFrameCRDT_IPFS_20$"mean_time_compute" / 1000000),mean(CSVFrameCRDT_IPFS_20$"time_add_IPFS") / 1000000,mean(CSVFrameCRDT_IPFS_20$"mean_time_pubsub")))
# data <- data.frame(specie,condition,value)
 

# print(paste("mean_time_retrieve", mean(CSVFrameCRDT_IPFS_10$"mean_time_retrieve")))
# print(paste("mean_time_compute", mean(CSVFrameCRDT_IPFS_10$"mean_time_compute")))
# print(paste("time_add_IPFS", mean(CSVFrameCRDT_IPFS_10$"time_add_IPFS")))
# print(paste("mean_time_pubsub", mean(CSVFrameCRDT_IPFS_10$"mean_time_pubsub")))

# pdf("AnalyseCommunicationTime.pdf")
# ggplot(data, aes(fill=condition, y=value, x=specie)) + 
#     scale_x_continuous(,breaks = seq(1, 5, 1), labels = c(1,2,5,10,20))+
#     xlab("Number of peers updating")+
#     ylab("Percentage of time spend on the step") +
#     scale_fill_discrete(labels = c("Compute", "Pubsub", "Retrieve", "Add IPFS")) +
#     ggtitle("Comparison of communication and computation time \n in function of the number of updates") +
#     labs(fill = "Step") + 
#     geom_bar(position="fill", stat="identity")












