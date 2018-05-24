function S = updatesd(x,e,S)
% Execute one iteration of the sign-data FIR adaptive filter.

%   Author(s): R. Losada
%   Copyright 1999-2002 The MathWorks, Inc.


% Form vector of input+states
u  = [x;S.states].';

% Compute new coefficients
S.coeffs = S.leakage.*S.coeffs + S.step.*e.*sign(u);

% EOF
