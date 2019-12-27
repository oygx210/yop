classdef variable < yop.node
    
    methods
        
        function obj = variable(name, varargin)
            if nargin == 0
                name = yop.keywords().default_name_variable;
            end
            obj@yop.node(name, varargin{:});
            obj.value = yop.variable.symbol(name, size(obj));
        end
        
        function indices = get_indices(obj)
            % Returns the indices in the vector variable
            % Observe that it doesn't test if it is a vector valued
            % variable or scalar.
            indices = 1:length(obj);
        end
        
    end
    
    methods (Static)
        
        function v = symbol(name, size)
            if yop.options.get_symbolics == yop.options.name_symbolic_math
                
                if isequal(size, [1,1])
                    v = sym(name, 'real');
                else
                    v = sym(name, size, 'real');
                end
                
            elseif yop.options.get_symbolics == yop.options.name_casadi
                v = casadi.MX.sym(name, size(1), size(2));
                
            end
        end
        
    end
end