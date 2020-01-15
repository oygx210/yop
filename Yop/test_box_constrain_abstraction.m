% State
t0 = yop.parameter('t0');
tf = yop.parameter('tf');
segments = 1;
points = 'legendre';
degree = 3;
states = size(x,1);

state = yop.ocp_state(t0, tf, segments, points, degree, states);

state(2:end-1).set_upper_bound(variable, 1)

%%



