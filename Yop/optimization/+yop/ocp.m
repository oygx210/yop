classdef ocp < handle
    
    properties
        independent
        independent_initial
        independent_final
        state
        algebraic
        control
        parameter
        
        % function calls
        arguments
        
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
            
            obj.independent         = ip.Results.(yop.default().independent_name);
            obj.independent_initial = ip.Results.(yop.default().independent_initial_name);
            obj.independent_final   = ip.Results.(yop.default().independent_final_name);
            obj.state               = ip.Results.(yop.default().state_name);
            obj.algebraic           = ip.Results.(yop.default().algebraic_name);
            obj.control             = ip.Results.(yop.default().control_name);
            parameter               = ip.Results.(yop.default().parameter_name);
            
            % parameters
            if isa(obj.independent_final, 'yop.parameter')
                parameter = [obj.independent_final; parameter];
            end
            
            if isa(obj.independent_initial, 'yop.parameter')
                parameter = [obj.independent_initial; parameter];
            end
            obj.parameter = parameter;
            
            
            % Function input arguments.
            % Överväg att flytta eftersom de skulle kunna hemmahöra i
            % transkriptorn
            arguments = {};
            
            if ~isempty(obj.independent)
                arguments = [arguments(:); {obj.independent.evaluate}];
            end
            
            if ~isempty(obj.state)
                arguments = [arguments(:); {obj.state.evaluate}];
            end
            
            if ~isempty(obj.algebraic)
                arguments = [arguments(:); {obj.algebraic.evaluate}];
            end
            
            if ~isempty(obj.control)
                arguments = [arguments(:); {obj.control.evaluate}];
            end
            
            if ~isempty(obj.parameter)
                arguments = [arguments(:); {obj.parameter.evaluate}];
            end
            
            obj.arguments = arguments;
            
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
        
    end
    
    methods
        
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








