import yop.*
t = variable('t');
tf = variable('tf');
x = variable('x', 3);
u = variable('u');
m0 = 214.839;
mf = 67.9833;
F_max = 9.525515;
[dxdt, rocket] = rocket_model(x, u);
ocp = optimization_problem( ...
    't', t, 't0', 0, 'tf', tf, 'state', x, 'control', u);
ocp.maximize( rocket.height(tf) );
ocp.subject_to( ...
    tf >= 0, ...
    der(x) == dxdt, ...
    rocket.velocity(t==0) == 0, ...
    rocket.height(t==0) == 0, ...
    rocket.mass(t==0) == m0, ...
    rocket.velocity >= 0, ...
    rocket.height >= 0, ...
    rocket.mass >= mf, ...
    0  <= rocket.fuel_mass_flow <= F_max ...
    );
sol = ocp.solve('control_intervals', 60);
figure(1)
subplot(311); hold on
sol.plot(time, rocket.velocity)
xlabel('Time'); ylabel('Velocity')
subplot(312); hold on
sol.plot(time, rocket.height)
xlabel('Time'); ylabel('Height')
subplot(313); hold on
sol.plot(time, rocket.mass)
xlabel('Time'); ylabel('Mass')
figure(2); hold on
sol.stairs(time, rocket.fuel_mass_flow)
xlabel('Time'); ylabel('F (Control)')

%% Model
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