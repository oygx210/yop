classdef nonlinear_program < handle
    properties
        variable
        upper_bound
        lower_bound
        objective
        equality_constraints
        inequality_constraints
    end
    methods
        function obj = nonlinear_program(varargin)
            ip = inputParser;
            ip.FunctionName = 'nonlinear_program';
            ip.PartialMatching = false;
            ip.KeepUnmatched = false;
            ip.CaseSensitive = true;
            
            ip.addParameter(yop.default().nlp_variable_name, []);
            ip.parse(varargin{:})
            
            yop.assert(~isempty(ip.Results.variable), ...
                yop.messages.optimization_variable_missing);
            
            yop.assert(size(ip.Results.variable,2)==1, ...
                yop.messages.optimization_not_column_vector);
            
            obj.variable = ip.Results.(yop.default().nlp_variable_name);
            obj.upper_bound = yop.node('ub', size(obj.variable));
            obj.lower_bound = yop.node('lb', size(obj.variable));
            obj.upper_bound.value =  inf(size(obj.variable));
            obj.lower_bound.value = -inf(size(obj.variable));
        end
        
        function present(obj)
            % Alt överlagra disp/display.
        end
        
        function obj = minimize(obj, f)
            obj.objective = f;
        end
        
        function obj = maximize(obj, f)
            obj.objective = -f;
        end
        
        function obj = subject_to(obj, varargin)
            
            [box, eq, ieq] = vertcat(varargin{:}).classify();
            obj.add_box(box);
            
            if ~isempty(eq)
                obj.equality_constraints = eq.left.evaluate;
            end
            
            if ~isempty(ieq)
                obj.inequality_constraints = ieq.left.evaluate;
            end
        end
        
        function obj = add_box(obj, box)
            for k=1:length(box)
                index = box(k).get_indices();
                bd = box(k).get_bound;
                
                if box(k).isa_upper_bound
                    obj.upper_bound(index) = bd;
                    
                elseif box(k).isa_lower_bound
                    obj.lower_bound(index) = bd;
                    
                elseif box(k).isa_equality  
                    obj.upper_bound(index) = bd;
                    obj.lower_bound(index) = bd;
                end
            end
        end
        
        function results = solve(obj, x0)
            ip = inputParser;
            ip.FunctionName = 'nonlinear_program.solve';
            ip.PartialMatching = false;
            ip.KeepUnmatched = false;
            ip.CaseSensitive = true;
            
            nlp = struct;
            nlp.x = obj.variable.evaluate;
            nlp.f = obj.objective.evaluate;
            nlp.g = [...
                obj.equality_constraints; ...
                obj.inequality_constraints ...
                ];
            
            yoptimizer = casadi.nlpsol('yoptimizer', 'ipopt', nlp);
            res = yoptimizer( ...
                'x0', x0, ...
                'ubx', obj.upper_bound.evaluate, ...
                'lbx', obj.lower_bound.evaluate, ...
                'ubg', [zeros(size(obj.equality_constraints)); zeros(size(obj.inequality_constraints))], ...
                'lbg', [zeros(size(obj.equality_constraints)); -inf(size(obj.inequality_constraints))]);
            results = full(res.x);
            
        end
        
    end
end