function [v_predict ] = Wind_MCS(shape_factor,scale_factor,hours)
%================================================================
% GOAL:
% This function will use a Monte Carlo Sampling technique to
% generate a new time series dataset based on the fitted Weibull
% Distribution
%================================================================
% for reproducibility

%Sample from Distribution
v_predict = wblrnd(scale_factor,shape_factor,hours,1);
% What a cute, compact function!! :D
end

