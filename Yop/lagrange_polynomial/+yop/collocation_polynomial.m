classdef collocation_polynomial < yop.lagrange_polynomial
    % COLLOCATION_POLYNOMIAL Lagrange polynomials used in collocation
    % methods.
    %    Approximates a function over the interval t \in [t0+h, t0].
    %    t = t0 + tau*h, tau \in [0, 1], using Lagrange polynomials.
    %    The Lagrange polynomial is calculated as:
    %
    %      L(t) = L(t0 + tau*h) = sum( l_j(tau)*x_j )_{j=0}^{d}
    %      l_j(tau) = prod( (tau - tau_r)/(tau_j - tau_r) )_{r=0, r/=j}^{d}
    %
    %    where L is the Lagrange polynomial, l_j the basis polynimals,
    %    tau normalized time, tau_i the collocation points, x_j the
    %    signal values at the collocation points, and d the polynomial
    %    degree.
    %
    % -- Properties --
    %    valid_range : Two element row vector specifying the valid range of
    %                   the polynomial. i.e. [t0, tf].
    %
    %    step_factor : Keeps track of the inner derivative constant.
    %
    % -- Properties (Derived) --
    %    timepoint : Row vector describing the sampling timepoints
    %
    %    value     : Matrix describing the sampling values. Must have
    %                 equally many rows as in 'timepoint'. E.g. if the
    %                 sampled signal is scalar-valued, 'value' is a row
    %                 vector.
    %
    %    basis     : Matrix containing the Lagrange basis polynomials.
    %
    % -- Methods --
    %    values = evaluate(obj, tau) : Evaluate the polynomial at
    %                                   normalized time tau.
    %
    %    polynomial=integrate(obj,constant_term):Integrates the polynomial.
    %
    %    polynomial = differentiate(obj) : Differentiate the polynomial.
    %
    %    len = h(obj) : Get the length of the valid range.
    %
    %    t = t0(obj) : Get the intital timepoint of the valid range.
    %
    %    t = tf(obj) : Get the last timepoint of the valid range.
    %
    % -- Methods (Static) --
    %    tau = collocation_points(points, degree) : Get collocation points.
    %
    % -- Methods (Derived) --
    %    obj = lagrange_polynomial() : Constructor.
    %
    %    obj = init(obj, timepoints, values) : Initialization method.
    %
    %    obj = calculate_basis(obj) : Calculates the basis polynomials.
    %
    %    deg = degree(obj) : Get the polynomial degree.
    %
    % -- Examples --
    %    % COPY INTO SCRIPT
    %    % Approximate the t^2 and t^3  at the specified timepoints using a
    %    %  second order collocation polynomial.
    %    timepoints = [1,2,3];
    %    analytical_values = @(t) [t.^2; t.^3];
    %    analytical_derivative = @(t) [2*t; 3*t.^2];
    %    analytical_integral = @(t) [t.^3/3; t.^4/4];
    %
    %    t_0 = 1;
    %    t_f = 3;
    %    h = t_f-t_0;
    %    points = 'legendre';
    %    deg = 2;
    %
    %    tau = yop.collocation_polynomial.collocation_points(points, deg);
    %    values = analytical_values(t_0 + tau*h);
    %
    %    cp = yop.collocation_polynomial();
    %    cp.init(points, deg, values, [t_0, t_f]);
    %
    %    t = linspace(t_0, t_f, 21);
    %    figure(1); hold on
    %    plot(t, analytical_values(t))
    %    plot(t, cp.evaluate((t-t_0)./h), 'x')
    %    legend('t^2', 't^3', 'cp_1', 'cp_2')
    %    title('Polynomial approximation')
    %
    %    figure(2); hold on
    %    plot(t, analytical_derivative(t))
    %    plot(t, cp.differentiate.evaluate((t-t_0)./h), 'x')
    %    legend('2*t', '3*t.^2', 'cp_1', 'cp_2')
    %    title('differentiation')
    %
    %    figure(3); hold on
    %    plot(t, analytical_integral(t))
    %    plot(t, cp.integrate.evaluate((t-t_0)./h), 'x')
    %    legend('1/3 t.^3', '1/4 t.^4', 'cp_1', 'cp_2')
    %    title('integration')
    %
    % -- Details --
    %    For details regarding Lagrange polynomials see:
    %    https://en.wikipedia.org/wiki/Lagrange_polynomial
    properties
        valid_range  % Valid range of the polynomial [t0, tf]
        step_factor = 1; % Is a property because the polynomial functions
                         %  cannot operate on yop objects. The purpose is
                         %  keep track of the inner derivative in
                         %  differentiation and inegration.
    end
    
    methods
        
        function obj = collocation_polynomial()
            % COLLOCATION_POLYNOMIAL Class constructor
            %    Takes no arguments but requires initialization. See the
            %    collocation_polynomial.init method for more information
            %    regarding initialization.
            %
            % -- Syntax --
            %    obj = collocation_polynomial()
            %
            % -- Exampels --
            %    lp = yop.collocation_polynomial()
        end
        
        function obj = init(obj, points, degree, values, valid_range)
            % INIT Initialize the collocation polynomial
            %    Initialize the polynomial by providing the selection of
            %    collocation points, the polynomial degree, the values at
            %    the collocation points, and the valid range of the
            %    polynomial.
            %
            % -- Syntax --
            %    obj.init(points, degree, values, valid_range)
            %    init(obj, points, degree, values, valid_range)
            %    obj = init(obj, points, degree, values, valid_range)
            %    obj = obj.init(points, degree, values, valid_range)
            %
            % -- Arguments --
            %    obj : Handle to the collocation polynomial.
            %
            %    points : The class of the collocation points.
            %           = 'legendre'  Selects the Legendre collocation
            %                         points.
            %           = 'radau'  Selects the Radau collocation points.
            %
            %    degree : The degree of the collocation polynomial.
            %
            %    values : The signal values at the collocation points.
            %              Specified as a matrix. Same number of columns as
            %              'degree'+1, and same number of rows as signal
            %              dimension.
            %
            %    valid_range : Two element row matrix describing the valid
            %                  range of the polynomial: [t0, tf].
            %
            % -- Examples --
            %    cp.init('legendre', 3, [1,2.02,6.64;1,2.88,17.12], [1,3]);
            %    cp.init('radau', 3, [1,2.02,6.64], [1,3]);
            %    init(cp, 'legendre', 3, [1,2.88,17.12], [1,3]);
            
            collocation_points = ...
                yop.collocation_polynomial.collocation_points(points, degree);
            obj.init@yop.lagrange_polynomial(collocation_points, values);
            obj.valid_range = valid_range;
        end
        
        function value = evaluate(obj, tau)
            % EVALUATE Evaluates the polynomial at normalized time tau.
            %    On the valid interval t \in [t0, tf] the normalized time
            %    tau = (t-t0)/h, h = tf-t0. Evaluates the polynomial
            %
            %       L(t) = sum( l_j(tau)*x_j )_{j=0}^{d}
            %
            % -- Syntax --
            %    value = obj.evaluate(tau)
            %    value = evaluate(obj, tau)
            %
            % -- Arguments --
            %    obj : A handle to the polynomial. Can be an object array.
            %
            %    tau : Normalized time. Specified as a scalar in [0,1], or
            %          as a row vector with timepoints in [0,1]. 
            %
            %    value : The value/-s at the normalized time/-points.
            %            Results when an object array is input are
            %            concatenated horizontally.
            %
            % -- Examples --
            %    value = cp.evaluate(0)
            %    value = cp.evaluate(1)
            %    value = cp.evaluate(0:0.1:1)
            %    value = evaluate(cp, 0.5)
            
            value = [];
            for k=1:length(obj)
                value = [value, obj(k).evaluate@yop.lagrange_polynomial(tau).*obj(k).step_factor];
            end
        end
        
        function polynomial = integrate(obj, constant_term)
            % INTEGRATE Integrates the collocation polynomial.
            %    Integrates the polynomial with an optional constant term.
            %    Returns a new polynomial that is the integration of the
            %    input. The integration is calculated as:
            %
            %    L_int(t) = h*sum( integral(l_j(tau))_0^1 * x_j)_{j=0}^{d}.
            %
            % -- Syntax --
            %    polynomial = obj.integrate(constant_term)
            %    polynomial = integrate(obj, constant_term)
            %
            % -- Arguments --
            %    obj : A handle to the collocation polynomial. Can be an
            %          object array. Object arrays are returned
            %          concatenated horizontally.
            %
            %    polynomial : A new collocation polynomial object that is
            %                 the integration of the input. Results when an
            %                 object array is input are returned
            %                 concatenated horizontally.
            %
            % -- Arguments (Optional) --
            %    constant_term : Constant of integration. Specified as a
            %                     scalar. Defaults to 0.
            %
            % -- Examples --
            %    polynomial = cp.integrate()
            %    polynomial = integrate(cp)
            %    polynomial = cp.integrate(1)
            %    polynomial = integrate(cp, 2)
            
            if nargin == 1
                constant_term = 0;
            end
            polynomial = [];
            for k=1:length(obj)
                pk = obj(k).integrate@yop.lagrange_polynomial(constant_term);
                pk.step_factor = pk.step_factor * obj(k).h;
                polynomial = [polynomial, pk];
            end
        end
        
        function polynomial = differentiate(obj)
            % DIFFERENTIATE Differentiate the collocation polynomial
            %    Differentiates the polynomial by creating a new polynomial
            %    on the following form:
            %
            %     L(t) = 1/h*sum( jacobian(l_j(tau), tau)*x_j )_{j=0}^{d}.
            %
            % -- Syntax --
            %    polynomial = obj.differentiate()
            %    polynomial = differentiate(obj)
            %
            % -- Arguments --
            %    obj : A handle to the collocation polynomial. Can be an
            %          object array. Object arrays are returned
            %          concatenated horizontally.
            %
            %    polynomial : A new collocation polynomial object that is
            %                 the differentiation of the input. Results
            %                 when an object array is input are returned
            %                 concatenated horizontally.
            %
            % -- Examples --
            %    polynomial = obj.differentiate()
            %    polynomial = differentiate(obj)
            polynomial = [];
            for k=1:length(obj)
                pk = obj(k).differentiate@yop.lagrange_polynomial();
                pk.step_factor = pk.step_factor / obj(k).h;
                polynomial = [polynomial, pk];
            end
        end
        
        function len = h(obj)
            % H Length of the valid range.
            %
            % -- Syntax --
            %    len = obj.h
            %    len = h(obj)
            %
            % -- Arguments --
            %    obj : A handle to the collocation polynomial. Or an array
            %          of handles.
            %
            %    len : Length of the valid range. Results when an object
            %          array is input are concatenated horizontally.
            
            len = zeros(1, length(obj)-1);
            for k=1:length(obj)
                len(k) = obj(k).valid_range(2) - obj(k).valid_range(1);
            end
        end
        
        function t = t0(obj)
            % T0 Starting timepoint of the valid range.
            %
            % -- Syntax --
            %    t = obj.t0
            %    t = t0(obj)
            %
            % -- Arguments --
            %    obj : A handle to the collocation polynomial. Can be an
            %          object array.
            %
            %    t : The value of the starting timepoint. Results when an
            %        object array is input are concatenated horizontally.
            
            t = zeros(1, length(obj));
            for k=1:length(obj)
                t(k) = obj(k).valid_range(1);
            end
        end
        
        function t = tf(obj)
            % TF End timepoint of the valid range.
            %
            % -- Syntax --
            %    t = obj.tf
            %    t = tf(obj)
            %
            % -- Arguments --
            %    obj : A handle to the collocation polynomial. Can be an
            %          object array.
            %
            %    t : The value of the end timepoint. Results when an object
            %        array is input are concatenated horizontally.
            
            t = zeros(1, length(obj));
            for k=1:length(obj)
                t(k) = obj(k).valid_range(2);
            end
        end
        
    end
    
    methods (Static)
        function tau = collocation_points(points, degree)
            % COLLOCATION_POINTS Get the collocation points of the class
            % 'points ' of the degree 'degree'
            %
            % -- Syntax --
            %    tau = collocation_polynomial.collocation_points(points, degree)
            %
            % -- Arguments --
            %    points : Class of the collocation points.
            %           = 'legendre'  Returns the legendre points
            %           = 'radau'     Returns the radau points
            %
            %    degree : The degree of the collocation points.
            %           = integer in the range [0,9]. 0 makes the
            %              polynomial a constant.
            %
            % -- Examples --
            %    tau = collocation_polynomial.collocation_points('legendre', 5)
            %    tau = collocation_polynomial.collocation_points('radau', 1)
            
            if degree >= 1
                folder = fileparts( mfilename('fullpath') );
                cp = load([folder '/collocation_points.mat']);
                tau = cp.collocation_points.(points){degree};
            else
                tau = 0;
            end
        end
    end
    
end