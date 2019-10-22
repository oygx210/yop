classdef variable < yop.node
    
    methods
        
        function obj = variable(name, rows, columns)
            if nargin == 0
                name = 'v';
                rows = 1;
                columns = 1;
                
            elseif nargin == 1
                rows = 1;
                columns = 1;
                
            elseif nargin == 2
                columns = 1;
                
            end
            obj@yop.node(name, rows, columns);
            obj.value = yop.variable.symbol(name, rows, columns);
        end
        
    end
    
    methods (Static)
        
        function v = symbol(name, rows, columns)       
            if yop.options.get_symbolics == yop.options.name_symbolic_math
                
                if rows==1 && columns==1
                    v = sym(name, 'real');
                else
                    v = sym(name, [rows, columns], 'real');
                end
                
            elseif yop.options.get_symbolics == yop.options.name_casadi
                v = casadi.MX.sym(name, rows, columns);
                
            end
        end
        
    end
end