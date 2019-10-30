classdef dynamic_optimization < yop.relation
    
    methods (Static)
        
        function bool = dynamics(constraint)
            % Does the constraint describe the system dynamics
            bool = isequal(constraint.operation, @eq) && ...
                (...
                isequal(constraint.left.operation, @der) || ...
                isequal(constraint.right.operation, @der) || ...
                isequal(constraint.left.operation, @alg) || ...
                isequal(constraint.right.operation, @alg) ...
                );
        end
        
    end
    
end