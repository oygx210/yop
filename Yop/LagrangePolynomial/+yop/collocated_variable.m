classdef collocated_variable < yop.collocated_signal
    methods
        function obj = collocated_variable(label, dimension, points, degree, valid_range)
            coefficients = [];
            for r=1:degree+1
                coefficients = [coefficients, yop.variable(label(r), dimension)];
            end
            obj@yop.collocated_signal(coefficients, points, degree, valid_range);
        end
    end    
end