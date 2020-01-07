yop.debug(true);
% yop.options.set_symbolics('symbolic math');
yop.options.set_symbolics('casadi');

t0 = yop.parameter('t0'); % end time
tf = yop.parameter('tf'); % end time
t = yop.variable('t'); % independent
x = yop.variable('x', 3); % state
u = yop.variable('u'); % control

[~, rocket] = rocket_model(x, u);

% create an optimization problem
ocp = yop.ocp('t', t, 't0', t0, 'tf', tf, 'state', x, 'control', u);

ocp.maximize( rocket.height(tf) );

ocp.subject_to( ...
    0 == t0 <= tf, ...
    der(x) == rocket.dxdt, ...
    x(t0) == [0; 0; 215], ...
    rocket.velocity >= 0, ...
    rocket.height >= 0, ...
    rocket.mass >= 68, ...
    0  <= rocket.fuel_mass_flow <= 9.5 ...
    );

%% Discretization
K = 10;
points = 'legendre';
d_x = 3;
d_u = 0;

%% Signals
h = (tf-t0)/K;

% State
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

% Control
s_u = size(u,1);
n_u = s_u*(d_u+1)*K;
w_u = casadi.MX.sym('u', n_u);

control(K) = yop.collocation_polynomial();
for k=1:K
    idx = ((k-1)*(d_u+1)*s_u+1):(k*(d_u+1)*s_u);
    control(k).init(points, d_u, reshape(w_u(idx), [s_u, d_u+1]), h*[(k-1) k]);
end

w = [w_x; w_u; t0.evaluate; tf.evaluate];
w_ub = inf(size(w));
w_lb = -inf(size(w));

%% Constraints classifiction
% <=, ==, differential, box
[box, equality, inequality, differential] = yop.dynamic_optimization.classify(ocp.constraints{:});

% Tidskontinuerlig eller tidpunkt spelar ingen roll. Uttrycken ska brytas
% upp, diskretiseras och sedan utvärderas.

%% Map box constraints

for k=1:length(box)
    bd = yop.nonlinear_programming.get_bound(box.object(k));
    
    if yop.nonlinear_programming.isa_upper_bound(box.object(k))
        if box.object(k).timepoint = 
        
    elseif yop.nonlinear_programming.isa_lower_bound(box.object(k))
        
    elseif yop.nonlinear_programming.isa_equality(box.object(k))
        
    end
    
end

% Typ
% Vilken variabel
% Tidsutbredning

%% Objective

%% Dynamics

%% Equality - Time continuous

%% Inequality - Time continuous

%% Equality - Timepoint

%% Inequality - Timepoint

%% Objekt som tar bivillkor och diskretiserar dem