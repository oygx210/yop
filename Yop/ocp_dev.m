yop.debug(true);
yop.options.set_symbolics('symbolic math');
% yop.options.set_symbolics('casadi');

t0 = yop.parameter('t0');
tf = yop.parameter('tf');
t  = yop.variable('t');
x  = yop.variable('x', 2);
u  = yop.variable('u');

ocp = yop.optimization_problem(...
    't', t, 't0', t0, 'tf', tf, 'state', x, 'control', u);

ocp.minimize( 1/2*integral( u^2 ) );

ocp.subject_to( ...
    der(x)  == [x(2); u], ...
    x(t==0) == [0; 1],    ... 
    x(t==1) == [0;-1],    ...
    x(1)    <= 1/9        );

%% Constraints classifiction

% Tidskontinuerlig, tidpunkt, <=, ==, integral, differential, box

[ineq, eq, box, differential] = classify(constraints);

%% Objective

%% Dynamics

%% Equality - Time continuous

%% Inequality - Time continuous

%% Equality - Timepoint

%% Inequality - Timepoint

%% Objekt som tar bivillkor och diskretiserar dem