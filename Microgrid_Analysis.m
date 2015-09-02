function [res_mat] = Microgrid_Analysis(sim_period,wind,dem)

%============================================================
% Energy Balance Arrays
%============================================================
% Equivalent energy storage of Hydrogen gas stored in H2 Tank
E_stor = zeros(sim_period,1);
% Energy produced by Wind Turbine
E_wt = wind;
% Energy demand of Hydraulic System
E_load = dem;
% Energy produced by Fuel Cell System
E_fc = zeros(sim_period,1);
% Energy drawn from Grid
E_grid = zeros(sim_period,1);

% Differential Energy - difference between load and production
% defines whether system is operating under deficit or surplus case
E_diff = zeros(sim_period,1);

%============================================================
% Operational Parameters
%============================================================

% Storage Tank Parameters:
%============================================================
% Minimum level of H2 gas storage tank
E_stor_min = 0;                                 %kWh
% Maximum level of H2 gas storage tank
E_stor_max = 100;                               %kWh
% Volume of H2 in tank under STP 
H2_Nvol =  zeros(sim_period,1);                 %m^3

% Power Regulator Efficiency ( includes inverter efficiency)
n_PR = 1.00;

% Fuel Cell Parameters:
%============================================================
% Lower Heating value of H2 gas
LHV = 33.3;                                     %kWh/kg of H2
% LHV Efficiency 
n_FC = 0.50;
% Purity of H2 gas
H2_pur = 0.9999;
% Normalised density of H2 gas under STP
H2_Ndens = 0.0899;                              %kg/m^3

% Electrolyzer Parameters:
%============================================================
% Mass of H2 gas produced 
H2_prod = zeros(sim_period,1);                  %kg
% Nominal Power of Electrolyzer
E_elec_nom = 40;                                %kW
% Hydrogen Generation Power consumption rate
E_elec_hyd = 63.4;                              %kWh/kg H2
% Start-up requirement of Electrolyzer (10% of nominal power)
E_elec_min = 0.1*E_elec_nom;                    %kWh
% Overload power of Electrolyzer
E_elec_ov = 2.00*E_elec_nom;                    %kWh
% Water consumption
W_consum = zeros(sim_period,1);                 %L
% Compressor Energy requirements
compres = 2.3;                                   %kWh

% Error check input data files
if length(E_wt) ~= sim_period | length(E_load) ~= sim_period
    error('WARNING: Simulation period does not match number of entries provided in uploaded datasets')
end
% Record whether system is storing(1) or discharging (0)
op_status = zeros(sim_period,1);

%============================================================
% Algorithm Loop
%============================================================

% Initial conditions:
% -------------------

% Initialise tank at 50% capacity
E_stor(1) = 1*E_stor_max;


% Iterate from 2nd time period till end of simulation period
for t = 2:(sim_period+1)
    % Load balance: Difference between Generated and Load at time step, t
    E_diff(t-1) = n_PR*E_wt(t-1) - E_load(t-1);
    % Deterimine if surplus or deficit energy generation 
    if E_diff(t-1) >= 0
        op_scenario = 'Excess';
        op_status(t-1) = 1; 
    else
        op_scenario = 'Deficit';
        op_status(t-1) = 0;
    end
    % Define Storage-Discharge operational strategy based on load balance
    switch op_scenario
        
        case 'Excess'
            % if Energy is within operational band of Electrolyzer
            if E_diff(t-1)>= E_elec_min && E_diff(t-1) <= E_elec_ov
                % check Energy storage level in tank
                if E_diff(t-1) <= E_stor_max - E_stor(t-1)
                    % calculate H2 gas produced at time step by Elec.
                    H2_prod(t-1) = n_PR*(E_diff(t-1))/E_elec_hyd;
                    % send H2 gas to tank; express as energy for use by FC
                    E_stor(t) = E_stor(t-1) + ((H2_prod(t-1)*LHV)*n_FC)*n_PR;
                else
                    E_stor(t) = E_stor_max;
                    % sent to grid
                    E_grid(t-1) = E_diff(t-1)- (E_stor_max - E_stor(t-1));
                end
            elseif E_diff(t-1) == 0
                E_stor(t) = E_stor(t-1);
            else
                % sent to grid
               E_stor(t) = E_stor(t-1); 
               E_grid(t-1) = -1*E_diff(t-1); 
            end
            
        case 'Deficit'
            % Note that E_diff is negative in deficit case
            % if Energy available in tank
            if E_stor(t-1) >= abs(E_diff(t-1))
                E_fc(t-1) = abs(E_diff(t-1));
                E_stor(t) = E_stor(t-1) - E_fc(t-1);
            else
                % draw from grid
                E_grid(t-1) = (abs(E_diff(t-1)) - E_stor(t-1))/n_PR;
                E_fc(t-1) = E_stor(t-1);
            end
    end 
end       
% Volume of Hydrogen in tank throughout simulation period 
H2_Nvol = (((E_stor./LHV)*n_FC)./H2_Ndens);


res_mat = zeros(sim_period,10);
res_mat(:,1) = E_load;
res_mat(:,2) = E_wt;
res_mat(:,3) = E_diff;
res_mat(:,4) = op_status;
res_mat(:,5) = H2_prod;
E_stor = E_stor(2:sim_period+1);
res_mat(:,6) = E_stor;
res_mat(:,7) = E_grid;
res_mat(:,8) = E_fc;
H2_Nvol = H2_Nvol(2:sim_period+1);
res_mat(:,9) = H2_Nvol;
res_mat(:,10) = W_consum;
end