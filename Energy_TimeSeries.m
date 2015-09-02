function [ ETS ] = Energy_TimeSeries( k,c,dens,SweptArea, Cp,v_plot,power_curve )

% =========================================================================
% Goal: Function to generate Time Series array for Hourly Energy production 
% of a given turbine 
% =========================================================================
% Wind Speed (Weibull) Parameters: k,c
% Density 
% Turbine Specifications: Swept Area, Capacity Factor
% Output:
% Energy production hourly time series
% =========================================================================
 
 % Monte Carlo Sampling of wind velocities from Weibull Distn
 Wind_Sim = Wind_MCS(k,c,168);
 % Initialise Hourly Energy Time Series
 ETS = zeros(1,length(Wind_Sim));
% Specify conservative efficiency of system 
effic = 0.95;

 for i=1:length(Wind_Sim)
    % Interpolate Power value from Manufacturer Power Rating curve
    P_v(i) = interp1(v_plot, power_curve,Wind_Sim(i));
    % Evaluate Energy = Turbine Power Rating(@velocity)*Efficiency of System
    ETS(i) = (P_v(i))*effic;
 end
 
end

