rootdirs = {'./forcing',...
            './results'};

dryrun = false;

for rid = 1:length(rootdirs)
    delete_all_mat(rootdirs{rid}, dryrun)
end

for rid = 1:length(rootdirs)
    delete_empty_folders(rootdirs{rid}, dryrun)
end





function delete_all_mat(rootdir, dryrun)
	
	if ~exist('dryrun', 'var')
		dryrun = false;
	end
	
    filelist = dir(fullfile(rootdir, '**\*.mat'));
    filelist = filelist(~[filelist.isdir]);

    for k = 1:length(filelist)
		baseFileName = filelist(k).name;
		folder = filelist(k).folder;
		fullFileName = fullfile(folder, baseFileName);
		fprintf(1, 'Now deleting %s\n', fullFileName);
		if ~dryrun
			delete(fullFileName);
		end
    end
end

function delete_empty_folders(rootdir, dryrun)
	
    if ~exist('dryrun', 'var')
		dryrun = false;
	end

    folderlist = dir(fullfile(rootdir, '*.*'));
    folderlist = folderlist([folderlist.isdir]);

    for k = 1:length(folderlist)
		baseFolderName = folderlist(k).name;
		parentPath = folderlist(k).folder;

        if any(strcmp(baseFolderName, {'.', '..'}))
            continue
        end

        folderpath = fullfile(parentPath, baseFolderName);
        dirlist = dir(fullfile(folderpath, '*.*'));
        if length(dirlist) == 2
    		fprintf(1, 'Now deleting %s\n', folderpath);
		    if ~dryrun
			    rmdir(folderpath);
            end
        end
    end
end

