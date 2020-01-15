classdef relation < yop.node
    methods
        function obj = relation(name, size, relation)
            obj@yop.node();
            if nargin > 0
                obj.init(name, size, relation);
            end
        end
        
        function obj = init(obj, name, size, relation)
            obj.init@yop.node(name, size(1), size(2));
            obj.operation = relation;
        end
        
        function obj = forward(obj)
            for n=1:length(obj)
                args = cell(size(obj(n).children));
                for k=1:size(args,2)
                    args{k} = obj(n).child(k).value;
                end
                obj(n).value = obj(n).operation(args{:});
            end
        end
        
        function graph = split(obj)
            % parsing the following structure
            %         r3
            %        / \
            %       r2  e4
            %      / \
            %     r1  e3
            %    /\
            %  e1 e2
            %
            % Splits into
            %   r1     r2     r3
            %  /  \   /  \   /  \
            % e1  e2 e2  e3 e3  e4
            %
            % e1 < e2 < e3 < e4 => {e1 < e2, e2 < e3, e3 < e4}
            for k=1:length(obj)
                if isa(obj(k), 'yop.relation') && ~isa(obj(k).left, 'yop.relation') && ~isa(obj(k).right, 'yop.relation')
                    % This is the end node.
                    graph_k = obj(k);
                    
                elseif isa(obj(k), 'yop.relation') && isa(obj(k).left, 'yop.relation') && ~isa(obj(k).right, 'yop.relation')
                    r = yop.relation(obj(k).name, size(obj(k)), obj(k).operation);
                    r.add_child(obj(k).left.right);
                    r.add_child(obj(k).right);
                    obj(k).left.right.add_parent(r);
                    graph_k = obj(k).left.split();
                    graph_k(end+1) = r;
                    
                else
                    yop.assert(false, yop.messages.graph_not_valid_relation);
                    
                end
                if k==1
                    graph = graph_k;
                else
                    graph = [graph, graph_k];
                end
            end
        end
        
        function r = general_form(obj)
            % changes the following form:
            %     r
            %    / \
            %   e1 e2
            % into:
            %      r
            %    /   \
            % e1-e2   0
            
            for k=1:length(obj)
                if ~isa(obj(k), 'yop.relation') || isa(obj(k).left, 'yop.relation') || isa(obj(k).right, 'yop.relation')
                    yop.assert(false, yop.messages.graph_not_simple);
                    
                else
                    if k == 1
                        r = obj(k).operation(obj(k).left-obj(k).right, 0);
                    else
                        r(k) = obj(k).operation(obj(k).left-obj(k).right, 0);
                    end
                end
            end
            
        end
        
    end
    
    methods % Constraints
        
        function r = nlp_form(obj)
            % If not on nlp form creates a new graph according to:
            %  e <  0  -->   e <= 0
            %  e <= 0   =    e <= 0
            %  e >  0  -->  -e <= 0
            %  e >= 0  -->  -e <= 0
            %  e == 0   =    e == 0
            
            for k=1:length(obj)
                if isequal(obj(k).operation, @lt)
                    if k==1
                        r = obj(k).left <= 0;
                    else
                        r(k) = obj(k).left <= 0;
                    end
                    
                elseif isequal(obj(k).operation, @gt) || isequal(obj(k).operation, @ge)
                    if k==1
                        r = -1*obj(k).left <= 0;
                    else
                        r(k) = -1*obj(k).left <= 0;
                    end
                    
                else
                    if k==1
                        r = obj(k);
                    else
                        r(k) = obj(k);
                    end
                    
                end
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
            bool = obj.isa_type1 && ...
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
            bool = obj.isa_type2 && isequal(obj.operation, @eq);
        end
        
        function bool = isa_type1(obj)
            % test if it is a box constraint of the following type:
            %   varaible [relation] constant.
            %   example upper bound: v <= c
            %   example lower bound: v >= c
            bool = obj.isa_box && obj.left.isa_symbol && ...
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
                
            elseif obj.isa_type2
                bd = obj.left;
                
            else
                yop.assert(false);
                
            end
        end
        
        function bd = get_variable(obj)
            if obj.isa_type1
                bd = obj.left;
                
            elseif obj.isa_type2
                bd = obj.right;
                
            else
                yop.assert(false);
                
            end
        end
        
        function indices = get_indices(obj)
            % Follows the implementation in yop.subs_operation
            if obj.isa_type1
                indices = obj.left.get_indices();
                
            elseif obj.isa_type2
                indices = obj.right.get_indices();
                
            else
                yop.assert(false);
                
            end
        end
        
        function bool = is_dynamics(obj)
            % Does the constraint describe the system dynamics
            bool = isequal(obj.operation, @eq) && ...
                (...
                isequal(obj.left.operation, @yop.der) || ...
                isequal(obj.right.operation, @yop.der) || ...
                isequal(obj.left.operation, @yop.alg) || ...
                isequal(obj.right.operation, @yop.alg) ...
                );
        end
        
        function bool = isa_integral(obj)
            % Is the expression contained an integral?
            bool = isequal(obj.operation, @yop.integral);
        end
        
        function [box, equality, inequality, dynamics] = classify(obj)
            % Classify the relations in obj into box constraints,
            % equality constraints, and inequality constraints.
            
            % Separate box and nonlinear (could be linear, but not box)
            % constraints.
            [box, dynamics, nl_con] = obj.split.sort("first", ...
                @isa_box, ...
                @is_dynamics, ...
                @(x) x.isa_valid_relation && ~x.is_dynamics ...
                );
            
            % Put the nonlinear constraints on first general form i.e.
            % f(x) [relation] 0 and then on nlp form: g(x)==0, h(x)<=0.
            if isempty(nl_con)
                equality = [];
                inequality = [];
                
            else
                [equality, inequality] = nl_con.general_form.nlp_form.sort("first", ...
                    @(x)isequal(x.operation, @eq), ...
                    @(x)isequal(x.operation, @le));
                
            end
            
        end
        
        function varargout = sort(obj, mode, varargin)
            varargout = cell(size(varargin));
            
            for k=1:length(obj)
                % For every constraint in object array obj
                
                for c=1:length(varargin)
                    % Test the criterias in varargin
                    criteria = varargin{c};
                    
                    if criteria(obj(k))
                        % Save if matches criteria
                        
                        if isempty(varargout(c))
                            varargout{c} = obj(k);
                        else
                            varargout{c}(end+1) = obj(k);
                        end
                        
                        if mode=="first"
                            break
                        end
                    end
                end
            end
        end
        
    end
    
    methods % Reset default changing behavior
        
        function y = horzcat(varargin)
            y = builtin('horzcat', varargin{:});
        end
        
        function y = vertcat(varargin)
            y = builtin('vertcat', varargin{:});
        end
        
        function s = size(varargin)
            s = builtin('size', varargin{:});
        end
        
        function varargout = subsref(x, s)
            [varargout{1:nargout}] = builtin('subsref', x, s);
        end
        
        function z = subsasgn(x, s, y)
            z = builtin('subsasgn', x, s, y);
        end
        
        function n = numArgumentsFromSubscript(obj, s, indexingContext)
            n = builtin('numArgumentsFromSubscript', obj, s, indexingContext);
        end
        
        function l = length(obj)
            l = builtin('length', obj);
        end
        
        function ind = end(obj, k, n)
            ind = builtin('end', obj, k, n);
        end
        
    end
    
end





















