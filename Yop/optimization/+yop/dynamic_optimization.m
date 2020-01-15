classdef dynamic_optimization < yop.relation
    
    methods (Static)
        
        
        function [box, equality, inequality, differential] = classify(varargin)
            % Store all constraints in a list
            constraints = yop.node_list().add_array(varargin);
            
            % Separate box and general nonlinear constraints.
            [box, nl_con] = constraints.split.sort("first", ...
                @yop.nonlinear_programming.isa_box, ...
                @(x) isa_valid_relation(x) && ~yop.dynamic_optimization.dynamics(x) ...
                );
            
            % Put the nonlinear constraints on first general form i.e.
            % f(x) [relation] 0 and then on nlp form: g(x)==0, h(x)<=0.
            [equality, inequality] = nl_con.general_form.nlp_form.sort("first", ...
                @(x)isequal(x.operation, @eq), ...
                @(x)isequal(x.operation, @le));
            
            differential = constraints.split.sort("every", @yop.dynamic_optimization.dynamics);
        end
        
        function bool = isa_integral(expression)
            % Is the expression contained an integral?
            bool = isequal(expression.operation, @yop.integral);
        end
        
        function bool = isa_timepoint(expression)
            bool = ~isempty(expression.timepoint);
        end
        
        function bool = dynamics(constraint)
            % Does the constraint describe the system dynamics
            bool = isequal(constraint.operation, @eq) && ...
                (...
                isequal(constraint.left.operation, @yop.der) || ...
                isequal(constraint.right.operation, @yop.der) || ...
                isequal(constraint.left.operation, @yop.alg) || ...
                isequal(constraint.right.operation, @yop.alg) ...
                );
        end
        
    end
    
end