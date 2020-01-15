% Return java.lang.Class instance for MatLab type.
%
% Input arguments:
% mtype:
%    the MatLab name of the type for which to return the java.lang.Class
%    instance
% ndims:
%    the number of dimensions of the MatLab data type
%
% See also: class

% Copyright 2009-2010 Levente Hunyadi
function jclass = javaclass(mtype, ndims)

validateattributes(mtype, {'char'}, {'nonempty','row'});
if nargin < 2
    ndims = 0;
else
    validateattributes(ndims, {'numeric'}, {'nonnegative','integer','scalar'});
end

if ndims == 1 && strcmp(mtype, 'char');  % a character vector converts into a string
    jclassname = 'java.lang.String';
elseif ndims > 0
    jclassname = javaarrayclass(mtype, ndims);
else
    % The static property .class applied to a Java type returns a string in
    % MatLab rather than an instance of java.lang.Class. For this reason,
    % use a string and java.lang.Class.forName to instantiate a
    % java.lang.Class object; the syntax java.lang.Boolean.class will not
    % do so.
    switch mtype
        case 'logical'  % logical vaule (true or false)
            jclassname = 'java.lang.Boolean';
        case 'char'  % a singe character
            jclassname = 'java.lang.Character';
        case {'int8','uint8'}  % 8-bit signed and unsigned integer
            jclassname = 'java.lang.Byte';
        case {'int16','uint16'}  % 16-bit signed and unsigned integer
            jclassname = 'java.lang.Short';
        case {'int32','uint32'}  % 32-bit signed and unsigned integer
            jclassname = 'java.lang.Integer';
        case {'int64','uint64'}  % 64-bit signed and unsigned integer
            jclassname = 'java.lang.Long';
        case 'single'  % single-precision floating-point number
            jclassname = 'java.lang.Float';
        case 'double'  % double-precision floating-point number
            jclassname = 'java.lang.Double';
        case 'cellstr'  % a single cell or a character array
            jclassname = 'java.lang.String';
        case 'string'  % a single cell or a character array
            jclassname = 'java.lang.String';
        case 'color'
            jclassname = 'java.awt.Color';
        otherwise
            error('java:javaclass:InvalidArgumentValue', ...
                'MatLab type "%s" is not recognized or supported in Java.', mtype);
    end
end
% Note: When querying a java.lang.Class object by name with the method
% jclass = java.lang.Class.forName(jclassname);
% MatLab generates an error. For the Class.forName method to work, MatLab
% requires class loader to be specified explicitly.
%
% MB: warning in 2018a (and lower??) when java.lang. ... .getContext... is
% done in one go. This works and does not warn.
thread = java.lang.Thread.currentThread();
jclass = java.lang.Class.forName(jclassname, true, thread.getContextClassLoader());

function jclassname = javaarrayclass(mtype, ndims)
% Returns the type qualifier for a multidimensional Java array.

switch mtype
    case 'logical'  % logical array of true and false values
        jclassid = 'Z';
    case 'char'  % character array
        jclassid = 'C';
    case {'int8','uint8'}  % 8-bit signed and unsigned integer array
        jclassid = 'B';
    case {'int16','uint16'}  % 16-bit signed and unsigned integer array
        jclassid = 'S';
    case {'int32','uint32'}  % 32-bit signed and unsigned integer array
        jclassid = 'I';
    case {'int64','uint64'}  % 64-bit signed and unsigned integer array
        jclassid = 'J';
    case 'single'  % single-precision floating-point number array
        jclassid = 'F';
    case 'double'  % double-precision floating-point number array
        jclassid = 'D';
    case 'cellstr'  % cell array of strings
        jclassid = 'Ljava.lang.String;';
    case 'string'  % cell array of strings
        jclassid = 'Ljava.lang.String;';
    otherwise
        error('java:javaclass:InvalidArgumentValue', ...
            'MatLab type "%s" is not recognized or supported in Java.', mtype);
end
jclassname = [repmat('[',1,ndims), jclassid];


% Copyright (c) 2010, Levente Hunyadi
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.