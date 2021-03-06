%% SeedBased: 
function [] = SeedBased_func(WhichProject,ParticipantID,removeNoise,WhichSeed)
    % ------------------------------------------------------------------------------
    % SeedBased.m
    % ------------------------------------------------------------------------------
    % This script will run the first level analysis.
    % 
    % ------------------------------------------------------------------------------
    % Linden Parkes, Brain & Mental Health Laboratory, 2016
    % ------------------------------------------------------------------------------

    % ------------------------------------------------------------------------------
    % Parent dir
    % ------------------------------------------------------------------------------
    parentdir = '/home/lindenmp/kg98/Linden/';
    parentdir_scratch = '/home/lindenmp/kg98_scratch/Linden/';

    % ------------------------------------------------------------------------------
    % Add paths - edit this section
    % ------------------------------------------------------------------------------
    % where the prepro scripts are
    funcdir = [parentdir,'Scripts/rs-fMRI/func/'];
    addpath(funcdir)

    fprintf(1, 'Running first level analysis using %s ROIs\n',WhichSeed);

    % ------------------------------------------------------------------------------
    % Set parcellation
    % Note, code is not setup to process multiple parcellations concurrently.
    % ------------------------------------------------------------------------------
    switch WhichSeed
        case 'TriStri'
            Seed = 3;
            idx = [1,4; 3,6];
        case 'DiMartino'
            Seed = 4;
            idx = [1,7; 6,12];
    end

    % ------------------------------------------------------------------------------
    % Set project variables
    % ------------------------------------------------------------------------------
    switch WhichProject
        case 'OCDPG_DCM'
            datadir = [parentdir_scratch,'ResProjects/rfMRI_DCM/OCDPG/data/'];
            preprostr = '/func/prepro/';

            TR = 2.5;
            N = 189;
            N = N - 4;
            numSlices = 44;
            refSlice = numSlices - 1; % use for interleaved order

            % Name of preprocessed functional data file
            rsdata = 'epi_prepro.nii.gz';
            brainMask = 'brain_mask.nii.gz';
    end

    % ------------------------------------------------------------------------------
    % Script
    % ------------------------------------------------------------------------------
    firstDirs = {['FirstLevel_L_',WhichSeed,'/'],['FirstLevel_R_',WhichSeed,'/']};

    fprintf(1,'Processing subject %s\n',ParticipantID)

    preprodir = [datadir,ParticipantID,preprostr];
    workdir = [preprodir,removeNoise,'/'];

    % unzip
    fprintf(1, '\t\tDecompressing epi...\n');
    cd(workdir); gunzip(rsdata); delete(rsdata)

    fprintf(1, '\t\tDecompressing brain mask...\n');
    cd(preprodir); gunzip(brainMask); delete(brainMask)

    % ------------------------------------------------------------------------------
    % Get time series
    % ------------------------------------------------------------------------------
    cd(workdir)
    load('cfg.mat');
    roiTS = cfg.roiTS{Seed};

    % ------------------------------------------------------------------------------
    % Estimate first level
    % ------------------------------------------------------------------------------
    for j = 1:length(firstDirs)
        firstdir = firstDirs{j};

        % Setup output directory
        if exist(firstdir) == 0
            fprintf(1,'\t\tInitialising firstdir\n')
            mkdir(firstdir)
        elseif exist(firstdir) == 7
            fprintf(1,'\t\tCleaning and re-initialising firstdir\n')
            rmdir(firstdir,'s')
            mkdir(firstdir)
        end

        R = roiTS(:,idx(1,j):idx(2,j));
        save spm_regs R
        clear R
        movefile('spm_regs.mat',firstdir)

        FirstLevelGLM([workdir,firstdir],'scans',TR,numSlices,refSlice,[workdir,rsdata(1:end-3)],N,[workdir,firstdir,'spm_regs.mat'],[preprodir,brainMask(1:end-3)]);
        
        FirstLevelContrasts(WhichSeed,[workdir,firstdir,'SPM.mat']);
    end
    fprintf(1, 'First level analysis done \n');

    % clean up
    fprintf(1, 'Cleaning up\n');
    cd(workdir); gzip(rsdata(1:end-3)); delete(rsdata(1:end-3))
    cd(preprodir); gzip(brainMask(1:end-3)); delete(brainMask(1:end-3))

    fprintf(1, 'Done!\n');
end
