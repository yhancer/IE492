from scipy.stats import t
import numpy as np
import math
import pandas as pd

arrival  = 3
service1 = 5
service2 = 3

#Costs
Backorder_cost1 = 10
Inventory_cost1 = 1
Backorder_cost2 = 10
Inventory_cost2 = 1

onhand_fraction1 = 0
onhand_fraction2 = 0

how_many_arrivals_discarded = 700
how_many_arrivals_counted   = 80000

#from independent approximation
s1_lowerlimit = 1
s2_lowerlimit = 1

#number of servers
num_ser1 = math.inf
num_ser2 = math.inf


#simulation warmup and duration
exclusion = arrival * how_many_arrivals_discarded
siml_duration = arrival * how_many_arrivals_counted + exclusion

def server_total_counter(clock , clock_bgn , server, server_total):
    time_elapsed = clock - clock_bgn
    server_total+= time_elapsed*server
    return server_total

def onhand_time_calculation(clock, clock_bgn, server,onhand_fraction,q):
    if(server<=q):
        time_elapsed = clock - clock_bgn
        onhand_fraction+= time_elapsed
    return onhand_fraction

def instant_cost_calculator(clock, clock_bgn, server1, server2, target1, target2):
    #parameter "is_arrival" comes TRUE only when it is called from an arrival instance
    time_elapsed = clock - clock_bgn
    cost_inv1, cost_inv2, cost_backorder1, cost_backorder2 = 0,0,0,0;
    #inventory is calculated by time-wise
    if target1 > server1:
        cost_inv1 = time_elapsed * (target1 - server1) * Inventory_cost1      
    if target2 > server2:
        cost_inv2 = time_elapsed * (target2 - server2) * Inventory_cost2 
    #backorder is calculated by time-wise
    if server1 > target1:
        cost_backorder1 = time_elapsed * (server1 - target1) * Backorder_cost1        
    if server2 > target2:
        cost_backorder2 = time_elapsed * (server2 - target2) * Backorder_cost2  
    
    cost_total = cost_inv1 + cost_inv2 + cost_backorder1 + cost_backorder2
    return cost_total

# cost matrix is created with width and length equal to 25
w, h = 25, 25;
cost_matrix = [[math.inf for x in range(w)] for y in range(h)] 

for i in range(s1_lowerlimit,100,1):            
    for j in range(s2_lowerlimit,100,1): 
        #statistics
        server1_total = 0
        server2_total = 0
        total_arrivals = 0
        total_dep1 = 0
        total_dep2 = 0

        #initial states
        server1 = 0
        server2 = 0
        clock = 0
        cost = 0

        while clock < siml_duration:
            clock_bgn = clock 
            #event creation
            next_arrival = np.random.exponential(1/arrival)
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
                clock+=next_arrival
                if(clock>exclusion):
                    total_arrivals+=1
                    server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                    server2_total = server_total_counter(clock , clock_bgn , server2, server2_total)
                    onhand_fraction1= onhand_time_calculation(clock, clock_bgn,server1,onhand_fraction1,i)
                    onhand_fraction2= onhand_time_calculation(clock, clock_bgn,server2,onhand_fraction2,j)
                    cost = cost + instant_cost_calculator(clock, clock_bgn, server1, server2, i, j)
                server1+=1
                server2+=1

            elif next_departure1 < next_departure2 and next_departure1 < next_arrival:
                clock+=next_departure1
                if(clock>exclusion):
                    total_dep1+= 1
                    server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                    server2_total = server_total_counter(clock , clock_bgn , server2, server2_total)
                    onhand_fraction1= onhand_time_calculation(clock, clock_bgn,server1,onhand_fraction1,i)
                    onhand_fraction2= onhand_time_calculation(clock, clock_bgn,server2,onhand_fraction2,j)
                    cost = cost + instant_cost_calculator(clock, clock_bgn, server1, server2, i, j)
                server1-=1

            else:
                clock+=next_departure2
                if(clock>exclusion):
                    total_dep2+= 1
                    server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                    server2_total = server_total_counter(clock , clock_bgn , server2, server2_total)
                    onhand_fraction1= onhand_time_calculation(clock, clock_bgn,server1,onhand_fraction1,i)
                    onhand_fraction2= onhand_time_calculation(clock, clock_bgn,server2,onhand_fraction2,j)
                    cost = cost + instant_cost_calculator(clock, clock_bgn, server1, server2, i, j)
                server2-=1
        onhand_fraction1 = onhand_fraction1/(siml_duration-exclusion)
        onhand_fraction2 = onhand_fraction2/(siml_duration-exclusion)
        cost_matrix[i][j] = round(cost/(siml_duration - exclusion), ndigits =5)
        min_cost = min(min(cost_matrix))
        if onhand_fraction1 >= Backorder_cost1/(Backorder_cost1+Inventory_cost1) and onhand_fraction2 >= Backorder_cost2/(Backorder_cost2+Inventory_cost2):
            print("Backorder/(Backorder+Inventory Holding Cost Formula is satisfied at ",i,j)
        #convexity by row
        if cost_matrix[i][j-1] < cost_matrix[i][j]:
            break
    #convexity by column
    if i != 1 and min(cost_matrix[i]) > min(cost_matrix[i-1]):
        break

for i in range(1,w,1):
    for j in range(1,h,1):
        if(cost_matrix[i][j] == min([min(element) for element in cost_matrix])):
            min_index_q1 = i
            min_index_q2 = j
print("For System 1, optimal Q = ",min_index_q1, "& for system 2, optimal Q = ", min_index_q2, "with the Cost of", min([min(element) for element in cost_matrix]))
df_cost= pd.DataFrame(cost_matrix)
display(df_cost)
