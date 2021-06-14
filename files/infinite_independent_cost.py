import math
from scipy.stats import poisson

arrival  = 3
service1 = 5
service2 = 3

#Costs
Backorder_cost1 = 10
Inventory_cost1 = 1
Backorder_cost2 = 10
Inventory_cost2 = 1
prob1 = 0
q1 = 1
prob2 = 0
q2 = 1

w, h = 20, 20;
cost_s1 = [0 for x in range(w)]
cost_s2 = [0 for x in range(h)]
cost_s1_s2 = [[math.inf for x in range(w)] for y in range(h)]
control1 = 1
control2 = 1
#finding optimal q1
while 1:
    cost = 0;
    for i in range(0,q1+1,1):
        cost = cost + poisson.pmf(i,arrival/service1)*Inventory_cost1*(q1-i)
    #finding backlog cost for q1
    k = q1+1;
    while poisson.pmf(k,arrival/service1)*(k-q1)*Backorder_cost1 > 0.0000000001:
        cost = cost + poisson.pmf(k,arrival/service1)*Backorder_cost1*(k-q1)
        k += 1
    cost_s1[q1] = cost
    if q1 >= w-1:
        break  
    q1 += 1
#finding optimal q2
while 1: 
    cost = 0;
    for j in range(0,q2+1,1):
        cost = cost + poisson.pmf(j,arrival/service2)*Inventory_cost2*(q2-j)
    l = q2+1;
    while poisson.pmf(l,arrival/service2)*(l-q2)*Backorder_cost2 > 0.0000000001:
        cost = cost + poisson.pmf(l,arrival/service2)*Backorder_cost2*(l-q2)
        l += 1
    cost_s2[q2] = cost
    if q2 >= h-1:
        break    
    q2 += 1

for i in range(1,q1+1,1):
    for j in range(1,q2+1,1):
        cost_s1_s2[i][j] = cost_s1[i] + cost_s2[j]
        if(cost_s1_s2[i][j] == min(min(cost_s1_s2))):
            min_index_q1 = i
            min_index_q2 = j

print("For System 1, optimal Q = ",min_index_q1, "& for system 2, optimal Q = ", min_index_q2, "with the Cost of", min(min(cost_s1_s2)))
import pandas as pd
df_cost_s1_s2= pd.DataFrame(cost_s1_s2)
display(df_cost_s1_s2)
