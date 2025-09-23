function database = DL_batch(folderPath)
% DL_BATCH: Reads all .c3d files in a folder (recursively) into a database
% Skips last file in each folder and files that are too short around peak bat speed
%
% Returns:
%   database - struct array with fields: filename, folder, data

    % Step 1: Recursively find all C3D files
    files = dir(fullfile(folderPath, '**', '*.c3d'));
    files = files(~[files.isdir]); % filter out directories

    % Step 2: Exclude last file in each subfolder
    [uniqueFolders, ~, folderIdx] = unique({files.folder});
    keepMask = true(size(files));

    for k = 1:numel(uniqueFolders)
        idx = find(folderIdx == k);
        [~, sortOrder] = sort({files(idx).name});
        idx = idx(sortOrder);
        keepMask(idx(end)) = false; % exclude last file
    end
    files = files(keepMask);

    % Step 3: Read files and build database
    database = struct('filename', {}, 'folder', {}, 'data', {});

    for i = 1:numel(files)
        filePath = fullfile(files(i).folder, files(i).name);
        fprintf('Processing file %d of %d: %s\n', i, numel(files), filePath);

        if isfile(filePath)
            try
                data = DL_read(filePath);  % returns [] if not enough frames
                if ~isempty(data)
                    % Only include valid files
                    database(end+1).filename = files(i).name;
                    database(end).folder   = files(i).folder;
                    database(end).data     = data;
                else
                    fprintf('Skipping %s: insufficient frames around peak.\n', files(i).name);
                end
            catch ME
                warning('Skipping %s (error: %s)', filePath, ME.message);
            end
        else
            warning('Skipping (not a valid file): %s', filePath);
        end
    end

    fprintf('Database built with %d valid C3D files.\n', numel(database));
end


