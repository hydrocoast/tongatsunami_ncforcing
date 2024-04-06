clear
close all

%% sim data
% --------------------------------------
% simdir1 = '../run_presA1min_3/_output';
% --------------------------------------
simdir1 = '../run_jaguar/_output';
% --------------------------------------
[dir_p,simdirname] = fileparts(simdir1);

%% make a file list
list_gauge1 = dir(fullfile(simdir1,'gauge*.txt'));
ngauge = size(list_gauge1,1);

%% read
gauge_time_eta = cell(ngauge,2);
for i = 1:ngauge
    file1 = fullfile(simdir1,list_gauge1(i).name);
    dat1 = readmatrix(file1,"FileType","text","NumHeaderLines",3);
    gauge_time_eta{i,1} = dat1(:,2); % time
    gauge_time_eta{i,2} = dat1(:,6); % eta, AMRlevel
end

%% convert call array to table
Tsim = table(gauge_time_eta(:,1),gauge_time_eta(:,2),'VariableNames',["Elapsed time","Eta"]);

%% save
save(fullfile(dir_p,[simdirname,'.mat']),'-v7.3','Tsim','simdirname');

