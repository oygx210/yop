yop.debug(true);
yop.options.set_symbolics('symbolic math');

t0 = yop.parameter('t0');
tf = yop.parameter('tf');
t  = yop.variable('t');
x  = yop.variable('x', 2);
u  = yop.variable('u');

ocp = yop.ocp('t', t, 't0', t0, 'tf', tf, 'state', x, 'control', u);

ocp.minimize( 1/2*integral( u^2 ) );

ocp.subject_to( ...
    0 == t0 <= tf == 1, ...
    der(x)  == [x(2); u], ...
    x(t==0) == [0; 1],    ...
    x(t==1) == [0;-1],    ...
    x(1)    <= 1/9        );

%% 

constraints = vertcat(ocp.constraints{:});
constraints.split;
[box, eq, ieq, dynamics] = constraints.classify();

for k=1:length(box)
    
    % Avgör om initial eller final om genom att jmf med ocp.t0/ocp.tf
    % om det finns en tidpunkt och den inte stämmer in på ovanstående ska
    % det tolkas om som ett olinjärt bivillkor.
    
    v = box(k).get_variable;
    bd = box(k).get_bound.evaluate;
    idx = box(k).get_indices;
    
    if isequal(v, ocp.independent_initial.variable)
        
        if box(k).isa_upper_bound
            ocp.independent_initial.upper_bound(idx) = bd;
            
        elseif box(k).isa_lower_bound
            ocp.independent_initial.lower_bound(idx) = bd;
            
        elseif box(k).isa_equality
            ocp.independent_initial.upper_bound(idx) = bd;
            ocp.independent_initial.lower_bound(idx) = bd;
            
        end
    
    
    elseif isequal(v, ocp.independent_final.variable)
        
        if box(k).isa_upper_bound
            ocp.independent_final.upper_bound(idx) = bd;
            
        elseif box(k).isa_lower_bound
            ocp.independent_final.lower_bound(idx) = bd;
            
        else % box(k).isa_equality
            ocp.independent_final.upper_bound(idx) = bd;
            ocp.independent_final.lower_bound(idx) = bd;
            
        end
    
    
    elseif isequal(v, ocp.state.variable)
        
        if isequal(v.timepoint, ocp.independent_initial)
            
            if box(k).isa_upper_bound
                ocp.state.initial_upper_bound(idx) = bd;
                
            elseif box(k).isa_lower_bound
                ocp.state.initial_lower_bound(idx) = bd;
                
            else % box(k).isa_equality
                ocp.state.initial_upper_bound(idx) = bd;
                ocp.state.initial_lower_bound(idx) = bd;
                
            end
              
        elseif isequal(v.timepoint, ocp.independent_final)
                
            if box(k).isa_upper_bound
                ocp.state.final_upper_bound(idx) = bd;
                
            elseif box(k).isa_lower_bound
                ocp.state.final_lower_bound(idx) = bd;
                
            else % box(k).isa_equality
                ocp.state.final_upper_bound(idx) = bd;
                ocp.state.final_lower_bound(idx) = bd;
                
            end
                
        elseif ~isempty(v.timepoint)
            % Move to nlcon
            
        else
            
            if box(k).isa_upper_bound
                ocp.state.upper_bound(idx) = bd;
                
            elseif box(k).isa_lower_bound
                ocp.state.lower_bound(idx) = bd;
                
            else % box(k).isa_equality
                ocp.state.upper_bound(idx) = bd;
                ocp.state.lower_bound(idx) = bd;
                
            end
            
        end
        
    end
    
    
end



