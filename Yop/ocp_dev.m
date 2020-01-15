yop.debug(true);
% yop.options.set_symbolics('symbolic math');
yop.options.set_symbolics('casadi');

t0 = yop.parameter('t0'); % end time
tf = yop.parameter('tf'); % end time
t = yop.variable('t'); % independent
x = yop.variable('x', 3); % state
z = yop.variable('z', 0);
u = yop.variable('u'); % control
p = yop.parameter('p', 0);

[~, rocket] = rocket_model(x, u);

% create an optimization problem
ocp = yop.ocp('t', t, 't0', t0, 'tf', tf, 'state', x, 'control', u);

ocp.maximize( ...
    rocket.height(tf) - ...
    rocket.mass(t0) - ...
    rocket.velocity(t==0.5)^2 - ...
    integral(rocket.fuel_mass_flow^2) + ...
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

%% Discretization
K = 10;
points = 'legendre';
d_x = 1;
d_u = 0;

[w_x, w_z, w_u, w_p, state, algebraic, control, parameter] = yop.get_variables(x, z, u, p, t0, tf, K, points, d_x, d_u);

%% Constraints classifiction
% <=, ==, differential, box
clear box_con

[box, equality, inequality, differential] = yop.dynamic_optimization.classify(ocp.constraints{:});

box_con(length(box)) = struct();
for k=1:length(box)
    c_k = box.object(k);
    v_k = yop.nonlinear_programming.get_variable(c_k);
    
    box_con(k).constraint = c_k;
    box_con(k).variable = v_k;
    
    if isempty(v_k.timepoint)
        box_con(k).timepoint = [];
        
    elseif isequal(v_k.timepoint, ocp.independent_initial)
        box_con(k).timepoint = ocp.independent_initial;
        
    elseif isequal(v_k.timepoint, ocp.independent_final)
        box_con(k).timepoint = ocp.independent_final;
        
    elseif isequal(v_k.timepoint.left, ocp.independent) && isa(v_k.timepoint.right, 'yop.constant')
        % Om värdet är annat än slut eller start då ska detta bivillkor
        % flyttas till ett path constraint.
        box_con(k).timepoint = c_k.timepoint.right.evalute;
        
    elseif isa(v_k.timepoint.left, 'yop.constant') && isequal(v_k.timepoint.right, ocp.independent)
        box_con(k).timepoint = v_k.timepoint.left.evaluate;
        
    elseif isequal(v_k.timepoint.left, ocp.independent) && isequal(v_k.timepoint.right, ocp.independent_initial)
        box_con(k).timepoint = ocp.independent_initial;
        
    elseif isequal(v_k.timepoint.left, ocp.independent_initial) && isequal(v_k.timepoint.right, ocp.independent)
        box_con(k).timepoint = ocp.independent_initial;
        
    elseif isequal(v_k.timepoint.left, ocp.independent) && isequal(v_k.timepoint.right, ocp.independent_final)
        box_con(k).timepoint = ocp.independent_final;
        
    elseif isequal(v_k.timepoint.left, ocp.independent_final) && isequal(v_k.timepoint.right, ocp.independent)
        box_con(k).timepoint = ocp.independent_final;
        
    end
end

w_x_ub =  inf(size(w_x));
w_x_lb = -inf(size(w_x));
w_z_ub =  inf(size(w_z));
w_z_lb = -inf(size(w_z));
w_u_ub =  inf(size(w_u));
w_u_lb = -inf(size(w_u));
w_p_ub =  inf(size(w_p));
w_p_lb = -inf(size(w_p));

for k=1:length(box_con)
    keyboard
    bd = evaluate(yop.nonlinear_programming.get_bound(box_con(k).constraint));
    
    % Independent initial
    if isequal(box_con(k).variable, ocp.independent_initial)
        
        if yop.nonlinear_programming.isa_upper_bound(box_con(k).constraint)
            w_p_ub(1) = bd;
            
        elseif yop.nonlinear_programming.isa_lower_bound(box_con(k).constraint)
            w_p_lb(1) = bd;
            
        elseif yop.nonlinear_programming.isa_equality(box_con(k).constraint)
            w_p_ub(1) = bd;
            w_p_lb(1) = bd;
            
        else
            yop.error();
            
        end
    end
    
    % Independent final
    if isequal(box_con(k).variable, ocp.independent_final)
        
        if yop.nonlinear_programming.isa_upper_bound(box_con(k).constraint)
            w_p_ub(2) = bd;
            
        elseif yop.nonlinear_programming.isa_lower_bound(box_con(k).constraint)
            w_p_lb(2) = bd;
            
        else
            yop.error();
            
        end
        
    end
    
    % Parameter. Notera att ocp.parameter innefattar t0, tf!
    
    % State
    if isequal(box_con(k).variable, ocp.state)
        
        if isequal(box_con(k).timepoint, ocp.independent_initial)
            
            if yop.nonlinear_programming.isa_upper_bound(box_con(k).constraint)
                w_x_ub(1:ocp.states) = bd;
                
            elseif yop.nonlinear_programming.isa_lower_bound(box_con(k).constraint)
                w_x_lb(1:ocp.states) = bd;
                
            elseif yop.nonlinear_programming.isa_equality(box_con(k).constraint)
                w_x_ub(1:ocp.states) = bd;
                w_x_lb(1:ocp.states) = bd;
                
            else
                yop.error();
                
            end
            
            
        elseif isequal(box_con(k).timepoint, ocp.independent_final)
            
            if yop.nonlinear_programming.isa_upper_bound(box_con(k).constraint)
                w_x_ub((end-ocp.states+1):end) = bd;
                
            elseif yop.nonlinear_programming.isa_lower_bound(box_con(k).constraint)
                w_x_lb((end-ocp.states+1):end) = bd;
                
            elseif yop.nonlinear_programming.isa_equality(box_con(k).constraint)
                w_x_ub((end-ocp.states+1):end) = bd;
                w_x_lb((end-ocp.states+1):end) = bd;
                
            else
                yop.error();
                
            end
            
        else
            
            keyboard
            if yop.nonlinear_programming.isa_upper_bound(box_con(k).constraint)
                w_x_ub((ocp.states+1):(end-ocp.states)) = repmat(bd,K-1,1);
                
            elseif yop.nonlinear_programming.isa_lower_bound(box_con(k).constraint)
                w_x_lb((ocp.states+1):(end-ocp.states)) = repmat(bd,K-1,1);
                
            elseif yop.nonlinear_programming.isa_equality(box_con(k).constraint)
                w_x_ub((ocp.states+1):(end-ocp.states)) = repmat(bd,K-1,1);
                w_x_lb((ocp.states+1):(end-ocp.states)) = repmat(bd,K-1,1);
                
            else
                yop.error();
                
            end
            
        end
        
    end
    
end

% Hantera initial när t==0, t0==0 och mappa det till olikhets-bivillkor.

%% Objective


J_fn = casadi.Function('J', ocp.function_arguments, {ocp.objective.evaluate});

h = evaluate((tf-t0)./K);

tau = yop.collocation_polynomial.collocation_points(points, d_x);

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

objective = J_fn( ...
    ocp.tf, ...
    state(K+1).evaluate(0), ...
    algebraic(K).evaluate(1), ...
    control(K).evaluate(1), ...
    parameter ...
    );

%% Dynamics
ode = casadi.Function('ode', ocp.function_arguments, {rocket.dxdt.evaluate});
alg = casadi.Function('alg', ocp.function_arguments, {[]});

c_dae = [];
for k=1:K
    t_k = ((k-1) + tau(2:end)).*h;
    x_k = state(k).evaluate( tau(2:end) );
    z_k = algebraic(k).evaluate( tau(2:end) );
    u_k = control(k).evaluate( tau(2:end) );
    c_dae = [ ...
        c_dae; ...
        ode(t_k, x_k, z_k, u_k, parameter) - state(k).differentiate.evaluate( tau(2:end) ); ...
        alg(t_k, x_k, z_k, u_k, parameter) ...
        ];
end

% Continuity
c_cont = state(1:K).evaluate(1) - state(2:end).evaluate(0);

%% Equality - Time continuous

%% Inequality - Time continuous

%% Equality - Timepoint

%% Inequality - Timepoint

%% Solve

w = [w_x; w_z; w_u; w_p];
w_ub = [w_x_ub; w_z_ub; w_u_ub; w_p_ub];
w_lb = [w_x_lb; w_z_lb; w_u_lb; w_p_lb];

g = [c_dae(:); c_cont(:)];
g_ub = ones(size(g));
g_lb = g_ub;

nlp = struct;
nlp.x = w;
nlp.f = objective;
nlp.g = g;
solver = casadi.nlpsol('yoptimizer', 'ipopt', nlp);
solution = solver('x0', zeros(size(w)), 'lbx', w_lb, 'ubx', w_ub, 'lbg', g_lb, 'ubg', g_ub);

w_opt = full(solution.x);


