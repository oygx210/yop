classdef dynamic_optimization_variables < handle
    
    properties
        independent
        state
        algebraic
        control
        parameter
        arguments
    end
    
    methods
        
        function obj = dynamic_optimization_variables(independent, state, algebraic, control, parameter)
            obj.independent = independent;
            obj.state = state;
            obj.algebraic = algebraic;
            obj.control = control;
            obj.parameter = parameter;
            
            arguments = {};
            
            if ~isempty(independent)
                arguments = [arguments(:); {independent.evaluate}];
            end
            
            if ~isempty(state)
                arguments = [arguments(:); {state.evaluate}];
            end
            
            if ~isempty(algebraic)
                arguments = [arguments(:); {algebraic.evaluate}];
            end
            
            if ~isempty(control)
                arguments = [arguments(:); {control.evaluate}];
            end
            
            if ~isempty(parameter)
                arguments = [arguments(:); {parameter.evaluate}];
            end
            
            obj.arguments = arguments;
        end
        
    end
    
end