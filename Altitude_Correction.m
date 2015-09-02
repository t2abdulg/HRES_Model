function [ v_corr ] = Altitude_Correction(wind_speed,design_height, roughness_index)
%Correct Wind Speed Time Series for Velocity encountered at hub height of
%turbine
roughness_class = [ 0:0.5:4];
roughness_height = [0.0002 0.0024 0.03 0.055 0.1 0.2 0.4 0.6 1.6]; 

Z_o = roughness_height(find(roughness_class ==roughness_index));
Z_meas = 10;
Z_d = design_height;
v_u = wind_speed;

v_corr = v_u.*(log(Z_d/Z_o)/ log(Z_meas/Z_o));

end

