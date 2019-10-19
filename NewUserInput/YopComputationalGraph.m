classdef (InferiorClasses = {?YopVar, ?YopIntegral}) YopComputationalGraph < YopMathOperations & matlab.mixin.Copyable
    
    properties
        Operation
        Argument
        Timepoint
    end
    
    methods % Class
        function obj = YopComputationalGraph(operation, varargin)
            obj.Operation = operation;
            obj.Argument = YopComputationalGraph.convert(varargin);
        end
        
        function bool = nodeIsaRelation(obj)
            bool = ...
                isequal(obj.Operation, @lt) || ...
                isequal(obj.Operation, @gt) || ...
                isequal(obj.Operation, @le) || ...
                isequal(obj.Operation, @ge) || ...
                isequal(obj.Operation, @ne) || ...
                isequal(obj.Operation, @eq);
        end        
        
        function bool = graphIsaExpression(obj)
            bool = true;
            for k=1:length(obj.Argument)
                bool = bool && ...
                    ~nodeIsaRelation(obj.Argument{k}) && ...
                    graphIsaExpression(obj.Argument{k});
            end
            
            % Bör ändras till att rekursivt fråga om nodeIsaRelation
%             operations = obj.getOperations;
%             for k=1:length(operations)
%                bool = bool & ~YopComputationalGraph.isRelationOperation(operations{k});
%             end
        end
        
        function bool = isaVariable(obj)
            bool = false;
        end
        
        function bool = isnumeric(obj)
            bool = false;
        end
        
        function l = lhs(obj)
            l = obj.Argument{1};
        end
        
        function r = rhs(obj)
            r = obj.Argument{2};
        end
        
        function disp(obj)
            for k=1:length(obj)
                disp(obj(k).evaluateComputation);
            end
        end
        
        function display(obj)
            % Bygga något eget rekursivt? om funktionsnamnet är förknippat
            % med en operation med egen symbol byt till symbolen annars
            % skriv ut namnet.
            [r, c] = size(obj);
            elements = [];
            for k=1:length(obj)
                if r > c
                    elements = [elements; obj(k).evaluateComputation];
                else
                    elements = [elements, obj(k).evaluateComputation];
                end
            end
            eval([inputname(1) '= elements']);
        end
    end
    
    methods % YopVar/-Graph Interface        
        function bool = areEqual(x, y)
            bool = false;
        end
        
        function result = evaluateComputation(obj)
            argument = cellfun( ...
                @(arg) evaluateComputation(arg), ...
                obj.Argument, ...
                'UniformOutput', false ...
                );
            result = obj.Operation( argument{:} );
        end
        
        function n = numberOfNodes(obj)
            n = 1 + sum( cellfun(@numberOfNodes, obj.Argument) );
        end
        
        function operations = getOperations(obj)
            operations = {obj.Operation};
            for k=1:length(obj.Argument)
                operations = [operations(:); getOperations(obj.Argument{k})];
            end
        end
        
        function nargs = numberOfInputArguments(obj)
            nargs = 0;
            for k=1:length(obj.Argument)
                nargs = nargs + numberOfInputArguments(obj.Argument{k});
            end
        end
        
        function args = getInputArguments(obj)
            args = {};
            for k=1:length(obj.Argument)
                args = [args(:); getInputArguments(obj.Argument{k})];
            end
        end
        
        function bool = dependsOn(obj, variable)
            obj.disp
            bool = false;
            for k=1:length(obj.Argument)
                bool = dependsOn(obj.Argument{k}, variable) || bool;
            end
        end
    end
    
    methods % Graph interpretation and modification                
        function bool = isaBox(obj)
            bool = xor(isaVariable(obj.lhs), isaVariable(obj.rhs)) && ...
                xor(isnumeric(obj.lhs), isnumeric(obj.rhs));
        end
        
        function bool = isaEquality(obj)
            bool = isequal(obj.Operation, @eq);
        end
        
        function bool = isaUpperBound(obj)
            bool = (...
                (obj.rhs.isnumeric && isequal(obj.Operation, @lt)) || ...
                (obj.rhs.isnumeric && isequal(obj.Operation, @le)) || ...
                (obj.lhs.isnumeric && isequal(obj.Operation, @gt)) || ...
                (obj.lhs.isnumeric && isequal(obj.Operation, @ge)) ...
                ) && obj.isaBox;      
        end
        
        function bool = isaLowerBound(obj)
            bool = (...
                (obj.lhs.isnumeric && isequal(obj.Operation, @lt)) || ...
                (obj.lhs.isnumeric && isequal(obj.Operation, @le)) || ...
                (obj.rhs.isnumeric && isequal(obj.Operation, @gt)) || ...
                (obj.rhs.isnumeric && isequal(obj.Operation, @ge)) ...
                ) && obj.isaBox;
        end
        
        function bd = getBound(obj)
            if obj.isaEquality
            end
        end
        
        function ub = getUpperBound(obj)
            ub = [];
            if obj.isaUpperBound && ...
                    (isequal(obj.Operation, @gt) || isequal(obj.Operation, @ge))
                ub = obj.lhs;
                
            elseif obj.isaUpperBound && ...
                    (isequal(obj.Operation, @lt) || isequal(obj.Operation, @le))
                ub = obj.rhs;
                
            end
        end
        
        function lb = getLowerBound(obj)
            lb = [];
            if obj.isaLowerBound && ...
                    (isequal(obj.Operation, @gt) || isequal(obj.Operation, @ge))
                lb = obj.rhs;
                
            elseif obj.isaLowerBound && ...
                    (isequal(obj.Operation, @lt) || isequal(obj.Operation, @le))
                lb = obj.lhs;
                
            end
        end
        
        function l = leftmostExpression(obj)
            if obj.graphIsaExpression
                l = obj;                
            else
                l = leftmostExpression(obj.lhs);
            end            
        end
        
        function r = rightmostExpression(obj)
            if obj.graphIsaExpression
                r = obj;
            else
                r = rightmostExpression(obj.rhs);                
            end
        end
        
        function graph = unnestRelations(obj)
            % Interprets graph as a constraint and unnest relations in the
            % graph from left to right. May brake down if graph is not a 
            % valid constraint.
            % I.e. -1 <= f(x) <= 1 turns into:
            %  -1 <= f(x)
            %  f(x) <= 1
            
            if length(obj) > 1
                graph = [];
                for k=1:length(obj)
                    graph = [graph; obj(k).unnestRelations];
                end
                
            elseif obj.lhs.graphIsaExpression && obj.rhs.graphIsaExpression
                graph = obj;
                
            elseif obj.lhs.graphIsaExpression && obj.rhs.nodeIsaRelation
                graph = [ ...
                    YopComputationalGraph(obj.Operation, obj.lhs, leftmostExpression(obj.rhs)); ...
                    unnestRelations(obj.rhs) ...
                    ];
                
            elseif obj.lhs.nodeIsaRelation && obj.rhs.graphIsaExpression
                graph = [ ...
                    unnestRelations(obj.lhs); ...
                    YopComputationalGraph(obj.Operation, rightmostExpression(obj.lhs), obj.rhs) ...                    
                    ];
                
            elseif obj.lhs.nodeIsaRelation && obj.rhs.nodeIsaRelation
                graph = [ ...
                    unnestRelations(obj.lhs); ...
                    YopComputationalGraph(obj.Operation, rightmostExpression(obj.lhs), leftmostExpression(obj.rhs)); ...
                    unnestRelations(obj.rhs) ...
                    ];                
            end   
            
        end
        
        function nlpForm = setToNlpForm(obj)
            % Sets an unnested graph to the following form.
            % h(x) <= 0
            % g(x) == 0
            % Presumes the graph has been unnested
            
            if length(obj) > 1
                nlpForm = [];
                for k=1:length(obj)
                    nlpForm = [nlpForm; obj(k).setToNlpForm];
                end
            
            elseif isequal(obj.Operation, @lt) || isequal(obj.Operation, @le)
                nlpForm = YopComputationalGraph( ...
                    @le, ...
                    obj.lhs - obj.rhs, ...
                    zeros( size(obj.lhs.evaluateComputation) ) ...
                    );
                
            elseif isequal(obj.Operation, @gt) || isequal(obj.Operation, @ge)
                nlpForm = YopComputationalGraph( ...
                    @le, ...
                    obj.rhs - obj.lhs, ...
                    zeros( size(obj.lhs.evaluateComputation) ) ...
                    );                
                
            elseif isequal(obj.Operation, @eq)
                nlpForm = YopComputationalGraph( ...
                    @eq, ...
                    obj.lhs - obj.rhs, ...
                    zeros( size(obj.lhs.evaluateComputation) ) ...
                    );                
            end
        end
    end
    
    methods (Access=protected)
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            cpObj.Argument = cell(size(obj.Argument));
            for k=1:length(obj.Argument)
                cpObj.Argument{k} = copy(obj.Argument{k});
            end
        end
    end
    
    methods (Static)
        function args = convert(args)
            for k=1:length(args)
                if ~isa(args{k}, 'YopVar') && ~isa(args{k}, 'YopComputationalGraph')
                    args{k} = YopVar(args{k});
                end
            end
        end
        
        function bool = isRelationOperation(operation)
            bool = ...
                isequal(operation, @lt) || ...
                isequal(operation, @gt) || ...
                isequal(operation, @le) || ...
                isequal(operation, @ge) || ...
                isequal(operation, @ne) || ...
                isequal(operation, @eq);
        end
    end
end