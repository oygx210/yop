classdef dynamic_optimization < yop.relation
    
    methods (Static)
        
        function [box, equality, inequality, differential] = classify(varargin)
            constraints = yop.node_list().add_array(varargin);
            [box, equality, inequality] = yop.nonlinear_programming.classify(varargin{:});
            differential = constraints.split.sort("every", @yop.dynamic_optimization.dynamics);
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
        
        function bool = isa_type1(relation)
            % test if it is a relation of the following type:
            %   varaible [relation] constant.
            %   example upper bound: t == c
            %   example lower bound: t == c
            bool = yop.nonlinear_programming.isa_box(relation) && ...
                is_independent(relation.left) && ...
                (isa_symbol(relation.right) || isa(relation.right, 'yop.constant'));
        end
        
        function bool = isa_type2(relation)
            % test if it is a relation of the following type:
            %   constant [relation] varaible.
            %   example lower bound: c <= v
            %   example upper bound: c >= v
            bool = yop.nonlinear_programming.isa_box(relation) && ...
                isa(relation.left, 'yop.constant') && ...
                isa_symbol(relation.right);
        end
        
    end
    
end