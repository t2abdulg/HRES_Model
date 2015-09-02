% H2OPTIMAL NET METERING ENERGY ANALYSIS
%==========================================================================
% Thouheed A.G., Khalil M.,Shadman C., Frances 
%==========================================================================
clear all
close all
clc
%==========================================================================
% GOAL: Script used to conduct net metering energy analysis of hybrid
% microgrid system
%==========================================================================
% KEY STEPS:
% Import all relevant datasets (Wind, FC energy production, EPANET outputs)
% Import hydraulic demand load
% Import results from Microgrid energy balance analysis
% Compute net price at each hour
% Evaluate annual net savings
%==========================================================================
% Set simulation period 
sim_period = 8760;
% Read Input datafiles
wind = csvread('wind_8760.csv');
dem = csvread('dem_8760.csv');
% Import Energy flows
energy_balance = Microgrid_Analysis(sim_period,wind,dem);

% Import Ontario Energy Board Annual Pricing Schedule - cost of pump at
% every hour of simulation
OEB_price_sched = csvread('Pump_cost.csv');

switch sim_period 
    case 24
        OEB_price_sched = OEB_price_sched(49:73);
    case 168
        OEB_price_sched = OEB_price_sched(1:168);
end

% Ontario FIT Pricing is fixed during simulation period
fit_price = 0.13;

% ===============================================
% Initialise costing arrays for simulation period
% ===============================================
% Array for base grid-connected system cost: 
exist_dem = zeros(sim_period,1);
% Array for net energy demand of hybrid system:
net_dem = zeros(sim_period,1);
% Array for net-metering cost of hybrid system:
net_cost = zeros(sim_period,1);
% Array for net-metering credits:
credit = zeros(sim_period,1);
% Array for fuel-cell system costs:
fc_cost = zeros(sim_period,1);
% Array for net-metering credits of fuel-cell system:
credit_fc = zeros(sim_period,1);

% Initial conditions
t = 1;
% if energy produced exceeds demand
if energy_balance(t,3) >= 0
    % transfer excess energy as credit on next bill
    credit(t) = abs(energy_balance(t,3));
    % no cost paid at time-step
    net_cost(t) = 0;
else
    credit(t) = 0;
    net_cost(t) = OEB_price_sched(t)*abs(energy_balance(t,3));
end
if energy_balance(t,7) > 0
    fc_cost(t) = OEB_price_sched(t)*energy_balance(t,7);
else
    credit_fc(t) = abs(energy_balance(t,7));
    fc_cost(t) = 0;
end

for t = 2:sim_period
    net_dem(t) = abs(energy_balance(t,3)) - credit(t-1);
    % if energy produced exceeds demand
    if energy_balance(t,3) >= 0
        % DM pays nothing at interval
        net_cost(t) = 0;
        % Excess energy is stored as credit for next interval
        credit(t) = abs(net_dem(t));
    else
        % Apply OEB pricing to net demand
        % Note that cumulative credit transfers over to next 
        % occuring deficit time period
        net_cost(t) = OEB_price_sched(t)*(net_dem(t));
    end
    % Evaluate existing grid costs (without hybrid system)
    exist_dem(t) = energy_balance(t,1)*OEB_price_sched(t);
    if energy_balance(t,7) > 0
        credit_fc(t) = 0;
    else
        credit_fc(t) = abs(energy_balance(t,7));
    end
    % Evaluate cost of hybrid-fuel cell system:
    fc_cost(t) = OEB_price_sched(t)*(energy_balance(t,7) - credit_fc(t-1));
end

% Monitor efficiency - Loss of Power Supply Prob. (LPSP):
% metric of hybrid system grid dependence
fprintf('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n')
fprintf('\n Grid Dependency Metrics: \n\n\n')
surp_def = energy_balance(:,3);
grid_val = abs(surp_def(find(surp_def<0)));
LPSP = sum(grid_val)/(sum(energy_balance(:,1)));
fprintf('\n The Hybrid Energy System (without the Fuel cell) is %2.2f dependent on the Grid [Loss of Power Supply] \n\n',LPSP)

LPSP_2 = sum(energy_balance(:,8))/(sum(energy_balance(:,1)));
fprintf('\n The Hybrid Energy System (with the Fuel cell) is %2.2f dependent on the Grid [Loss of Power Supply] \n\n',LPSP_2)

