classdef nlp_constraint < yop.relation
    
    methods
        
        function obj = nlp_constraint(relation)
            obj@yop.relation();
            if nargin == 1
                obj.init(relation);
            end
        end
        
        function obj = init(obj, relation)
            obj.init@yop.relation(relation.name, relation.size, relation.operation);
            prop = properties(relation);
            for k = 1:length(prop)
                obj.(prop{k}) = relation.(prop{k});
            end
        end
        
        function bool = isa_box(obj)
            % Tests if the following structure (r=relation, e=expression):
            %      r
            %     / \
            %    e1 e2
            % is a box constraint.
            % Notice that it doesn't test if the strucure is correct.
            bool = obj.left.isa_symbol && isa(obj.right, 'yop.constant') || ...
                isa(obj.left, 'yop.constant') && obj.right.isa_symbol;
        end
        
        function bool = isa_upper_bound(obj)
            % Tests if a box constraint is an upper bound that is:
            % test if the object is one of the following:
            %   v <= c
            %   c >= v
            bool = obj.isa_upper_type1 || obj.isa_upper_type2;
        end
        
        function bool = isa_upper_type1(obj)
            % test if it is a box constraint of the following type:
            %   variable <= constant
            bool = obj.isa_type1(obj) && ...
                (isequal(obj.operation, @lt) || isequal(obj.operation, @le));
        end
        
        function bool = isa_upper_type2(obj)
            % test if it is a box constraint of the following type:
            %    constant >= variable
            bool = obj.isa_type2 && ...
                (isequal(obj.operation, @gt) || isequal(obj.operation, @ge));
        end
        
        function bool = isa_lower_bound(obj)
            % Tests if a box constraint is an upper bound that is:
            % test if the object is one of the following:
            %   v >= c
            %   c <= v
            bool = obj.isa_lower_type1 || obj.isa_lower_type2;
        end
        
        function bool = isa_lower_type1(obj)
            % test if it is a box constraint of the following type:
            %   variable >= constant
            bool = obj.isa_type1 && ...
                (isequal(obj.operation, @gt) || isequal(obj.operation, @ge));
        end
        
        function bool = isa_lower_type2(obj)
            % test if it is a box constraint of the following type:
            %    constant <= variable
            bool = obj.isa_type2 && ...
                (isequal(obj.operation, @lt) || isequal(obj.operation, @le));
        end
        
        function bool = isa_equality(obj)
            % Tests if a box constraint is an upper bound that is:
            % test if the object is one of the following:
            %   v >= c
            %   c <= v
            bool = obj.isa_equality_type1 || obj.isa_equality_type2;
        end
        
        function bool = isa_equality_type1(obj)
            % test if it is a box constraint of the following type:
            %   variable == constant
            bool = obj.isa_type1 && isequal(obj.operation, @eq);
        end
        
        function bool = isa_equality_type2(obj)
            % test if it is a box constraint of the following type:
            %    constant == variable
            bool = obj.isa_type2(obj) && isequal(obj.operation, @eq);
        end
        
        function bool = isa_type1(obj)
            % test if it is a box constraint of the following type:
            %   varaible [relation] constant.
            %   example upper bound: v <= c
            %   example lower bound: v >= c
            bool = obj.isa_box(obj) && isa_symbol(obj.left) && ...
                isa(obj.right, 'yop.constant');
        end
        
        function bool = isa_type2(obj)
            % test if it is a box constraint of the following type:
            %   constant [relation] varaible.
            %   example lower bound: c <= v
            %   example upper bound: c >= v
            bool = obj.isa_box && ...
                isa(obj.left, 'yop.constant') && ...
                isa_symbol(obj.right);
        end
        
        function bd = get_bound(obj)
            if obj.isa_type1
                bd = obj.right;
                
            elseif obj.isa_type2(obj)
                bd = obj.left;
                
            else
                yop.assert(false);
                
            end
        end
        
        function bd = get_variable(obj)
            if obj.isa_type1(obj)
                bd = obj.left;
                
            elseif obj.isa_type2(obj)
                bd = obj.right;
                
            else
                yop.assert(false);
                
            end
        end
        
        function indices = get_indices(obj)
            % Follows the implementation in yop.subs_operation
            if obj.isa_type1(obj)
                indices = obj.left.get_indices();
                
            elseif obj.isa_type2(obj)
                indices = obj.right.get_indices();
                
            else
                yop.assert(false);
                
            end
        end
        
       function [box, equality, inequality] = classify(obj)
            % Classify the relations in obj into box constraints,
            % equality constraints, and inequality constraints.
            
            % Separate box and nonlinear (could be linear, but not box) 
            % constraints.
            [box, nl_con] = obj.split.convert_to_nlp_constraint.sort("first", ...
                @isa_box, ...
                @isa_valid_relation ...
                );
            
            % Put the nonlinear constraints on first general form i.e.
            % f(x) [relation] 0 and then on nlp form: g(x)==0, h(x)<=0.
            [equality, inequality] = nl_con.general_form.nlp_form.sort("first", ...
                @(x)isequal(x.operation, @eq), ...
                @(x)isequal(x.operation, @le));
            
       end
       
       function varargout = sort(obj, mode, varargin)
            varargout = cell(size(varargin));
            for n=1:length(varargout)
                varargout{n} = yop.nlp_constraint();
            end
            
            for k=1:length(obj)
                for c=1:length(varargin)
                    criteria = varargin{c};
                    if criteria(obj.object(k))                        
                        varargout{c}(end+1) = obj.object(k);
                        if mode=="first"
                            break
                        end
                    end
                end
            end
            
        end
       
    end
    
end