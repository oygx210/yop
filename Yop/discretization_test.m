clear state control

t = casadi.MX.sym('t');
x = casadi.MX.sym('x',2);
z = casadi.MX.sym('z',0);
u = casadi.MX.sym('u');
p = casadi.MX.sym('p', 0);

ode = casadi.Function('ode', {t, x, z, u, p}, {[x(2); u]});
alg = casadi.Function('alg', {t, x, z, u, p}, {[]});
J_fn = casadi.Function('J', {t, x, z, u, p}, {1/2*u^2});

t0 = 0;
tf = 1;

%%
K = 10;
h = (tf-t0)/K;
points = 'legendre';
d_x = 3;
d_u = 0;

%% Independent
time = yop.lagrange_polynomial();
time.init([t0, tf], [t0, tf]);

%% State
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

%% Algebraic
s_z = size(z,1);
n_z = s_z*(d_x+1)*K;
w_z = casadi.MX.sym('z', n_z);

algebraic(K) = yop.collocation_polynomial();
for k=1:K
    idx = ((k-1)*(d_x+1)*s_z+1):(k*(d_x+1)*s_z);
    algebraic(k).init(points, d_x, reshape(w_z(idx), [s_z, d_x+1]), h*[(k-1) k]);
end

%% Control
s_u = size(u,1);
n_u = s_u*(d_u+1)*K;
w_u = casadi.MX.sym('u', n_u);

control(K) = yop.collocation_polynomial();
for k=1:K
    idx = ((k-1)*(d_u+1)*s_u+1):(k*(d_u+1)*s_u);
    control(k).init(points, d_u, reshape(w_u(idx), [s_u, d_u+1]), h*[(k-1) k]);
end

%% Parameters
parameter = p;

%% Dynamics
tau = yop.collocation_polynomial.collocation_points(points, d_x);

c_dae = [];
for k=1:K
    t_k = ((k-1) + tau(2:end))*h;
    x_k = state(k).evaluate( tau(2:end) );
    z_k = algebraic(k).evaluate( tau(2:end) );
    u_k = control(k).evaluate( tau(2:end) );
    c_dae = [ ...
        c_dae; ...
        ode(t_k, x_k, z_k, u_k, parameter) - state(k).differentiate.evaluate( tau(2:end) ); ...
        alg(t_k, x_k, z_k, u_k, parameter) ...
        ];
end

%% Continuity
c_cont = state(1:K).evaluate(1) - state(2:end).evaluate(0);

%% Objective
objective_integrand(K) = yop.collocation_polynomial();
for k=1:K
    t = (k-1)*h;
    c_k = [];
    for r=1:d_x+1
        t_kr = ((k-1) + tau(r))*h;
        x_kr = state(k).evaluate(tau(r));
        z_kr = algebraic(k).evaluate(tau(r));
        u_kr = control(k).evaluate(tau(r));
        c_k = [c_k, J_fn(t_kr, x_kr, z_kr, u_kr, parameter)];
    end
    
    objective_integrand(k).init(points, d_x, c_k, h*[(k-1) k]);
end

objective = sum(objective_integrand.integrate.evaluate(1));

%% Nlp

lb_x = -inf(size(w_x));
ub_x =  inf(size(w_x));
ub_x(1:2:end) = 1/9;
lb_x(1:2) = [0; 1];
ub_x(1:2) = [0; 1];
lb_x(end-1:end) = [0; -1];
ub_x(end-1:end) = [0; -1];

lb_u = -inf(size(w_u));
ub_u =  inf(size(w_u));

w = [w_x; w_u];
w_lb = [lb_x; lb_u];
w_ub = [ub_x; ub_u];

g = [c_dae(:); c_cont(:)];
g_ub = zeros(size(g));
g_lb = g_ub;

nlp = struct;
nlp.x = w;
nlp.f = objective;
nlp.g = g;
solver = casadi.nlpsol('yoptimizer', 'ipopt', nlp);
solution = solver('x0', zeros(size(w)), 'lbx', w_lb, 'ubx', w_ub, 'lbg', g_lb, 'ubg', g_ub);

w_opt = full(solution.x);


%%
t_x = [];
for k=1:K
    t_k = h*(k-1);
    for r=1:d_x+1
        t_x = [t_x, t_k + h*tau(r)];
    end
end
t_x = [t_x, tf];

tau_u = yop.collocation_polynomial.collocation_points(points, d_u);
t_u = [];
for k=1:K
    t_k = h*(k-1);
    for r=1:d_u+1
        t_u = [t_u, t_k + h*tau_u(r)];
    end
end
t_u = [t_u, tf];

x_fun = casadi.Function('x', {w}, {w_x});
u_fun = casadi.Function('u', {w}, {w_u});
u_end = casadi.Function('u_end', {w}, {control(K).evaluate(1)});
%%

x_opt = full(x_fun(w_opt));
x1_opt = x_opt(1:2:end);
x2_opt = x_opt(2:2:end);
u_opt = full(u_fun(w_opt));
u_opt(end+1) = full(u_end(w_opt));


figure(1);
subplot(311); hold on;
plot(t_x, x1_opt)
subplot(312); hold on;
plot(t_x, x2_opt)
subplot(313); hold on;
stairs(t_u, u_opt)



















