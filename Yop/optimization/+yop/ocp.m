classdef ocp < handle
    
    properties
        independent
        independent_initial
        independent_final
        state
        algebraic
        control
        parameter
        
        % Objective and constraints
        objective
        objective_function
        constraints
        
        % Box constraints
        
        % Path constraints
        %  equality, inequality
    end
    
    methods
        
        function obj = ocp(varargin)
            
            ip = inputParser;
            ip.FunctionName = 'ocp';
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
            
            obj.independent.variable         = ip.Results.(yop.default().independent_name);
            obj.independent_initial.variable = ip.Results.(yop.default().independent_initial_name);
            obj.independent_final.variable   = ip.Results.(yop.default().independent_final_name);
            obj.state.variable               = ip.Results.(yop.default().state_name);
            obj.algebraic.variable           = ip.Results.(yop.default().algebraic_name);
            obj.control.variable             = ip.Results.(yop.default().control_name);
            obj.parameter.variable           = ip.Results.(yop.default().parameter_name);
            
            obj.independent_initial.upper_bound = inf;
            obj.independent_initial.lower_bound = -inf;
            
            obj.independent_final.upper_bound = inf;
            obj.independent_final.lower_bound = -inf;
            
            obj.state.upper_bound = inf(size(obj.state.variable));
            obj.state.lower_bound = -inf(size(obj.state.variable));
            obj.state.initial_upper_bound = inf(size(obj.state.variable));
            obj.state.initial_lower_bound = -inf(size(obj.state.variable));
            obj.state.final_upper_bound = inf(size(obj.state.variable));
            obj.state.final_lower_bound = -inf(size(obj.state.variable));
            
            obj.algebraic.upper_bound = inf(size(obj.algebraic.variable));
            obj.algebraic.lower_bound = -inf(size(obj.algebraic.variable));
            
            obj.control.upper_bound = inf(size(obj.control.variable));
            obj.control.lower_bound = -inf(size(obj.control.variable));
            obj.control.initial_upper_bound = inf(size(obj.control.variable));
            obj.control.initial_lower_bound = -inf(size(obj.control.variable));
            obj.control.final_upper_bound = inf(size(obj.control.variable));
            obj.control.final_lower_bound = -inf(size(obj.control.variable));
            
            obj.parameter.upper_bound = inf(size(obj.parameter.variable));
            obj.parameter.lower_bound = -inf(size(obj.parameter.variable));
            
        end
        
        function obj = minimize(obj, expression)
            obj.objective = 'minimize';
            obj.objective_function = expression;
        end
        
        function obj = maximize(obj, expression)
            obj.objective = 'maximize';
            obj.objective_function = -expression;
        end
        
        function obj = subject_to(obj, varargin)
            obj.constraints = varargin;
        end
        
        function n_x = states(obj)
            n_x = length(obj.state);
        end
        
        function n_z = algebraics(obj)
            n_z = length(obj.algebraic);
        end
        
        function n_c = controls(obj)
            n_c = length(obj.control);
        end
        
        function n_p = parameters(obj)
            n_p = length(obj.parameter);
        end
        
    end
    
end








