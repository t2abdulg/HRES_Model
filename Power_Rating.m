function [P_v] = Power_Rating(cut_in_vel, cut_out_vel, rated_vel, rated_power)
% Function to develop the Power Rating Curve based on Manufacturer Turbine
% Specifications

% ======================================
% Nomenclature:
% ======================================

% Velocity - Power Proportionality Factor
n = 3;

% Rated Power
P_r = rated_power;

% Rated Velocity
V_r = rated_vel;

% Cut in Velocity
V_i = cut_in_vel;

% Cut out Velocity
V_o = cut_out_vel;

V = linspace(0,100,1000);
P_v = zeros(length(V),1);

for i = 1:length(V)
        
    if V(i) < V_i
        % Region 1: Power Output (for V < V_i) - System is non-generating
        P_v(i) = 0;

    elseif V(i) >= V_i & V(i) < V_r 
        % Region 2: Power Output (for V_i <= V < V_r)
        P_v(i) = P_r*(V(i).^n - V_i^n)./(V_r^n - V_i^n);

    elseif V(i) >= V_r & V(i) <= V_o
        % Region 3: Power Output (for V_r <= V <= V_o)
        P_v(i) = P_r;

    elseif V(i) > V_o
        % Region 4: Power Output (for V > V_o) - System is non-generating
        P_v(i) = 0;
    end
    
end
% Return P_v : Turbine Power Rating Curve Array Output 

end

