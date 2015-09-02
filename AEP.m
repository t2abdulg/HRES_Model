function [ AEP_out ] = AEP( Dens_sample,plot_vel,oper_vel,power_curve,wind_PDF)
% =========================================================================
% Goal: Function to evaluate Annual Energy Production for any turbine power
% rating
% =========================================================================
% Inputs: 
% Wind Speed Probability Distribution, Power Rating Curve,
% Operating Velocity Range, Plotting Velocities for Interpolation
% =========================================================================
% Output: 
% AEP
% =========================================================================

% Plotting x axis velocity (high resolution velocity values)
v_plot = plot_vel;
% Range of velocities to evaluate system
Wind_Range = oper_vel;
% Specify conservative efficiency of system 
effic = 0.95;
% Initialise arrays
P_v = zeros(1,length(Wind_Range));
F_v = zeros(1,length(Wind_Range));
Energy_Curve = zeros(1,length(Wind_Range));

% Iterate through operational velocities
for i=1:length(Wind_Range)
    % Interpolate Power value from Manufacturer Power Rating curve
    P_v(i) = interp1(v_plot, power_curve,Wind_Range(i));
    % Interpolate Prob. of occurence from PDF (of operational velocity)
    F_v(i) = interp1(v_plot,wind_PDF,Wind_Range(i));
    % Evaluate Energy = Turbine Power Rating(@velocity) * (Frequency of
    % velocity in year)*(Normalised Air Density)*Efficiency of System
    Energy_curve(i) = (P_v(i))*(F_v(i)*8760)*(Dens_sample(i)/1.225)*effic;
end

% Estimate Annual Energy Production (MWh)
% (Area under Energy Curve)
AEP_out = sum(Energy_curve)*10^(-3);


end

