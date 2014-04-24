%USER_STRING  Get/set a user specific string
%
% Examples:
%   string = user_string(string_name)
%   saved = user_string(string_name, new_string)
%
% Function to get and set a string persisted in user preferences. This
% enables, for example, system specific paths to binaries to be saved.
%
% IN:
%   string_name - String containing the name of the string required.
%   new_string - The new string to be saved under the name given by
%                string_name.
%
% OUT:
%   string - The currently saved string. Default: ''.
%   saved - Boolean indicating whether the save was succesful

% Copyright (C) Oliver Woodford 2011-2013

% 2014-04-24 - Rewrote function to use getpref/setpref.

function string = user_string(string_name, string)
% validate arguments
if ~isvarname(string_name)
    error('Invalid key.');
end
if nargin > 1 && ~ischar(string)
    error('Value must be a string.');
end

% get/set preference value
group_name = 'ojwoodford_export_fig';
if nargin < 2
    % get value
    string = getpref(group_name, string_name, '');
else
    % set value
    try
        if ~ispref(group_name, string_name)
            addpref(group_name, string_name, string);
        else
            setpref(group_name, string_name, string);
        end
        string = true;    % success
    catch
        string = false;   % failure
    end
end
end
