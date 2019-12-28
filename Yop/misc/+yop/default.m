classdef default < handle
    properties
        node_rows
        node_columns
        nlp_variable_name
        constant_name
        variable_name
        independent_name
        independent_initial_name
        independent_final_name
        state_name
        algebraic_name
        control_name
        parameter_name
        lhs_name
        rhs_name
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
            obj.node_rows = 1;
            obj.node_columns = 1;
            obj.nlp_variable_name = "variable";
            obj.constant_name = "c";
            obj.variable_name = "v";            
            obj.independent_name = "t";
            obj.independent_initial_name = "t0";
            obj.independent_final_name = "tf";
            obj.state_name = "state";
            obj.algebraic_name = "algebraic";
            obj.control_name = "control";
            obj.parameter_name = "parameter";
            obj.lhs_name = "lhs";
            obj.rhs_name = "rhs";
        end
        
    end
end