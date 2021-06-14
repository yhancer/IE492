clc;
clear all;
%dependent version

%syms a b c;
a =3;  %arrival
b = 5;  %service1
c = 3;  %service2

H1 = 1; %holding cost 1
H2 = 1; %holding cost 2
L1 = 10;  %lost cost 1
L2 = 10;  %lost cost 2

N1 = 15; %server arama sınırı1
N2 = 15; %server arama sınırı2
Costs_generic = zeros(N1,N2);



for s1 = 1:N1
    for s2 = 1:N2
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
        %for system1 holding
        for i = 1:s1
            expectedCost = expectedCost +H1*(s1-(i-1))*rowSum(i);
        end
        %for the losts from system1
        expectedCost = expectedCost + (L1+L2)*(a*rowSum(s1+1));
        %for system2 holding
        for j = 1:s2
            expectedCost = expectedCost + H2*(s2-(j-1))*colSum(j);
        end
        %for the losts from system2
        expectedCost = expectedCost + (L1+L2)*(a*colSum(s2+1));
        expectedCost = expectedCost - (L1+L2)*a*X(s1+1,s2+1);
        Costs_generic(s1,s2) = expectedCost;
    end
end

Costs_generic
for i = 1:N1
    for j = 1:N2
        if Costs_generic(i,j) == min(Costs_generic,[],'all')
            sprintf("Target for system1 = %d and target for system2 = %d yield a minimum cost of %g for Dependent Version", i, j, Costs_generic(i,j))
        end
    end
end