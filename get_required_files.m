function get_required_files(files, baseurl)
% Function to download files if they do not exist
%
% files:     list of file names (including path)
% baseurl:   the url from which to download the files
%
% Author: Thomas Ingeman-Nielsen, tin@byg.dtu.dk, August 2021

% check that url ends with a slash, or add it
if strcmp(baseurl(end), '/')
    baseurl = baseurl(1:end-1);
end

for i=1:length(files)
    if ~isfile(files{i})
        [fpath, fname, fext] = fileparts(files{i});
        
        % if no path is included in filename, assume current dir
        if strcmp(fpath, '')
            fpath = '.';
        elseif ~exist(fpath, 'dir')
			[status,msg,msgID] = mkdir(fpath);
        end
        
        % get file from repository
        filename = [fpath '/' fname fext];
        fprintf(['Downloading "' filename '" from repository ... '])
        try
            websave(filename, [baseurl '/' fname fext]);
        catch ME
            disp('Error!')
            rethrow(ME)
        end
        disp('Done')
    end
end
    