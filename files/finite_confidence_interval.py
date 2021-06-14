from scipy.stats import t
import numpy as np
import math
#parameters
arrival  = 5
service1 = 3
service2 = 1
onhand_fraction1=0
onhand_fraction2=0

#number of servers
num_ser1 = math.inf
num_ser2 = math.inf

#Costs
Backorder_cost1 = 10
Inventory_cost1 = 3
Backorder_cost2 = 10
Inventory_cost2 = 3

def server1_total_counter(clock , clock_bgn , server1, server1_total):
    time_elapsed = clock - clock_bgn
    server1_total+= time_elapsed*server1
    return server1_total

def server2_total_counter(clock , clock_bgn , server2, server2_total):
    time_elapsed = clock - clock_bgn
    server2_total+= time_elapsed*server2
    return server2_total

def onhand_time_calculation1(clock, clock_bgn, server1,onhand_fraction1,q1):
    if(server1<=q1):
        time_elapsed = clock - clock_bgn
        onhand_fraction1+= time_elapsed
    return onhand_fraction1

def onhand_time_calculation2(clock, clock_bgn, server2,onhand_fraction2,q2):
    if(server2<=q2):
        time_elapsed = clock - clock_bgn
        onhand_fraction2+= time_elapsed   
    return onhand_fraction2
#infinite
numberoftrials = 100
checkifsimulated = np.zeros((numberoftrials,numberoftrials),dtype=int)
for k in range(1,numberoftrials+1,1):   
    for i in range(1,k+1,1):            
        for j in range(1,k+1,1):
            # i represents target level for system 1 & j represents target level for system 2
            if checkifsimulated[i-1][j-1] == 0:  ## [i][j]leri [i-1][j-1] şeklinde değiştirdim 
                checkifsimulated[i-1][j-1] = 1
                #statistics
                server1_total = 0
                server2_total = 0
                total_arrivals = 0
                total_dep1 = 0
                total_dep2 = 0
                loss_s1 = 0     #number of arrivals that cannot enter system due to server 1
                loss_s2 = 0 
                loss_both = 0
                #initial states
                server1 = 0
                server2 = 0
                clock = 0
                #simulation warmup and duration
                exclusion=arrival*20
                siml_duration = 10000+exclusion
 
                while clock < siml_duration:
                    clock_bgn = clock 
                    #event creation
                    next_arrival    = np.random.exponential(1/arrival)
                    if server1:        
                        next_departure1 = np.random.exponential(1/(service1*server1))
                    else:
                        next_departure1=math.inf

                    if server2:        
                        next_departure2 = np.random.exponential(1/(service2*server2))
                    else:
                        next_departure2=math.inf

                    #event determination       
                    if next_arrival < next_departure1 and next_arrival < next_departure2:
                        #checking whether customer will enter the system or will be lost
                        if server1<num_ser1 and server2<num_ser2:
                            clock+=next_arrival
                            if(clock>exclusion):
                                server1_total = server1_total_counter(clock , clock_bgn , server1 , server1_total)
                                server2_total = server2_total_counter(clock , clock_bgn , server2, server2_total)
                                total_arrivals+=1
                                onhand_fraction1= onhand_time_calculation1(clock, clock_bgn,server1,onhand_fraction1,i)
                                onhand_fraction2= onhand_time_calculation2(clock, clock_bgn,server2,onhand_fraction2,j)
                                                      
                            server1+=1
                            server2+=1

                        elif server1 == num_ser1 and server2<num_ser2:
                            if(clock>exclusion):
                                loss_s1 +=1
                            clock+=next_arrival
                            if(clock>exclusion):
                                server1_total = server1_total_counter(clock , clock_bgn , server1 , server1_total)
                                server2_total = server2_total_counter(clock , clock_bgn , server2, server2_total)
                                onhand_fraction1= onhand_time_calculation1(clock, clock_bgn,server1,onhand_fraction1,i)
                                onhand_fraction2= onhand_time_calculation2(clock, clock_bgn,server2,onhand_fraction2,j)   
                            #server2+=1  partial olması için
                        elif server1 < num_ser1 and server2 == num_ser2:
                            if(clock>exclusion):
                                loss_s2 +=1
                            clock+=next_arrival
                            if(clock>exclusion):
                                server1_total = server1_total_counter(clock , clock_bgn , server1 , server1_total)
                                server2_total = server2_total_counter(clock , clock_bgn , server2, server2_total) 
                                onhand_fraction1= onhand_time_calculation1(clock, clock_bgn,server1,onhand_fraction1,i)
                                onhand_fraction2= onhand_time_calculation2(clock, clock_bgn,server2,onhand_fraction2,j)   
                            #server1+=1  partial olması için
                        else:
                            clock+=next_arrival
                            if(clock>exclusion):
                                server1_total = server1_total_counter(clock , clock_bgn , server1 , server1_total)
                                server2_total = server2_total_counter(clock , clock_bgn , server2, server2_total) 
                                loss_both += 1
                                onhand_fraction1= onhand_time_calculation1(clock, clock_bgn,server1,onhand_fraction1,i)
                                onhand_fraction2= onhand_time_calculation2(clock, clock_bgn,server2,onhand_fraction2,j)   



                    elif next_departure1 < next_departure2 and next_departure1 < next_arrival:
                        clock+=next_departure1
                        if(clock>exclusion):
                            server1_total = server1_total_counter(clock , clock_bgn , server1 , server1_total)
                            server2_total = server2_total_counter(clock , clock_bgn , server2, server2_total)
                            total_dep1+= 1
                            onhand_fraction1= onhand_time_calculation1(clock, clock_bgn,server1,onhand_fraction1,i)
                            onhand_fraction2= onhand_time_calculation2(clock, clock_bgn,server2,onhand_fraction2,j)
                        server1-=1

                    else:
                        clock+=next_departure2
                        if(clock>exclusion):
                            server1_total = server1_total_counter(clock , clock_bgn , server1 , server1_total)
                            server2_total = server2_total_counter(clock , clock_bgn , server2, server2_total)
                            total_dep2+= 1
                            onhand_fraction1= onhand_time_calculation1(clock, clock_bgn,server1,onhand_fraction1,i)
                            onhand_fraction2= onhand_time_calculation2(clock, clock_bgn,server2,onhand_fraction2,j)
                        server2-=1
                #while satırı
                onhand_fraction1 = onhand_fraction1/(siml_duration-exclusion)
                onhand_fraction2 = onhand_fraction2/(siml_duration-exclusion)
                if onhand_fraction1 >= Backorder_cost1/(Backorder_cost1+Inventory_cost1) and onhand_fraction2 >= Backorder_cost2/(Backorder_cost2+Inventory_cost2):
                    print(onhand_fraction1,onhand_fraction2,i,j)
                    break
            if onhand_fraction1 >= Backorder_cost1/(Backorder_cost1+Inventory_cost1) and onhand_fraction2 >= Backorder_cost2/(Backorder_cost2+Inventory_cost2):
                break    
        if onhand_fraction1 >= Backorder_cost1/(Backorder_cost1+Inventory_cost1) and onhand_fraction2 >= Backorder_cost2/(Backorder_cost2+Inventory_cost2):
            break       
    if onhand_fraction1 >= Backorder_cost1/(Backorder_cost1+Inventory_cost1) and onhand_fraction2 >= Backorder_cost2/(Backorder_cost2+Inventory_cost2):
        break 
print(checkifsimulated)
