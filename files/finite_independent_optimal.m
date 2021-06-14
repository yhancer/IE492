clc;

syms a b c;
a =3;  %arrival
b = 5;  %service1
c = 3;  %service2

N1 = 13; %server arama sınırı1
N2 = 13; %server arama sınırı2
Costs_independent = zeros(N1,N2);

H1 = 1; %holding cost 1
H2 = 1; %holding cost 2
L1 = 10;  %lost cost 1
L2 = 10;  %lost cost 2

for s1 = 1:N1
    for s2 = 1:N2
        S1 = sym('S1_', [s1+1 1]);
        S2 = sym('S2_', [s2+1 1]);
        p = sym('p%d_%d', [s1+1 s2+1]);

        x = sum(S1(:)) == 1;
        y = sum(S2(:)) == 1;
        for i = 1:s1+1
            if i == 1
                %prompt = sprintf('%d',i);
                %input(prompt);
                x(end+1) = S1(i)*a == S1(i+1)*i*b;
            elseif i == s1+1
                %prompt = sprintf('%d',i);
                %input(prompt);
                x(end+1) = S1(i)*(i-1)*b == S1(i-1)*a;
            else
                %prompt = sprintf('%d',i);
                %input(prompt);
                x(end+1) = S1(i)*(a+(i-1)*b) == S1(i-1)*a + S1(i+1)*i*b;
            end
        end

        for j = 1:s2+1
            if j == 1
                %prompt = sprintf('%d',j);
                %input(prompt);
                y(end+1) = S2(j)*a == S2(j+1)*j*c;
            elseif j == s2+1
                %prompt = sprintf('%d',j);
                %input(prompt);
                y(end+1) = S2(j)*(j-1)*c == S2(j-1)*a;
            else
                %prompt = sprintf('%d',j);
                %input(prompt);
                y(end+1) = S2(j)*(a+(j-1)*c) == S2(j-1)*a + S2(j+1)*j*c;
            end
        end
        [A,B] = equationsToMatrix(x(1:s1+1),S1(1:s1+1));
        X = simplify(linsolve(A,B));

        [C,D] = equationsToMatrix(y(1:s2+1),S2(1:s2+1));
        Y = simplify(linsolve(C,D));

   
        expectedCost = 0;
        %for system1 holding
        for i = 1:s1
            expectedCost = expectedCost +H1*(s1-(i-1))*X(i);
        end
        %for the losts from system1
        expectedCost = expectedCost + L1*(a*X(s1+1));
        %for system2 holding
        for j = 1:s2
            expectedCost = expectedCost +H2*(s2-(j-1))*Y(j);
        end
        %for the losts from system2
        expectedCost = expectedCost + L2*(a*Y(s2+1));
        Costs_independent(s1,s2) = expectedCost;
    end
end

Costs_independent
for i = 1:N1
    for j = 1:N2
        if Costs_independent(i,j) == min(Costs_independent,[],'all')
            sprintf("Target for system1 = %d and target for system2 = %d yield a minimum cost of %g", i, j, Costs_independent(i,j))
        end
    end
end
