clc;
clear all;
%dependent version

%syms a b c;
a = 3;  %arrival
b = 5;  %service1
c = 3;  %service2

H1 = 1; %holding cost 1
H2 = 1; %holding cost 2
B1 = 10;  %lost cost 1
B2 = 10;  %lost cost 2

s1 = 50; %for this inputs, it is like infinite
s2 = 50; %for this inputs, it is like infinite

T1 = 3; %target inventory level1
T2 = 4; %target inventory level2

p = sym('p%d_%d', [s1+1 s2+1]);
x = sum(p(:)) == 1;
for i = 1:s1+1
    for j = 1:s2+1
        if j == 1 && i == s1+1
            %prompt = sprintf('%d, %d', i, j);
            %input(prompt);
            x(end+1) = p(i,j)*((i-1)*b) == p(i,j+1)*(j*c);
        elseif i == 1 && j == s2+1
            %prompt = sprintf('%d, %d', i, j);
            %input(prompt);
            x(end+1) = p(i,j)*((j-1)*c) == p(i+1,j)*(i*b);
        elseif i == 1 || j == 1
            %prompt = sprintf('%d, %d', i, j);
            %input(prompt);
            x(end+1) = p(i,j)*(a+(i-1)*b+(j-1)*c) ==  p(i,j+1)*((j)*c) + p(i+1,j)*((i)*b);
        elseif i == s1+1 && j == s2+1
            %prompt = sprintf('%d, %d', i, j);
            %input(prompt);
            x(end+1) = p(i,j)*((i-1)*b+(j-1)*c) == p(i-1,j-1)*(a);
        elseif i == s1+1
            %prompt = sprintf('%d, %d', i, j);
            %input(prompt);
            x(end+1) = p(i,j)*((i-1)*b+(j-1)*c) == p(i-1,j-1)*(a) + p(i,j+1)*((j)*c);
        elseif j == s2+1
            %prompt = sprintf('%d, %d', i, j);
            %input(prompt);
            x(end+1) = p(i,j)*((i-1)*b+(j-1)*c) == p(i-1,j-1)*(a) + p(i+1,j)*((i)*b);
        else
            %prompt = sprintf('%d, %d', i, j);
            %input(prompt);
            x(end+1) = p(i,j)*(a+(i-1)*b+(j-1)*c) == p(i-1,j-1)*(a) + p(i,j+1)*((j)*c) + p(i+1,j)*((i)*b);
        end
    end
end
[A,B] = equationsToMatrix(x(1:(s1+1)*(s2+1)+1), p(1:s1+1,1:s2+1));
X = linsolve(A,B);
X = double(reshape(X,s1+1,s2+1));
rowSum = sum(X,2);
colSum = sum(X,1);



expectedCost = 0;
for i = 1:s1
    for j = 1:s2
        if i < T1+2
           expectedCost = expectedCost + H1*(T1-(i-1))*X(i,j); 
        else
            expectedCost = expectedCost + B1*((i-1)-T1)*X(i,j); 
        end
        if j < T2+2
            expectedCost = expectedCost + H2*(T2-(j-1))*X(i,j);
        else
            expectedCost = expectedCost + B2*((j-1)-T2)*X(i,j); 
        end
        
    end
end
expectedCost


        