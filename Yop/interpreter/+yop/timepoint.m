classdef timepoint < handle
    
    properties
        expression
        value
    end
    
    methods
        
        function obj = timepoint(expression)
            yop.assert(yop.timepoint.is_valid(expression), yop.messages.invalid_timepoint);
            obj.expression = expression;
        end
        
        function obj = parse_expression(obj, independent)
            % Parse the expression in order to get the specified timepoint
            if isa(obj.expression, 'yop.constant')
                obj.value = obj.expression.value;
                
            elseif isa(obj.expression, 'yop.parameter')
                obj.value = obj.expression;
                
            else
                if isequal(obj.expression.left, independent.variable)
                    if isa(obj.expression.right, 'yop.parameter')
                        obj.value = obj.expression.right;
                        
                    elseif isa(obj.expression.right, 'yop.constant')
                        obj.value = obj.expression.right.value;
                        
                    else
                        % A variable is used in the right branch, and that
                        % is not allowed.
                        yop.error(yop.messages.invalid_timepoint);
                        
                    end
                    
                else % isequal(obj.expression.right, independent.variable)
                    if isa(obj.expression.left, 'yop.parameter')
                        obj.value = obj.expression.left;
                        
                    elseif isa(obj.expression.left, 'yop.constant')
                        obj.value = obj.expression.left.value;
                        
                    else
                        % A variable is used in the right branch, and that
                        % is not allowed.
                        yop.error(yop.messages.invalid_timepoint);
                        
                    end
                end 
            end
        end
        
        function bool = is_initial(obj, independent)
            obj.parse_expression(independent);
            bool = isequal(obj.value, independent.lower_bound);
        end
        
        function bool = is_final(obj, independent)
            obj.parse_expression(independent);
            bool = isequal(obj.value, independent.upper_bound);
        end
        
    end
    
    methods (Static)
        
        function bool = is_valid(expression)
            % Test if the expression is one of the following
            %   1. yop.constant
            %   2. yop.parameter
            %   3. yop.relation, d==2, n==3, op==@eq
            % If any is fullfilled it is valid
            
            bool = ... 1.
                isa(expression, 'yop.constant') || ...
                ... 2.
                isa(expression, 'yop.parameter') || ...
                ... 3.
                (isa(expression, 'yop.relation') && ...
                 isequal(graph_size(expression), [2,3]) && ...
                 isequal(expression.operation, @eq) ...
                );
            
        end
        
    end
    
end