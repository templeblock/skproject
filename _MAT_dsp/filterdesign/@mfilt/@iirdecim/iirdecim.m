function this = iirdecim(varargin)
%IIRDECIM   Construct an IIR decimator filter object.
%   Hm = MFILT.IIRDECIM(C1,C2,...) constructs an IIR decimator filter
%   given the coefficients specified in the cell arrays C1, C2, etc.
%
%   The IIR decimator is a polyphase IIR filter where each phase is a
%   cascade allpass IIR filter.
%
%   Each cell array Ci, contains a set of vectors representing a cascade of
%   allpass sections. Each element in the cell array is one section. For
%   more information on the contents of each cell array, see the help for
%   DFILT.CASCADEALLPASS. The contents of the cell array are the same as
%   the ones specified in the constructor of DFILT.CASCADEALLPASS and have
%   the same interpretation. However, the following exception applies: if
%   one of the cell arrays contains only one vector which consists of a
%   series of zeros and a unique element equal to one, that cell array
%   represent a DFILT.DELAY with latency equal to the number of zeros
%   rather than a DFILT.CASCADEALLPASS. This case occurs with quasi linear 
%   phase IIR decimators.
%
%   Note that one usually does not construct IIR decimators explicitly as
%   discussed so far. Instead, one obtains these filters as a result from a
%   design of a halfband decimator. An example of this is shown below.
%
%   % Example # 1: Design an elliptic halfband decimator with a decimation
%   % factor of 2.
%   TW  = 100;  % Transition width of filter to be designed, 100 Hz
%   Ast = 80;   % Stopband attenuation of filter to be designed, 80 db
%   Fs  = 2000; % Sampling frequency of signal to be filtered
%   M   = 2;    % Decimation factor
%   f = fdesign.decimator(M,'halfband','TW,Ast',TW,Ast,Fs); % Store decimator design specs
%   % Now perform actual design. Hm results in an mfilt.iirdecim
%   Hm = design(f,'ellip','FilterStructure','iirdecim'); 
%   realizemdl(Hm) % Requires Simulink; build model for filter
%
%   % Example # 2: Design an linear phase halfband decimator with a decimation
%   % factor of 2.
%   TW  = 100;  % Transition width of filter to be designed, 100 Hz
%   Ast = 60;   % Stopband attenuation of filter to be designed, 80 db
%   Fs  = 2000; % Sampling frequency of signal to be filtered
%   M   = 2;    % Decimation factor
%   f = fdesign.decimator(M,'halfband','TW,Ast',TW,Ast,Fs); % Store decimator design specs
%   % Now perform actual design. Hm results in an mfilt.iirdecim
%   Hm = design(f,'iirlinphase','FilterStructure','iirdecim'); 
%   realizemdl(Hm) % Requires Simulink; visualize 
%
%   See also MFILT/STRUCTURES.

%   Author(s): R. Losada
%   Copyright 2005 The MathWorks, Inc.

this = mfilt.iirdecim;

this.FilterStructure = 'IIR Polyphase Decimator';

for n = 1:nargin,
    fn{n} = sprintf('Phase%d',n);
    for k = 1:length(varargin{n}),        
        phasefn{k} = sprintf('Section%d',k);
    end
    fv{n} = cell2struct(varargin{n},phasefn,2);
    clear phasefn;
end


if nargin > 0,
    this.Polyphase = cell2struct(fv,fn,2);
else
    % Design a filter
    f = fdesign.decimator(2,'halfband');
    h = ellip(f);
    this.polyphase = h.polyphase;
end



% [EOF]