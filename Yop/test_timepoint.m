t = yop.variable('t');
t0 = yop.parameter('t0');
tf = yop.parameter('tf');

independent = yop.independent(t);
independent.upper_bound = 1;
independent.lower_bound = 0;

tp1 = yop.timepoint(t0);
tp2 = yop.timepoint(tf);
tp3 = yop.timepoint(t==0);
tp4 = yop.timepoint(t==t0);
tp5 = yop.timepoint(tf==t);
tp6 = yop.timepoint(1==t);

tp1.is_initial(independent);
tp6.is_final(independent);