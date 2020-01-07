classdef independent < yop.variable
    methods
        function obj = independent(name)
            persistent t
            
            if nargin == 0
                name = yop.default().variable_name;
            end
            obj@yop.variable(name, 1, 1);
            
            if isempty(t)
                t = obj;
            else
                obj = t;    
            end
            
        end
    end
end