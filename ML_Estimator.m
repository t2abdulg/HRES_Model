function [out] = ML_Estimator(v)
% ============================================================
% GOAL: Estimation of Weibull Shape, Scale parameters 
% using Maximum Likelihood Method
% ============================================================
% INPUT:
% - wind velocity time series
% ============================================================
% OUTPUT:
% - array of Weibull shape and scale parameters
% ============================================================


% ============================================================
% Nomenclature:
% ============================================================
% Define shape factor coefficient k of Weibull Distribution as:
% k = (sum(i to n)[(vi^k*ln(vi)]/ sum(i to n)[vi^k] - (sum(i to
% n)[lnvi])/n)^-1
% Define scale factor coefficient c of Weibull Distribution as:
% c = 1/n sum(i to n)[vi^k]^(1/k)
% Let unit_1(i) = v(i)^k
% Let unit_2(i) = log(v(i))
% Let unit_3(i) = unit_1(i)*unit_2(i)
% Let num_1 = sum(unit_3);
% Let num_2 = sum(unit_2);
% Let denom_1 = sum(unit_1);
% k = ((num_1/denom_1) - (num_2/n))^(-1)
% c = (1/n)*(denom_1)^(1/k)
% ============================================================

% Remove zero velocity readings (to avoid infeasible solutions)
v(find(v==0)) = [];

% Initialise tolerance
error = 1;
% Initialise k = 2
k_guess = 2;
n_o = length(v);
% Allow error tolerance of 10^-5, converge iteratively unto k
while error > 0.00001
    for i = 1:n_o
        unit_1(i) = v(i)^k_guess;
        unit_2(i) = log(v(i));
        unit_3(i) = unit_1(i)*unit_2(i);
    end
    num_1 = sum(unit_3);
    num_2 = sum(unit_2);
    denom_1 = sum(unit_1);
    denom_2 = n_o;
    LHS = ((num_1/denom_1) - (num_2/denom_2))^(-1);
    RHS = k_guess;
    % Linearly adjust estimate of k
    k_new = k_guess + k_guess* ((LHS - RHS)/LHS/100);
	error = abs((k_guess - k_new)/k_guess);
    k_guess = k_new;
    
end 
k = k_guess;
c = ((1/n_o)*(denom_1))^(1/k);
out = [k,c];
end

