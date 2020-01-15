classdef optimization_variable < handle
    
    properties
        variable
        upper_bound
        lower_bound
        initial_upper_bound
        initial_lower_bound
        final_upper_bound
        final_lower_bound
    end
    
    methods
    
        function obj = optimization_variable(variable)
            obj.variable = variable;
        end
        
        function set_upper(obj, variable, value)
            obj.set_bound('upper_bound', variable, value);
        end
        
        function set_lower(obj, variable, value)
            obj.set_bound('lower_bound', variable, value);
        end
        
        function set_initial_upper(obj, variable, value)
            obj.set_bound('initial_upper_bound', variable, value);
        end
        
        function set_initial_lower(obj, variable, value)
            obj.set_bound('initial_lower_bound', variable, value);
        end
        
        function set_final_upper(obj, variable, value)
            obj.set_bound('final_upper_bound', variable, value);
        end
        
        function set_final_lower(obj, variable, value)
            obj.set_bound('final_lower_bound', variable, value);
        end
        
        function set_bound(obj, bound, variable, value)
            for k=1:length(obj)
                if isequal(obj.variable, variable)
                    obj.(bound) = value;
                end
            end
        end
        
    end
    
end