function [dxdt, rocket] = rocket_model(x, u)
% States and control
v = x(1); % Velocity
h = x(2); % Height
m = x(3); % Fuelmass
F = u;    % Thrust

% Parameters
D0   = 0.01227;
beta = 0.145e-3;
c    = 2060;
g0   = 9.81;
r0   = 6.371e6;

% Drag and gravity
D   = D0 * exp( -beta*h );
F_D = sign(v) * D * v^2;
g   = g0 * ( r0 / (r0+h) )^2;

% Dynamics
dv = ( F*c - F_D )/m - g;
dh = v;
dm = -F;
dxdt = [dv;dh;dm];

% Signals y
rocket.velocity = v;
rocket.height = h;
rocket.mass = m;
rocket.fuel_mass_flow = F;
end