clc;
clear all;

syms a b c;
a = 5;
b = 3;
c = 1;
syms s1 s2;
s1 = 7;
s2 = 11;
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
X = reshape(X,s1+1,s2+1);
S1avg = 0;
S2avg = 0;
for i = 1:s1+1
    for j = 1:s2+1
        S1avg = S1avg + X(i,j)*(i-1);
        S2avg = S2avg + X(i,j)*(j-1);
    end
end
sprintf('p00 = %g',vpa(X(1,1)))
sprintf('p01 = %g',vpa(X(1,2)))
sprintf('p10 = %g',vpa(X(2,1)))
sprintf('p11 = %g',vpa(X(2,2)))
sprintf('Average entity in System1 = %g',double(S1avg))
sprintf('Average entity in System2 = %g',double(S2avg))
