classdef optimization_problem < handle
    properties
        independent
        independent_initial
        independent_final
        state
        algebraic
        control
        parameter
        objective
        constraints
    end
    methods
        function obj = optimization_problem(varargin)
            % Överväg att flytta ut konstruktorn och beroende på input
            % instansiera olika klasser beroende på vilken typ av
            % optimeringsproblem det är.
            ip = inputParser;
            ip.FunctionName = 'optimization_problem';
            ip.PartialMatching = false;
            ip.KeepUnmatched = false;
            ip.CaseSensitive = true;
            
            ip.addParameter(yop.default().independent_name, []);
            ip.addParameter(yop.default().independent_initial_name, []);
            ip.addParameter(yop.default().independent_final_name, []);
            ip.addParameter(yop.default().state_name, []);
            ip.addParameter(yop.default().algebraic_name, []);
            ip.addParameter(yop.default().control_name, []);
            ip.addParameter(yop.default().parameter_name, []);
            
            ip.parse(varargin{:});
            
            obj.independent = ip.Results.(yop.default().independent_name);
            obj.independent_initial = yop.node.typecast(ip.Results.(yop.default().independent_initial_name));
            obj.independent_final = yop.node.typecast(ip.Results.(yop.default().independent_final_name));
            obj.state = ip.Results.(yop.default().state_name);
            obj.algebraic = ip.Results.(yop.default().algebraic_name);
            obj.control = ip.Results.(yop.default().control_name);
            obj.parameter = ip.Results.(yop.default().parameter_name);
        end
        
        function obj = minimize(obj, expression)
            obj.objective = expression;
        end
        
        function obj = maximize(obj, expression)
            obj.minimize(-expression);
        end
        
        function obj = subject_to(obj, varargin)
            obj.constraints = varargin;
        end
        
        function t = tf(obj)
            t = obj.independent_final.evaluate;
        end
        
        function t = t0(obj)
            t = obj.independent_initial.evaluate;
        end
        
    end
end