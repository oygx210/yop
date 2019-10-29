classdef constant < yop.node
    
    methods
        
        function obj = constant(name, size)
            if nargin == 0
                name = yop.keywords().default_name_constant;
                size = [1, 1];
                
            elseif nargin == 1
                size = [1, 1];
                
            end
            obj@yop.node(name, size);
        end
        
    end
end