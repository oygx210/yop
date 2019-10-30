%% Yop
import yop.*
yop.options('my_fav_opts.mat');

% variable - tidskontinuerlig
% parameter - parameter som ska optimeras
% constant - konstant vars värde man kan ändra mellan körningar

t_0 = parameter('t_0');
t_f = parameter('t_f');
t   = variable('t');
x   = variable('x', [2, 1]);
u   = variable('u');
l   = constant('l', [1, 1]);
alpa = signal('alpha', [1, 1]);
alpha.signal = @(t) f(t);

[ode, cart] = trolley_model(t, x, u);

% Interface mot alla matlabs lösare?
% Beskriva ocp-lösaren i yop mha yop? Dvs. ställa upp det olinjära
% problemet mha yop? förs nlp-lösare sedan ocp-lösare
ocp = optimization_problem('t0', t_0, 'tf', t_f, 'state', x, 'control', u, 'parameter', p);

ocp.minimize( 1/2*integral( cart.acceleration^2 ) );

constraint1 = some_expression <= some_other_expression;

ocp.subject_to( ...
    der(x) == trolley_model(x,u), ...
    alg(0) == ae, ...
    t0(cart.position) == 0, ...
    t0(cart.speed) == 1, ...
    tf(cart.position) == 0, ...
    tf(cart.speed) == 1, ...
    cart.position <= l, ...
    constraint1, ...
    0 == t_0 <= t_f == 1 ...
    );

l.value = 2;
alpha.signal =  @(t) f(t);

ocp.method = 'direct_collocation';
% help ocp.set.method
ocp.points = 'legendre';
ocp.set('segments', 100, 'degree', 5);
res = ocp.solve();

ocp.constraint(3).strict;
strict(constraint1); % Trigger event;

l.value = 3;
ocp.initial_guess = sim_res2; % trigger event to change the initial guess
res2 = ocp.solve(); % Options remembered

figure(1)
subplot(211)
res.plot(t, x(1));
subplot(212)
res.plot(t, x(2));

figure(2)
res.plot(t, u);

%% Simulation
simulator = yop.simulator('t0', t_0, 'tf', t_f, 'state', x, 'algebraic', z);

simulator.problem(t_0==0, t_f==1, dot(x)==ode, t0(x)==x0);

simulator.steps = 100;
simulator.reltol = 1e-4;
simulator.integrator = 'ode15s';
sim_res = simulator.simulate();


%% Optimization problems (general)

v = variable('v', 100);
c = constatn('c', 1);
c.value = 0;

yoptimizer = yop.optimization_pronblem('variable', v);
yoptimizer.minimize(norm(v-c));
yoptimizer.subject_to(-1 <= v <= 1);
yoptimizer.solver = 'fmincon';

res = yoptimizer.solve();

c.value = 1;
res1 = yoptimizer.solve();
