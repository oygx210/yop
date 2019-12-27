classdef constant < yop.node    
    methods
        function obj = constant(name, varargin)
            if nargin == 0
                name = yop.default().constant_name;
            end
            obj@yop.node(name, varargin{:});
        end
    end
end