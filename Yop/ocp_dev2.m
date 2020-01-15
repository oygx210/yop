yop.debug(true);
yop.options.set_symbolics('symbolic math');
% yop.options.set_symbolics('casadi');

t0 = yop.parameter('t0'); % end time
tf = yop.parameter('tf'); % end time
% t0 = 0;
% tf = 1;
t = yop.variable('t'); % independent
x = yop.variable('x', 3); % state
u = yop.variable('u'); % control

[~, rocket] = rocket_model(x, u);

% create an optimization problem
ocp = yop.ocp('t', t, 't0', t0, 'tf', tf, 'state', x, 'control', u);

ocp.maximize( ...
    rocket.height(tf) - ...
    rocket.mass(t0) - ...
    rocket.velocity(t==0.5)^2 - ...
    integral(rocket.fuel_mass_flow^2) +...
    2 ...
    );

ocp.subject_to( ...
    0 == t0 <= tf, ...
    der(x) == rocket.dxdt, ...
    x(t0) == [0; 0; 215], ...
    rocket.velocity >= 0, ...
    rocket.height >= 0, ...
    rocket.mass >= 68, ...
    0  <= rocket.fuel_mass_flow <= 9.5 ...
    );

%% Standardform för nlp
% Måste börja med att diskretisera bivillkoren eftersom de säger om det är
% fix horisont.

% 0. Hämta bivillkoren
% 1. Omvandla till standardform
% 2. Tolka tidpunkter för problemet
% 3. Diskretisera 




%% Målfunktion: Tidpunkter, intergral

% Endast tidskontinuerliga uttryck och tidpunkter behöver hittas, de andra
% diskretieras direkt av ocp-variablerna.
[integrals, timepoints] = yop.node.sort(ocp.objective, ...
    @yop.dynamic_optimization.isa_integral, ...
    @yop.dynamic_optimization.isa_timepoint ...
    );

% Diskretisera målfunktionen
K = 10;
points = 'legendre';
d_x = 1;
d_u = 0;
h = (ocp.tf-ocp.t0)./K;

% State trajectory
s_x = size(x,1);
n_x = s_x*(d_x+1)*K + s_x;
w_x = casadi.MX.sym('x', n_x);

state(K+1) = yop.collocation_polynomial();
for k=1:K
    idx = ((k-1)*(d_x+1)*s_x+1):(k*(d_x+1)*s_x);
    state(k).init(points, d_x, reshape(w_x(idx), [s_x, d_x+1]), h*[(k-1) k]);
end
idx = (K*(d_x+1)*s_x+1):(K*(d_x+1)*s_x+s_x);
state(K+1).init(points, 0, w_x(idx), [tf, tf]);

% Control trajectory
s_u = size(u,1);
n_u = s_u*(d_u+1)*K;
w_u = casadi.MX.sym('u', n_u);

control(K) = yop.collocation_polynomial();
for k=1:K
    idx = ((k-1)*(d_u+1)*s_u+1):(k*(d_u+1)*s_u);
    control(k).init(points, d_u, reshape(w_u(idx), [s_u, d_u+1]), h*[(k-1) k]);
end

% Målfunktion


% Bivillkor






















