function [w_x, w_z, w_u, w_p, state, algebraic, control, parameter] = get_variables(x, z, u, p, t0, tf, K, points, d_x, d_u)

h = evaluate((tf-t0)/K);

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

% Algebraic
s_z = size(z,1);
n_z = s_z*(d_x+1)*K;
w_z = casadi.MX.sym('z', n_z);

algebraic(K) = yop.collocation_polynomial();
for k=1:K
    idx = ((k-1)*(d_x+1)*s_z+1):(k*(d_x+1)*s_z);
    algebraic(k).init(points, d_x, reshape(w_z(idx), [s_z, d_x+1]), h*[(k-1) k]);
end

% Control
s_u = size(u,1);
n_u = s_u*(d_u+1)*K;
w_u = casadi.MX.sym('u', n_u);

control(K) = yop.collocation_polynomial();
for k=1:K
    idx = ((k-1)*(d_u+1)*s_u+1):(k*(d_u+1)*s_u);
    control(k).init(points, d_u, reshape(w_u(idx), [s_u, d_u+1]), h*[(k-1) k]);
end

% Parameters
parameter = p.evaluate;

w_p = [t0.evaluate; tf.evaluate; parameter];

end