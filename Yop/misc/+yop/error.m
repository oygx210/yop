function error(msg)

if nargin == 0
    msg = 'Unspecified error.';
end

builtin('error', ['Yop: ' msg]);
end