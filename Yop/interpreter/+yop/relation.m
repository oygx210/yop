classdef relation < yop.node
    methods
        function obj = relation(name, size, relation)
            obj@yop.node(name, size);
            obj.operation = relation;
        end
        
        function obj = forward(obj)
            args = cell(size(obj.children));
            for k=1:size(args,2)
                args{k} = obj.child(k).value;
            end
            obj.value = obj.operation(args{:});
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
            
            if isa(obj, 'yop.relation') && ~isa(obj.left, 'yop.relation') && ~isa(obj.right, 'yop.relation')
                % This is the end node.
                graph = yop.node_list().add(obj);
                
            elseif isa(obj, 'yop.relation') && isa(obj.left, 'yop.relation') && ~isa(obj.right, 'yop.relation')
                r = yop.relation(obj.name, size(obj), obj.operation);
                r.add_child(obj.left.right);
                r.add_child(obj.right);
                obj.left.right.add_parent(r);
                graph = obj.left.split.add(r);
                
            else
                yop.assert(false, yop.messages.graph_not_valid_relation);
                
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
            %
            
            if ~isa(obj, 'yop.relation') || isa(obj.left, 'yop.relation') || isa(obj.right, 'yop.relation')
                yop.assert(false, yop.messages.graph_not_simple);
                
            else
                r = obj.operation(obj.left-obj.right, 0);
                
            end
            
        end
        
        function r = nlp_form(obj)
            % If not on nlp form creates a new graph according to: 
            %  e <  0  -->   e <= 0
            %  e <= 0   =    e <= 0
            %  e >  0  -->  -e <= 0
            %  e >= 0  -->  -e <= 0
            %  e == 0   =    e == 0
            if isequal(obj.operation, @lt)
                r = obj.left <= 0;
                
            elseif isequal(obj.operation, @gt) || isequal(obj.operation, @ge)
                r = -1*obj.left <= 0;
                
            else
                r = obj;
                
            end                
        end
        
        function y = horzcat(varargin)
            y = builtin('horzcat', varargin{:});
        end
        
        function y = vertcat(varargin)
            y = builtin('vertcat', varargin{:});
        end
        
        function s = size(varargin)
            s = builtin('size', varargin{:});
        end
        
    end
    
end





















