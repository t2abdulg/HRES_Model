%% 1.0  Introduction

% H2OPTIMAL WIND ENERGY ANALYSIS
%==========================================================================
% Thouheed A.G., Khalil M., Shadman C., Frances O.
%==========================================================================

% Step 1: Fit Weibull Distribution to Wind Data

% Step 2: Fit Power Rating Curve for WES50

% Step 3: Evaluate Annual Energy Production for WES50
%==========================================================================
clear all
close all
clc

%% 2.0  Visualise Wind Speed Time Series (2013)

% Import & Visualise Wind Speed Data from Vineland Station
% Hourly data
v = xlsread('test_data'); 
% Monthly data
%{v_monthly = xlsread('MonthlyWndSpd_1981-2010'); %need to correct file

% Hourly & Monthly index variables (x-axis)
hr_index = 1:length(v);
%{m_index = 1:length(v_monthly);%}

% Apply correction factors for Turbine Hub Heights (evaluated at 30m)
V_30 = Altitude_Correction(v,30,3);

% Plot Uncorrected Wind Speed Time Series
figure
plot(hr_index,v,'-b','LineWidth',0.25)
% Figure Annotation
title('Vineland Station Hourly Wind Speed (2013)');
xlabel('Measurement Hourly Index');
ylabel('Wind speed [km/hr]');
axis([1,8785,0,70])

v(find(v==0)) = [];
V_30(find(V_30==0)) = [];
    
%% 3.0 Air Density Visualisation

% Import Air Density Data for 2013 at Vineland Station
dens = xlsread('air_dens_2012');
dens_ind = 1:length(dens);


% Compute Annual average,max,min air density
dens_avg = mean(dens);
dens_max = max(dens);
dens_min = min(dens);

% Calculate Seasonal Average Densities (Winter, Summer)
% Dec - Apr
wint_dens = cat(1,dens(1:2184),dens(7992:8760));
fprintf('\n Average Air Density in Winter [kg/m^3]: \n')
wint_dens_avg = mean(wint_dens);
% May - Sept
summer_dens = dens(2905:5857);
fprintf('\n Average Air Density in Summer [kg/m^3]: \n')
sum_dens_avg = mean(summer_dens)
% X-Axis, Index variable
season_ind = 1:length(wint_dens);
% Plot Hourly Air Density
figure
plot(dens_ind, dens,'k');
% Figure Annotation
title('Vineland Station Hourly Air Density (2013)');
xlabel('Measurement Hourly Index');
ylabel('Density [kg/m^3]');

% Plot Seasonal Influence on Air Density
figure
plot(season_ind,wint_dens,'-c',season_ind,summer_dens,'-g')
% Figure Annotation
legend('Winter','Summer')
title('Seasonal Influence on Hourly Air Density (2013)'); %title year?
xlabel('Measurement Hours')
ylabel('Air Density (kg/m^3)')

% % Determine Weibull Parameters for corrected velocities at 30m
% fprintf('\n Weibull Parameters at Hub Height of 30m (k,c): \n')
p_30 = ML_Estimator(V_30);

% % Plotting velocity - 500 equally spaced velocities 0 - 100 km/hr
 v_plot = linspace(0,100,1000);


% MATLAB BUILT-IN FUNCTION WEIBULL FIT (STATISTICAL TOOLBOX)
% ============================================================
PD = fitdist(v,'Weibull');
PD_30 = fitdist(V_30,'Weibull')

y = pdf(PD,v_plot);
y_30 = pdf(PD_30,v_plot);


% Visualise effect of Hub Height on Weibull Fit
% ============================================================
figure
hold on
plot(v_plot,y,'k',v_plot,y_30,'--r','LineWidth',2);
legend('Uncorrected Wind','30m Hub Height')
% Annotate Figure
title('Effect of Turbine Hub Height on Weibull PDF');
xlabel('Wind Velocity (km/hr)');
ylabel('f(V)');
hold off

%% 5.0  Manufacturer Turbine Power Rating

% SMALL TURBINES
% ==============

% Wind Energy Solutions 50 kW Turbine Specs
% Evaluate at 24,30 m hub heights
ZEC75_Power = Power_Rating(10.8,90,27,75);
ZEC75_SweptArea = 380;    %m^2
ZEC75_NamePlate = 75;     %kW

size(ZEC75_Power)
size(v_plot)
% Plot small Turbine Rating Curve (10 - 100kW)
figure
plot(v_plot,ZEC75_Power ,'--b','LineWidth',1.5)
legend('ZEC-75kW')
axis([0,100,0,100]);

% Annotate Figure
title('Small (75kW) Wind Turbine Power Rating Curves');
xlabel('Wind Velocity (km/hr)');
ylabel('Power (kW)');
hold off


%% 6.0 Annual Energy Production

% Sample 100 linearly-spaced densities between max and min observations
Dens_sample = linspace(dens_min,dens_max);
% Sample 100 linearly-spaced velocities between max and min observations
Wind_Range = linspace(10,90);


% Calls Annual Energy Production Function 
fprintf('\n Annual Energy Production of ZEC-75kW Turbine (MWh): \n')
Annual_Energy_ZEC75 = AEP(Dens_sample,v_plot,Wind_Range,ZEC75_Power,y_30)
disp(Annual_Energy_ZEC75)

% Estimate Capacity Factor

fprintf('\n Capacity factor of ZEC-75kW Turbine: \n')
Cp_ZEC75 = Annual_Energy_ZEC75/((ZEC75_NamePlate*8466)*10^(-3));
disp(Cp_ZEC75)

%% 7.0 Time Series Energy Production

% Call Function to produce Hourly Energy Time Series (HETS) Arrays 
 Time_Series = 1:1:168;
 
 HETS_ZEC75 = Energy_TimeSeries(p_30(1),p_30(2),dens,ZEC75_SweptArea,Cp_ZEC75,v_plot,ZEC75_Power);
sum(HETS_ZEC75)/1000


% Write Hourly Energy Production Time Series Data to CSV 
filename='HETS_ZEC75.csv';
csvwrite(filename,HETS_ZEC75')

% Plot HETS 
figure

bar(Time_Series,HETS_ZEC75,'g')
legend('ZEC-75Kw Turbine')
% Annotate Figure
title('Energy Production Hourly Time Series');
axis([0,168,0,100])
xlabel('Time(hours)');
ylabel('Estimated Energy (kWh)');
