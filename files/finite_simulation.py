from scipy.stats import t
import numpy as np
import math
import pandas as pd

#parameters
arrival  = 3
service1 = 1
service2 = 1

#Costs
Loss_cost1 = 10
Inventory_cost1 = 1
Loss_cost2 = 10
Inventory_cost2 = 1

#from independent approximation
s1_lowerlimit = 1
s2_lowerlimit = 1

how_many_arrivals_discarded = 700
how_many_arrivals_counted   = 80000


#simulation warmup and duration
exclusion = arrival * how_many_arrivals_discarded
siml_duration = arrival * how_many_arrivals_counted + exclusion


def server_total_counter(clock , clock_bgn , server, server_total):
    time_elapsed = clock - clock_bgn
    server_total+= time_elapsed*server
    return server_total

def steady_state_counter(steady_state_prob_matrix, clock, clock_bgn, server1,server2):   
    steady_state_prob_matrix[server1][server2] += clock - clock_bgn
    return steady_state_prob_matrix

def inventory_cost_addition(inventory_cost,Inv_cost, clock, clock_bgn, server, num_ser):
    time_elapsed = clock - clock_bgn
    inventory_cost+= Inv_cost * time_elapsed * (num_ser - server)
    return inventory_cost

# cost matrix is created with width and length equal to 25
w, h = 25, 25;
cost_matrix = [[math.inf for x in range(w)] for y in range(h)]

for i in range(s1_lowerlimit,100,1):
    for j in range(s2_lowerlimit,100,1):
        #number of servers
        num_ser1 = i
        num_ser2 = j        
        
        #statistics
        inventory1_cost = 0
        inventory2_cost = 0
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

        while clock < siml_duration:
            clock_bgn = clock 
            #event creation
            next_arrival = np.random.exponential(1/arrival)
            if server1:        
                next_departure1 = np.random.exponential(1/(service1*server1))
            else:
                next_departure1 = math.inf

            if server2:        
                next_departure2 = np.random.exponential(1/(service2*server2))
            else:
                next_departure2 = math.inf

            #event determination       
            if next_arrival < next_departure1 and next_arrival < next_departure2:
                #checking whether customer will enter the system or will be lost
                if server1<num_ser1 and server2<num_ser2:
                    clock+=next_arrival
                    if(clock>exclusion):
                        server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                        server2_total = server_total_counter(clock , clock_bgn , server2, server2_total)
                        inventory1_cost = inventory_cost_addition(inventory1_cost, Inventory_cost1, clock, clock_bgn, server1, num_ser1)
                        inventory2_cost = inventory_cost_addition(inventory2_cost, Inventory_cost2, clock, clock_bgn, server2, num_ser2)
                        total_arrivals+=1               
                    server1+=1
                    server2+=1

                elif server1 == num_ser1 and server2<num_ser2:
                    if(clock>exclusion):
                        loss_s1 +=1
                    clock+=next_arrival
                    if(clock>exclusion):
                        server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                        server2_total = server_total_counter(clock , clock_bgn , server2, server2_total)
                        inventory1_cost = inventory_cost_addition(inventory1_cost, Inventory_cost1, clock, clock_bgn, server1, num_ser1)
                        inventory2_cost = inventory_cost_addition(inventory2_cost, Inventory_cost2, clock, clock_bgn, server2, num_ser2)
                    #server2+=1  in order to make it partial order service model
                elif server1 < num_ser1 and server2 == num_ser2:
                    if(clock>exclusion):
                        loss_s2 +=1
                    clock+=next_arrival
                    if(clock>exclusion):
                        server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                        server2_total = server_total_counter(clock , clock_bgn , server2, server2_total) 
                        inventory1_cost = inventory_cost_addition(inventory1_cost, Inventory_cost1, clock, clock_bgn, server1, num_ser1)
                        inventory2_cost = inventory_cost_addition(inventory2_cost, Inventory_cost2, clock, clock_bgn, server2, num_ser2)
                    #server1+=1  in order to make it partial order service model
                else:
                    clock+=next_arrival
                    if(clock>exclusion):
                        server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                        server2_total = server_total_counter(clock , clock_bgn , server2, server2_total) 
                        inventory1_cost = inventory_cost_addition(inventory1_cost, Inventory_cost1, clock, clock_bgn, server1, num_ser1)
                        inventory2_cost = inventory_cost_addition(inventory2_cost, Inventory_cost2, clock, clock_bgn, server2, num_ser2)
                        loss_both += 1

            elif next_departure1 < next_departure2 and next_departure1 < next_arrival:
                clock+=next_departure1
                if(clock>exclusion):
                    server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                    server2_total = server_total_counter(clock , clock_bgn , server2, server2_total)
                    inventory1_cost = inventory_cost_addition(inventory1_cost, Inventory_cost1, clock, clock_bgn, server1, num_ser1)
                    inventory2_cost = inventory_cost_addition(inventory2_cost, Inventory_cost2, clock, clock_bgn, server2, num_ser2)
                    total_dep1+= 1
                server1-=1

            else:
                clock+=next_departure2
                if(clock>exclusion):
                    server1_total = server_total_counter(clock , clock_bgn , server1 , server1_total)
                    server2_total = server_total_counter(clock , clock_bgn , server2, server2_total)
                    inventory1_cost = inventory_cost_addition(inventory1_cost, Inventory_cost1, clock, clock_bgn, server1, num_ser1)
                    inventory2_cost = inventory_cost_addition(inventory2_cost, Inventory_cost2, clock, clock_bgn, server2, num_ser2)
                    total_dep2+= 1
                server2-=1   

        total_loss_cost = (loss_s1 + loss_s2 + loss_both) * (Loss_cost1 + Loss_cost2)
        total_cost = inventory1_cost + inventory2_cost + total_loss_cost
        cost_matrix[num_ser1][num_ser2] = total_cost/(siml_duration-exclusion)
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
    