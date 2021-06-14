import math
from scipy.stats import poisson

arrival  = 3
service1 = 5
service2 = 5

#Costs
Inventory_cost1 = 1
Backorder_cost1 = 10
Backorder_cost2 = Backorder_cost1
Inventory_cost2 = Inventory_cost1

prob1 = 0
q1 = 1
prob2 = 0
q2 = 1

cost = 0;
#finding optimal q1
while 1: 
    prob1 = poisson.cdf(q1,arrival/service1) 
    if prob1 >= Backorder_cost1/(Backorder_cost1+Inventory_cost1):
        break    
    q1 += 1
    
#finding optimal q2
while 1: 
    prob2 = poisson.cdf(q2,arrival/service2) 
    if prob2 >= Backorder_cost2/(Backorder_cost2+Inventory_cost2):
        break    
    q2 += 1
print(prob1,Backorder_cost1/(Backorder_cost1+Inventory_cost1),prob2,Backorder_cost2/(Backorder_cost2+Inventory_cost2))
    
print("For System 1, optimal Q = ",q1, "& for system 2, optimal Q = ", q2)