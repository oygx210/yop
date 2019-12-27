classdef default < handle
    properties
        variable
        constant_name
        variable_name
        parameter_name
        lhs_name
        rhs_name
        node_rows
        node_columns
    end
    methods
        
        function obj = default()
            persistent singleton
            if isempty(singleton)
                singleton = obj;
                singleton.set_default();
            else
                obj = singleton;
            end
        end
        
        function obj = set_default(obj)
            obj.variable = 'variable';
            obj.constant_name = 'c';
            obj.variable_name = 'v';
            obj.parameter_name = 'p';
            obj.lhs_name = 'lhs';
            obj.rhs_name = 'rhs';
            obj.node_rows = 1;
            obj.node_columns = 1;
        end
        
    end
end