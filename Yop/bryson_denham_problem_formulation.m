yop.debug(true);
yop.options.set_symbolics('symbolic math');
% yop.options.set_symbolics('casadi');

t  = yop.variable('t');
x  = yop.variable('x', 2);
u  = yop.variable('u');

J = 1/2*integral( u^2 );

c1 = der(x)  == [x(2); u];
c2 = x(t==0) == [0; 1];
c3 = x(t==1) == [0;-1];
c4 = x(1)    <= 1/9;

constraints = {c1, c2, c3, c4};
%%
t  = yop.variable('t');
x  = yop.variable('x', 2);
u  = yop.variable('u');

s = x(1); 
v = x(2); 
a = u;

J = 1/2*integral( a^2 );

c1 = der(s) == v;
c2 = der(v) == a;
c3 = s(t==0) ==  s(t==1) == 0;
c4 = v(t==0) == -v(t==1) == 1;
c5 = s <= 1/9;

constraints = {c1, c2, c3, c4, c5};
%% Objective
% Decompose into computable parts
% hitta: t0, ti, tf, integral, integrate, differentiate, derivative
%  de som inte faller inom kategorin ska kunna utvärderas direkt.
% copy->decompose->parameterize->evaluate
% Behöver kopiera allt utom variabler

% copy_upto(obj, {nodes})
%  if node == nodes{k}; break

% objective = J.copy_structure;

% Diffekvationer / DAE-er
% Integraler
% Tidpunkter
% Tidskontinuerliga uttryck


% 1. Leta efter noder som matchar integral, tidpunkt, index,
% 2. 

[t0_list, t_list, tf_list, integral_list] = yop.node.sort(J, ...
    @(x) isequal(x.operation, @yop.t0), ...
    @(x) isequal(x.operation, @yop.t), ...
    @(x) isequal(x.operation, @yop.tf), ...
    @(x) isequal(x.operation, @yop.integral) ...
    );

%% Loopa över cell arrayen istället och bena ut noderna.
constraints = yop.node_list().add_array(user_constraints);
[dynamics, box_and_path] = constraints.sort("first", ...
    @yop.dynamic_optimization.dynamics, ...
    @(x) true ...
    );











