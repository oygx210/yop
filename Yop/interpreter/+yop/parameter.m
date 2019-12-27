classdef parameter < yop.variable
    methods
        function obj = parameter(name, varargin)
            if nargin == 0
                name = yop.default().parameter_name;
            end
            obj@yop.variable(name, varargin{:});
        end
    end
end