% Number of hours in deficit:
def_hours = length(grid_val);
fprintf('\n The system experiences %2.0f hours with deficit energy generation and %2.0f at a surplus \n\n', def_hours, 8760-def_hours)

fprintf('\n %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n')
fprintf('\n Fuel Cell-Electrolyzer Metrics: \n\n\n')
% Number of hours of fuel-cell recovery:
fc_gen = energy_balance(:,8);
fc_run = fc_gen(find(fc_gen>0));
fc_hours = length(fc_run);
perc_def = fc_hours/def_hours;
fprintf('\n The Fuel Cell generates energy %2.0f hours a year, meeting %2.0f percent of the deficit periods. \n\n',fc_hours, perc_def*100)

% Annual Hydrogen Production:
Ann_H2_Prod = sum(energy_balance(:,5));
fprintf('\n The Electrolyzer produces %2.2f kg of Hydrogen gas over a year. \n\n',Ann_H2_Prod)


% Storage Tank Properties
tank_stor = energy_balance(:,6);
tank_notempty = length(tank_stor(find(tank_stor >0)));
tank_atcap = length(tank_stor(find(tank_stor==100)));
fprintf('\n Hydrogen Storage Tank runs %2.0f hours per year, and is at capacity for %2.0f of those hours. \n\n',tank_notempty,tank_atcap)

fprintf('\n %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% \n')
fprintf ('\n Financial Metrics: \n\n\n')
% Grid connected Base system cost:
base_cost = sum(exist_dem);
fprintf('\n Annual Electricity cost of existing Grid-connected Pumping System [$]: \n %2.0f \n\n',base_cost)

% Net-metering Hybrid System cost:
hybrid_cost = sum(net_cost);
fprintf('\n Annual Electricity cost of Hybrid-Energy Integrated Pumping System [$]: \n %2.0f \n\n',hybrid_cost')


% Net-metering Fuel cell Hybrid System cost:
fc_hybrid_cost = sum(fc_cost);
fprintf('\n Annual Electricity cost of Integrated Hybrid-Energy System with Fuel Cell [$]:\n %2.0f \n\n',fc_hybrid_cost)

% Percent savings (Net-metering Hybrid versus Grid):
p_save = ((base_cost-hybrid_cost)/base_cost)*100;
fprintf('\n Percent Savings of Hybrid Energy Integrated System (evaluated against existing system): \n %2.0f \n\n', p_save)

% Percent savings (Net-metering Hybrid Fuel Cell System versus Grid):
p_save_fc = ((base_cost-fc_hybrid_cost)/base_cost)*100;
fprintf('\n Percent Savings of Hybrid Energy with Fuel Cell Integrated System (evaluated against existing system): \n %2.0f \n\n', p_save_fc)

% Visualization of Results:
% =========================

figure
plot(1:sim_period,energy_balance(:,1),'-r')
% Annotate Figure
legend('Demand Load')
axis([1,168,1,100])
title('Weekly Energy consumption of Pumping Station');
xlabel('Time(hours)');
ylabel('Energy(kWh)');

figure
plot(1:sim_period,energy_balance(:,2),'-g')
% Annotate Figure
legend('Wind Turbine')
axis([1,168,1,100])
title('Weekly Energy production of Wind Turbine');
xlabel('Time(hours)');
ylabel('Energy(kWh)');

figure
plot(1:sim_period,energy_balance(:,3),'-b',1:sim_period,zeros(sim_period,1),'--k')
legend('Surplus(+ve), Deficit(-ve)')
axis([1,168,-100,100])
title('Load matching capability of Turbine System');
xlabel('Time(hours)');
ylabel('Energy(kWh)');

figure
plot(1:sim_period,energy_balance(:,6),'-c',1:sim_period,energy_balance(:,8),'-r')
% Annotate Figure
legend('Hydrogen Storage','Fuel Cell Discharge')
axis([1,168,1,120])
xlabel('Time(hours)');
ylabel('Energy(kWh)');

% figure
% plot(1:sim_period,energy_balance(:,9),'-k')
% axis([1,168,1,25])
% % Annotate Figure
% title('Hydrogen Storage Tank Level');
% xlabel('Time(hours)');
% ylabel('Volume (m^3)');

figure
y = [net_cost, fc_cost];
bar(y)
legend('NHybrid','Hybrid with Fuel-cell')
axis([1,168,1,1000])
% Annotate Figure
title('Annual Net-Metering Electricity Cost');
xlabel('Time(hours)');
ylabel('Estimated Incurred Cost ($)');