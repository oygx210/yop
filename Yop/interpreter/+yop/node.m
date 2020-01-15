classdef node < handle
    % NODE A class for creating nodes in computational graphs.
    %    Node is the basic building block for creating computaional grapwhs
    %    in Yop. The computional graphs are used for formulating
    %    optimization problems and manipulating them into a form that can
    %    be handled by optimization solvers. Three classes are used to
    %    formulate expressions: 'yop.variable', 'yop.parameter' and 
    %    'yop.constant'. By operator overloading, normal Matlab operations 
    %    are used in to writh expressions, which when evaluated form a 
    %    computational graph that Yop can interpret. The implementation is
    %    inspired by how computational graphs can be used to calculate
    %    derivatives. Evaluation is carried out in forward mode, but no
    %    derivatives are calculated. Instead, that is handled by the
    %    symbolic framework used by Yop.
    %
    % -- Properties --
    %    name : Name of the node.
    %
    %    operation : Operation associated with node.
    %    
    %    timepoint : Timepoint associated with node.
    %
    % -- Properties (SetObservable, AbortSet) --
    %    value : Value of node when evaluated. Listens to changes in
    %            underlying computational graph. If changes are made in the
    %            rest of the graph causing a need to recompute, the value
    %            is deleted. Otherwise, the node gives back the stored
    %            value in order to avoid recomputation.
    %
    % -- Properties (SetAccess=protected) --
    %    rows : The number of rows.
    %
    %    columns : The number of columns.
    %
    %    parents : Parents of the node. I.e. node taking it as input.
    %              Protected because it has an associated listener, used to
    %              avoid reevaluation of the graph.
    %
    %    children : Children of the node. I.e. input nodes.
    %
    % -- Properties (SetAccess=private, GetAccess=private) --
    %    eval_order : Order in which the rest of the nodes in the graph
    %                 needs to be computed in order to evaluate this node.
    %
    % -- Methods --
    %    obj = node(name, varargin) : Class constructor.
    %
    %    p = parent(obj, index) : Returns parent with index 'index'.
    %
    %    c = child(obj, index) : Returns child with index 'index'.
    %
    %    obj = add_parent(obj, parent) : Add 'parent' to parent list.
    %
    %    obj = remove_parent(obj, parent) : Remove parent from list.
    %
    %    obj = add_child(obj, child) : Add 'child' to child list.
    %
    %    obj = remove_child(obj, child) : Remove from child list.
    %
    %    obj = clear(obj, ~, ~) : Clear the node value.
    %
    %    obj = set_value(obj, value) : Set the node value.
    %
    %    obj = forward(obj) : Forward evaluation.
    %
    %    bool = isa_leaf(obj) : Tests if node is a leaf.
    %
    %    bool = isa_valid_relation(obj) : Tests if relations in the node
    %                                     follow allowed syntax.
    %
    %    bool = isa_symbol(obj) : Tests if node is a 'yop.variable' or an
    %                             element of such a variable.
    %
    %    l = left(obj) : First child of node.
    %
    %    r = right(obj) : Second child of node.
    %
    %    l = leftmost(obj) : Leftmost child in the graph.
    %
    %    r = rightmost(obj) : Rightmost child in the graph.
    %
    % -- Methods (Default changing behavior) --
    %    s = size(obj, dim) : Size of node when evaluated.
    %    
    %    l = length(obj) : length of node when evaluated.
    %    
    %    ind = end(obj,k,n) : Last element of indexation.
    %
    %    n = numArgumentsFromSubscript(obj, s, indexingContext) : Number of
    %                     object array elements used in indexing operation.
    %    
    %    y = subsref(x, s) : Behavs like normal subsref except for
    %                        subreferencing elements or specifying
    %                        timepoints for constraints.
    %
    %    z = subsasgn(x, s, y) : When assigning to subelements creates a
    %                            node, otherwist like builtin.
    %
    %    y = horzcat(varargin) : Horizontal concatenation.
    %
    %    y = vertcat(varargin) : Vertical concatenation.
    %
    % -- Methods (Computational graph specific) --
    %    obj = order_nodes(obj) : Orders nodes in graph for forward
    %                             evaluation.
    %
    %    [depth, nodes] = graph_size(obj) : Calculates graph depth and the
    %                                       number of nodes.
    %
    %     value = evaluate(obj) : Evaluate the computaional graph
    %                             associated with the node.
    %
    % -- Methods (Operator overloading) --
    %    z = plus(x, y) : x + y.
    %
    %    z = minus(x, y) : x - y.
    %
    %    y = uplus(x) : +x.
    %
    %    y = uminus(x) : -x.
    %
    %    z = times(x, y) : x.*y.
    %
    %    z = mtimes(x, y) : x*y.
    %
    %    z = rdivide(x, y) : x./y.
    %
    %    z = ldivide(x, y) : x.\y.
    %
    %    z = mrdivide(x, y) : x/y.
    %
    %    z = mldivide(x, y) : x\y.
    %
    %    z = power(x, y) : x.^y.
    %
    %    z = mpower(x, y) : x^y.
    %
    %    y = exp(x) : Exponential.
    %
    %    y = expm(x) : Matrix exponential.
    %
    %    y = ctranspose(x) : Complex conjugate transpose x'.
    %
    %    y = transpose(x) : Transpose x.'.
    %
    %    y = sign(x) : Sign of x.
    %
    %    z = dot(x, y) : Dot product of x and y.
    %
    %    y = integral(x) : Integral of x.
    %
    %    y = integrate(x) : Wrapper for 'integral()'.
    %
    %    y = der(x) : Timederivative of x.
    %
    %    y = alg(x) : Indication of algebraic equation.
    %
    %    r = lt(lhs, rhs) : lhs < rhs.
    %
    %    r = gt(lhs, rhs) : lhs > rhs.
    %
    %    r = le(lhs, rhs) : lhs <= rhs.
    %
    %    r = ge(lhs, rhs) : lhs >= rhs.
    %
    %    r = ne(lhs, rhs) : lhs ~= rhs.
    %
    %    r = eq(lhs, rhs) : lhs == rhs.
    %
    %    r = reshape(A, varargin) : Reshape.
    %
    % -- Methods (Static) --
    %    v = typecast(v) : Typecast numerics into 'yop.constant'.
    %
    %    bool = compatible(x, y) : Check if x and y and Matlab 2D
    %                              compatible.
    %
    
    properties
        name % Name of the node.
        operation % operation possibly associated with node.
        timepoint
    end
    
    properties (SetObservable, AbortSet)
        value % Value associated with node.
    end
    
    properties (SetAccess=protected)
        rows    % Number of rows.
        columns % Number of columns.
        parents  % Parent nodes. Is proteced beacuse it uses a listener.
        children % Child nodes.
    end
    
    properties (SetAccess=private, GetAccess=private)
        eval_order
    end
    
    methods
        
        function obj = node(name, varargin)
            % YOP.NODE - creates a node
            % obj = yop.node(name)
            % obj = yop.node(name, size)
            % obj = yop.node(name, rows)
            % obj = yop.node(name, rows, columns)
            
            if nargin == 1
                rows = yop.default().node_rows;
                columns = yop.default().node_columns;
                
            elseif nargin == 2
                if isequal(size(varargin{1}), [1,2])
                    rows = varargin{1}(1);
                    columns = varargin{1}(2);
                    
                else
                    rows = varargin{1};
                    columns = yop.default().node_columns;
                    
                end
                
            elseif nargin == 3
                rows = varargin{1};
                columns = varargin{2};
                
                
            else
                yop.assert(false);
                
            end
            
            obj.name = name;
            obj.rows = rows;
            obj.columns = columns;
            obj.parents = yop.node_listener_list();
            obj.children = yop.list();
        end
        
        function p = parent(obj, index)
            % PARENT Get parent at position 'index' in the parent list.
            p = obj.parents.object(index);
        end
        
        function c = child(obj, index)
            % CHILD Get child at postion 'index' in the child list.
            c = obj.children.object(index);
        end
        
        function obj = add_parent(obj, parent)
            % ADD_PARENT Add parent to the parent list.
            %    Uses a special type of list to also manage a listener that
            %    monitors the value property. If The value is changed to a
            %    different value, it clears the values of its parents. This
            %    is used to avoid recomputation, as only parts of a graph
            %    that are affected by a change of a certain input value
            %    needs to be recomputed.
            listener = addlistener(obj, 'value', 'PostSet', @parent.clear);
            obj.parents.add(parent, listener);
            parent.value = [];
        end
        
        function obj = remove_parent(obj, parent)
            % REMOVE_PARENT Remove a parent from the parent list.
            obj.parents.remove(parent);
        end
        
        function obj = add_child(obj, child)
            % ADD_CHILD Add a child to the child list.
            obj.children.add(child);
        end
        
        function obj = remove_child(obj, child)
            % REMOVE_CHILD Remove a child from the child list.
            obj.children.remove(child);
        end
        
        function obj = clear(obj, ~, ~)
            % CLEAR Clear the value property. 
            %    Empty args required by callback interface.
            if isvalid(obj)
                obj.value = [];
            end
        end
        
        function obj = set_value(obj, value)
            % SET_VALUE Set the value property.
            obj.value = value;
        end
        
        function obj = forward(obj)
            % FORWARD Forward evaluation of node.
            %    Needs to be overloaded in classes that are used for 
            %    operations.
        end
        
        function bool = isa_leaf(obj)
            % ISA_LEAF Tests if node is a leaf.
            bool = isa(obj, 'yop.variable') || isa(obj, 'yop.constant');
        end
        
        function bool = isa_valid_relation(obj)
            % ISA_VALID_RELATION Test if relations are input in an
            %                    acceptable way.
            % Tests for the following structure where r is a relation and e
            % is an expression, e.g. e1 <= e2 <= ... <= eN
            %         r
            %        / \
            %       r   e
            %      / \
            %     r   e
            %    /\
            %   e  e
            % This is not valid: e1 <= (e2 <= e3) as the 'direction' is the
            % opposite.
            if isa(obj, 'yop.relation') && ...
                    ~isa(obj.left, 'yop.relation') && ...
                    ~isa(obj.right, 'yop.relation')
                % This is the end node.
                bool = true;
                
            elseif isa(obj, 'yop.relation') && ...
                    isa(obj.left, 'yop.relation') && ...
                    ~isa(obj.right,'yop.relation')
                bool = obj.left.isa_valid_relation();
                
            else
                bool = false;
                
            end
            
        end
        
        function bool = isa_symbol(obj)
            % ISA_SYMBOL Test if the node is a 'yop.variable',
            %    'yop.parameter' or an element of one.
            if isa(obj, 'yop.variable')
                bool = true;
                
            elseif ~isa(obj, 'yop.subs_operation')
                bool = false;
                
            else % has to be a subs_operation and therefore it's
                % sufficient to look at the first argument and see if that
                % tree only containts variables or subs_operations
                bool = obj.child(1).isa_symbol();
                
            end
        end
        
        function l = left(obj)
            % LEFT First child of node.
            l = obj.child(1);
        end
        
        function r = right(obj)
            % RIGHT Second child of node.
            r = obj.child(2);
        end
        
        function l = leftmost(obj)
            % LEFTMOST Leftmost child in graph.
            if isa_symbol(obj)
                l = obj;
            else
                l = obj.left.leftmost();
            end
        end
        
        function r = rightmost(obj)
            % RIGHTMOST Righmost child in graph.
            if isa_symbol(obj)
                r = obj;
            else
                r = obj.right.rightmost();
            end
        end
        
        
        
    end
    
    methods % Default changing behavior
        
        function s = size(obj, dim)
            % SIZE Size of node when graph is evaluated.
            if nargin == 2
                if dim == 1
                    s = obj.rows;
                elseif dim == 2
                    s = obj.columns;
                else
                    yop.assert(false, yop.messages.error_size(dim))
                end
            else
                s = [obj.rows, obj.columns];
            end
        end
        
        function l = length(obj)
            % LENGTH Length of node when graph is evaluated.
            l = max(size(obj));
        end
        
        function ind = end(obj,k,n)
            % END Last element in indexation.
            szd = size(obj);
            if k < n
                ind = szd(k);
            else
                ind = prod(szd(k:end));
            end
        end
        
        
        function n = numArgumentsFromSubscript(obj, s, indexingContext)
            % NUMARGUMENTSFROMSUBSCRIPT
            % Numbers of object array elements used in a subs operation.
            % Somewhat rudimentary implemented. Might be buggy, not checked 
            % for all cases.
            n=1;            
        end
        
        function y = subsref(x, s)
            % SUBSREF Used to add functionality for specifying timepoints
            % using the syntax x(t==0), and accessing subelements of
            % matrix. Otherwise behaves like builtin.
            %
            % Specialfall
            %   - element i matris
            %   - tidpunkt eller index
            
            % x(1) + 2
            % x(t==0)
            % x(1).add(2) två anrop, x(1), add(2)
            % x(1).evaluate
            
            switch s(1).type
                case '.'
                    y = builtin('subsref', x, s);
                    
                case '()'
                    if isnumeric(s(1).subs{1}) || strcmp(s(1).subs{1}, ':')
                        % Implements obj(index)
                        
                        tmp = ones(size(x));
                        tmp = tmp(builtin('subsref', tmp, s(1)));
                        
                        txt = [x.name '(' num2str(s(1).subs{1}) ')'];
                        y = yop.subs_operation(txt, size(tmp), @subsref);
                        
                        s_yop = yop.constant('s', [1, 1]);
                        s_yop.value = s(1);
                        
                        y.add_child(x);
                        y.add_child(s_yop);
                        x.add_parent(y);
                        s_yop.add_parent(y);
                        
                        if length(s) > 1
                            y = subsref(y, s(2:end));
                        end
                        
                    elseif isa(s(1).subs{1}, 'yop.node')
                        % Implements obj(t), obj(t==1), obj(1==t)
                                           
                        % Logik för timepoints:
                        % Antingen är det en:
                        %   1. yop.parameter
                        %   2. numeric
                        %   3. yop.variable = yop.constant/yop.parameter
                        x.timepoint = yop.timepoint(s(1).subs{1});
                        y = x;
                        
                        if length(s) > 1
                            y = subsref(y, s(2:end));
                        end
                        
                    else
                        % Use built-in for any other expression
                        y = builtin('subsref', x, s);
                    end
                    
                case '{}'
                    y = builtin('subsref', x, s);
                    
                otherwise
                    error('Not a valid indexing expression')
            end
            
            % Ta hand om nästa nivå.
            % Om det finns rest ska enbart det första i varargout ges som
            % input. Om ingen rest finns ska allt returneras.
        end
        
        
        %         function y = subsref(x, s)
        %             if s(1).type == "()" && (isnumeric(s(1).subs{1}) || strcmp(s(1).subs{1},':'))
        %                 tmp = ones(size(x));
        %                 tmp = tmp(builtin('subsref', tmp, s));
        %
        %                 txt = [x.name '(' num2str(s(1).subs{1}) ')'];
        %                 y = yop.subs_operation(txt, size(tmp), @subsref);
        %
        %                 s_yop = yop.constant('s', [1, 1]);
        %                 s_yop.value = s(1);
        %
        %                 y.add_child(x);
        %                 y.add_child(s_yop);
        %                 x.add_parent(y);
        %                 s_yop.add_parent(y);
        %
        %                 if length(s) > 1
        %                     y = subsref(y, s(2:end));
        %                 end
        %             else
        %                 y = builtin('subsref', x, s);
        %             end
        %         end
        
        function z = subsasgn(x, s, y)
            % SUBSASGN Assign to subelement. Overloaded when assigning to
            % matrices.
            if s(1).type == "()" && isnumeric(s(1).subs{1})
                y = yop.node.typecast(y);
                
                z = yop.subs_operation(x.name, size(x), @subsasgn);
                
                s_yop = yop.constant('s', [1, 1]);
                s_yop.value = s(1);
                
                z.add_child(x);
                z.add_child(s_yop);
                z.add_child(y);
                x.add_parent(z);
                s_yop.add_parent(z);
                y.add_parent(z);
            else
                z = builtin('subsasgn',x, s, y);
            end
        end
        
        function y = horzcat(varargin)
            % HORZCAT Horizontal concatenation.
            args = varargin(~cellfun('isempty', varargin));
            args = cellfun(@yop.node.typecast, args, 'UniformOutput', false);
            
            yop.assert(all(cellfun('size', args, 1)), ...
                yop.messages.incompatible_size('horzcat', args{1}, args{end}));
            
            sz = [size(args{1},1), sum(cellfun(@(x) size(x,2), args))];
            y = yop.operation('horzcat', sz, @horzcat);
            
            for k=1:length(args)
                y.add_child(args{k});
                args{k}.add_parent(y);
            end
            
            yop.debug.validate_size(y, @horzcat, varargin{:});
        end
        
        function y = vertcat(varargin)
            % VERTCAT Vertical concatenation.
            args = varargin(~cellfun('isempty', varargin));
            args = cellfun(@yop.node.typecast, args, 'UniformOutput', false);
            
            yop.assert(all(cellfun('size', args, 2)), ...
                yop.messages.incompatible_size('vertcat', args{1}, args{end}));
            
            sz = [sum(cellfun(@(x) size(x,1), args)), size(args{1}, 2)];
            y = yop.operation('vertcat', sz, @vertcat);
            
            for k=1:length(args)
                y.add_child(args{k});
                args{k}.add_parent(y);
            end
            
            yop.debug.validate_size(y, @vertcat, varargin{:});
        end
        
    end
    
    methods % Computational graph
        
        function obj = order_nodes(obj)
            % ORDER_NODES Order nodes for forward evaluation.
            visited = yop.list();
            ordering = yop.list();
            
            function recursion(node)
                if isa(node, 'yop.operation') || isa(node, 'yop.relation')
                    for k=1:length(node.children)
                        if ~visited.contains(node.child(k))
                            recursion(node.child(k));
                        end
                    end
                end
                visited.add_unique(node);
                ordering.add_unique(node);
            end
            
            recursion(obj);
            obj.eval_order = ordering;
        end
        
        function size = graph_size(obj)
            % GRAPH_SIZE Compute the depth and number of nodes of the
            % graph.
            visited = yop.list;
            function d = recursion(node)
                d = 1;
                for k=1:length(node.children)
                    if ~visited.contains(node.child(k))
                        d_k = 1 + recursion(node.child(k));
                        if d_k > d
                            d = d_k;
                        end
                    end
                end
                visited.add_unique(node);
            end
            depth = recursion(obj);
            nodes = length(visited);
            size = [depth, nodes];
        end
        
        function d = depth(obj)
            d = graph_size(obj);
        end
        
        function value = evaluate(obj)
            % EVALUATE Evaluate graph in forward mode.
            if isempty(obj.eval_order)
                obj.order_nodes();
            end
            for k=1:length(obj.eval_order)
                obj.eval_order.object(k).forward();
            end
            value = obj.value;
        end
        
        function obj = at(obj, timepoint)
            obj.timepoint = timepoint;
        end
    end
    
    methods % ool
        
        function z = plus(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            yop.assert(yop.node.compatible(x, y), ...
                yop.messages.incompatible_size('+', x, y));
            
            z_rows = max(size(x, 1), size(y, 1));
            z_cols = max(size(x, 2), size(y, 2));
            
            z = yop.operation('plus', [z_rows, z_cols], @plus);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @plus, x, y);
        end
        
        function z = minus(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            yop.assert(yop.node.compatible(x, y), ...
                yop.messages.incompatible_size('-', x, y));
            
            z_rows = max(size(x,1), size(y,1));
            z_cols = max(size(x,2), size(y,2));
            
            z = yop.operation('minus', [z_rows, z_cols], @minus);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @minus, x, y);
        end
        
        function y = uplus(x)
            y = yop.operation('uplus', size(x), @uplus);
            y.add_child(x);
            x.add_parent(y);
            
            yop.debug.validate_size(y, @uplus, x);
        end
        
        function y = uminus(x)
            y = yop.operation('uminus', size(x), @uminus);
            y.add_child(x);
            x.add_parent(y);
            
            yop.debug.validate_size(y, @uminus, x);
        end
        
        function z = times(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            yop.assert(yop.node.compatible(x, y), ...
                yop.messages.incompatible_size('.*', x, y));
            
            z_rows = max(size(x, 1), size(y, 1));
            z_cols = max(size(x, 2), size(y, 2));
            
            z = yop.operation('times', [z_rows, z_cols], @times);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @times, x, y);
        end
        
        function z = mtimes(x, y)
            % Produces the wrong size, when x is a matrix and y is a
            % scalar. Consider introducing an if-statement or producing
            % size based on the same mehthod as debug is made.
            
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            cond = isscalar(x) || isscalar(y) || size(x,2)==size(y,1);
            yop.assert(cond, yop.messages.incompatible_size('*', x, y));
            
            z = yop.operation('mtimes', [size(x,1), size(y,2)], @mtimes);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @mtimes, x, y);
        end
        
        function z = rdivide(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            yop.assert(yop.node.compatible(x, y), ...
                yop.messages.incompatible_size('./', x, y));
            
            z_rows = max(size(x,1), size(y,1));
            z_cols = max(size(x,2), size(y,2));
            
            z = yop.operation('rdivide', [z_rows, z_cols], @rdivide);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @rdivide, x, y);
        end
        
        function z = ldivide(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            yop.assert(yop.node.compatible(x, y), ...
                yop.messages.incompatible_size('.\', x, y));
            
            z_rows = max(size(x,1), size(y,1));
            z_cols = max(size(x,2), size(y,2));
            
            z = yop.operation('ldivide', [z_rows, z_cols], @ldivide);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @ldivide, x, y);
        end
        
        function z = mrdivide(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            cond = isscalar(y) || size(x,2)==size(y,2);
            yop.assert(cond, yop.messages.incompatible_size('/', x, y));
            
            z = yop.operation('mrdivide', [size(y,1), size(x,1)], @mrdivide);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @mrdivide, x, y);
        end
        
        function z = mldivide(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            cond = isscalar(x) || size(x,1)==size(y,1);
            yop.assert(cond, yop.messages.incompatible_size('\', x, y));
            
            z = yop.operation('mldivide', [size(y,1), size(x,1)], @mldivide);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @mldivide, x, y);
        end
        
        function z = power(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            yop.assert(yop.node.compatible(x, y), ...
                yop.messages.incompatible_size('.^', x, y));
            
            z_rows = max(size(x, 1), size(y, 1));
            z_cols = max(size(x, 2), size(y, 2));
            
            z = yop.operation('power', [z_rows, z_cols], @power);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @power, x, y);
        end
        
        function z = mpower(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            cond = size(x,1)==size(x,2) && isscalar(y) || ...
                size(y,1)==size(y,2) && isscalar(x);
            yop.assert(cond, yop.messages.incompatible_size('^', x, y));
            
            z_rows = max(size(x, 1), size(y, 1));
            z_cols = max(size(x, 2), size(y, 2));
            
            z = yop.operation('mpower', [z_rows, z_cols], @mpower);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @mpower, x, y);
        end
        
        function y = exp(x)
            y = yop.operation('exp', size(x), @exp);
            y.add_child(x);
            x.add_parent(y);
            
            yop.debug.validate_size(y, @exp, x);
        end
        
        function y = expm(x)
            cond = size(x,1)==size(x,2);
            yop.assert(cond, yop.messages.wrong_size('expm', x));
            y = yop.operation('exp', size(x), @expm);
            y.add_child(x);
            x.add_parent(y);
            
            yop.debug.validate_size(y, @expm, x);
        end
        
        function y = ctranspose(x)
            y = yop.operation('ctranspose', [x.columns, x.rows], @ctranspose);
            y.add_child(x);
            x.add_parent(y);
            
            yop.debug.validate_size(y, @ctranspose, x);
        end
        
        function y = transpose(x)
            y = yop.operation('transpose', [x.columns, x.rows], @transpose);
            y.add_child(x);
            x.add_parent(y);
            
            yop.debug.validate_size(y, @transpose, x);
        end
        
        function y = sign(x)
            y = yop.operation('sign', [1, 1], @sign);
            y.add_child(x);
            x.add_parent(y);
            
            yop.debug.validate_size(y, @sign, x);
        end
        
        function z = dot(x, y)
            x = yop.node.typecast(x);
            y = yop.node.typecast(y);
            
            cond = size(x)==size(y);
            yop.assert(cond, yop.messages.incompatible_size('dot', x, y));
            
            z = yop.operation('dot', size(x), @dot);
            
            z.add_child(x);
            z.add_child(y);
            x.add_parent(z);
            y.add_parent(z);
            
            yop.debug.validate_size(z, @dot, x, y);
        end
        
        function y = integral(x)
            x = yop.node.typecast(x);
            y = yop.operation('integral', size(x), @yop.integral);
            y.add_child(x);
            x.add_parent(y);
        end
        
        function y = integrate(x)
            y = integral(x);
        end
        
        function y = der(x)
            x = yop.node.typecast(x);
            y = yop.operation('der', size(x), @yop.der);
            y.add_child(x);
            x.add_parent(y);
        end
        
        function y = alg(x)
            x = yop.node.typecast(x);
            y = yop.operation('alg', size(x), @yop.alg);
            y.add_child(x);
            x.add_parent(y);
        end
        
        function z = cross(x, y)
            
        end
        
        function y = norm(x)
            r = 1;
            c = 1;
        end
        
        function log()
        end
        
        function r = lt(lhs, rhs)
            if isnumeric(lhs)
                tmp = lhs.*ones(size(rhs));
                lhs = yop.constant(yop.default().lhs_name, size(rhs));
                lhs.value = tmp;
            elseif isnumeric(rhs)
                tmp = rhs.*ones(size(lhs));
                rhs = yop.constant(yop.default().rhs_name, size(lhs));
                rhs.value = tmp;
            end
            
            cond = size(lhs,1)==size(rhs,1)&&size(lhs,2)==size(rhs,2);
            yop.assert(cond, yop.messages.incompatible_size('<', lhs, rhs));
            
            r = yop.relation('<', size(lhs), @lt);
            r.add_child(lhs);
            r.add_child(rhs);
            lhs.add_parent(r);
            rhs.add_parent(r);
        end
        
        function r = gt(lhs, rhs)
            if isnumeric(lhs)
                tmp = lhs.*ones(size(rhs));
                lhs = yop.constant(yop.default().lhs_name, size(rhs));
                lhs.value = tmp;
            elseif isnumeric(rhs)
                tmp = rhs.*ones(size(lhs));
                rhs = yop.constant(yop.default().rhs_name, size(lhs));
                rhs.value = tmp;
            end
            
            cond = size(lhs,1)==size(rhs,1)&&size(lhs,2)==size(rhs,2);
            yop.assert(cond, yop.messages.incompatible_size('>', lhs, rhs));
            
            r = yop.relation('>', size(lhs), @gt);
            r.add_child(lhs);
            r.add_child(rhs);
            lhs.add_parent(r);
            rhs.add_parent(r);
        end
        
        function r = le(lhs, rhs)
            if isnumeric(lhs)
                tmp = lhs.*ones(size(rhs));
                lhs = yop.constant(yop.default().lhs_name, size(rhs));
                lhs.value = tmp;
            elseif isnumeric(rhs)
                tmp = rhs.*ones(size(lhs));
                rhs = yop.constant(yop.default().rhs_name, size(lhs));
                rhs.value = tmp;
            end
            
            cond = size(lhs,1)==size(rhs,1)&&size(lhs,2)==size(rhs,2);
            yop.assert(cond, yop.messages.incompatible_size('<=', lhs, rhs));
            
            r = yop.relation('<=', size(lhs), @le);
            r.add_child(lhs);
            r.add_child(rhs);
            lhs.add_parent(r);
            rhs.add_parent(r);
        end
        
        function r = ge(lhs, rhs)
            if isnumeric(lhs)
                tmp = lhs.*ones(size(rhs));
                lhs = yop.constant(yop.default().lhs_name, size(rhs));
                lhs.value = tmp;
            elseif isnumeric(rhs)
                tmp = rhs.*ones(size(lhs));
                rhs = yop.constant(yop.default().rhs_name, size(lhs));
                rhs.value = tmp;
            end
            
            cond = size(lhs,1)==size(rhs,1)&&size(lhs,2)==size(rhs,2);
            yop.assert(cond, yop.messages.incompatible_size('>=', lhs, rhs));
            
            r = yop.relation('>=', size(lhs), @ge);
            r.add_child(lhs);
            r.add_child(rhs);
            lhs.add_parent(r);
            rhs.add_parent(r);
        end
        
        function r = ne(lhs, rhs)
            if isnumeric(lhs)
                tmp = lhs.*ones(size(rhs));
                lhs = yop.constant(yop.default().lhs_name, size(rhs));
                lhs.value = tmp;
            elseif isnumeric(rhs)
                tmp = rhs.*ones(size(lhs));
                rhs = yop.constant(yop.default().rhs_name, size(lhs));
                rhs.value = tmp;
            end
            
            cond = size(lhs,1)==size(rhs,1)&&size(lhs,2)==size(rhs,2);
            yop.assert(cond, yop.messages.incompatible_size('~=', lhs, rhs));
            
            r = yop.relation('~=', size(lhs), @ne);
            r.add_child(lhs);
            r.add_child(rhs);
            lhs.add_parent(r);
            rhs.add_parent(r);
        end
        
        function r = eq(lhs, rhs)
            if isnumeric(lhs)
                tmp = lhs.*ones(size(rhs));
                lhs = yop.constant(yop.default().lhs_name, size(rhs));
                lhs.value = tmp;
            elseif isnumeric(rhs)
                tmp = rhs.*ones(size(lhs));
                rhs = yop.constant(yop.default().rhs_name, size(lhs));
                rhs.value = tmp;
            end
            
            cond = size(lhs,1)==size(rhs,1)&&size(lhs,2)==size(rhs,2);
            yop.assert(cond, yop.messages.incompatible_size('==', lhs, rhs));
            
            r = yop.relation('==', size(lhs), @eq);
            r.add_child(lhs);
            r.add_child(rhs);
            lhs.add_parent(r);
            rhs.add_parent(r);
        end
        
        % --- Logic ---
        % Size scalar?
        % ------------------------------------------------------------------------------------------------
        
        function r = reshape(A, varargin)
            sz = size(reshape(ones(size(A)), varargin{:}));
            varargin = cellfun(@yop.node.typecast, varargin, ...
                'UniformOutput', false);
            
            r = yop.operation('reshape', sz, @reshape);
            
            r.add_child(A);
            A.add_parent(r);
            for k=1:length(varargin)
                r.add_child(varargin{k});
                varargin{k}.add_parent(r);
            end
            
        end
        
    end
    
    methods
        
        %         function cp_obj = copy_structure(obj)
        %             % Copies the structure of an expression graph. It does not
        %             % copies leafs, but the rest is copied. The primary purpose of
        %             % this method is that the copied structure is later going to be
        %             % changed, and then it would be undesirable to change the user
        %             % object. But since the correct experession given by the user
        %             % must be maintained leafs are not copied.
        %
        %             if obj.isa_leaf() || obj.isa_symbol()
        %                 cp_obj = obj;
        %
        %             else
        %                 cp_obj = copy(obj);
        %                 cp_obj.parents = yop.node_listener_list();
        %                 cp_obj.children = yop.list();
        %                 for k=1:obj.children.length
        %                     child_k = copy_structure(obj.child(k));
        %                     cp_obj.add_child(child_k);
        %                     child_k.add_parent(cp_obj);
        %                 end
        %             end
        %         end
        
    end
    
    
    methods (Static)
        
        function v = typecast(v)
            % TYPECAST Cast matlab numerics to 'yop.constant'.
            if ~isa(v, 'yop.node')
                v = yop.constant(yop.default().constant_name, ...
                    size(v)).set_value(v);
            end
        end
        
        function bool = compatible(x, y)
            % COMPATIBLE Check if inputs are 2D compatible
            
            bool = isequal(size(x), size(y)) ...    Equal size
                || isscalar(x) || isscalar(y) ...   One input scalar
                || ( size(x,1)==size(y,1) ) ...     Same number of rows
                || size(x,1)==1 && size(y,2)==1 ... One row, one column
                || size(x,2)==1 && size(y,1)==1;
        end
        
        function varargout = sort(obj, varargin)
            % Search tree in order to find subtrees mathching the criterias
            % in varargin.
            
            criteria = varargin;
            visited = yop.list;
            varargout = cell(size(varargin));
            for n=1:length(varargout)
                varargout{n} = yop.node_list();
            end
            
            function recursion(node)
                
                % Test criterias on node, if match then break
                match = false;
                for k=1:length(criteria)
                    if criteria{k}(node)
                        varargout{k}.add(node);
                        match = true;
                        break
                    end
                end
                visited.add(node);
                
                % Test children
                if ~match
                    for k=1:length(node.children)
                        if ~visited.contains(node.child(k))
                            recursion(node.child(k))
                        end
                    end
                end
            end
            
            recursion(obj);
        end
        
    end
    
end


