%==========================================================================
% VIDEO 2: PROFESSIONAL COLOR ENHANCEMENT AND DETAIL REFINEMENT
%==========================================================================
% Purpose:
%   Process video2.avi using frame-by-frame enhancement pipeline
%
% Processing Pipeline:
%   1. CLAHE on LAB luminance channel
%   2. Median filtering (noise reduction)
%   3. Unsharp masking (detail enhancement)
%   4. Quality metrics (MSE, PSNR, SSIM)
%
% Outputs:
%   - ProcessedVideo2_Enhanced.avi
%   - Comparison subplot images
%   - Metrics report
%   - Progress graph
%==========================================================================

clear;close all;clc;

% =====================================================================
% CONFIGURATION
% =====================================================================

Path = "/MATLAB Drive/ICV";
cd(Path);

inputVideoPath = 'Assets/video2.avi';

outputFolder = 'Output/Video2/';
subplotFolder = fullfile(outputFolder, 'Subplots/');

videoOutputPath = fullfile( ...
    outputFolder, ...
    'ProcessedVideo2_Enhanced.avi');

metricsFile = fullfile( ...
    outputFolder, ...
    'Video2_Metrics.txt');

progressFigurePath = fullfile( ...
    outputFolder, ...
    'Processing_Progress.png');

% Create output folders
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

if ~exist(subplotFolder, 'dir')
    mkdir(subplotFolder);
end

fprintf(' VIDEO 2: COLOR ENHANCEMENT & DETAIL REFINEMENT\n');

%% VIDEO READER SETUP

vReader = VideoReader(inputVideoPath);

% Get FPS from input video
fps = vReader.FrameRate;

% Estimate total frames
estimated_total_frames = floor(vReader.Duration * fps);

fprintf('Input Video Loaded Successfully\n');
fprintf('Frame Rate : %.2f FPS\n', fps);
fprintf('Total Frames (Estimated) : %d\n\n', estimated_total_frames);


%% VIDEO WRITER SETUP

videoWriter = VideoWriter(videoOutputPath,'Motion JPEG AVI');

videoWriter.FrameRate = fps;
videoWriter.Quality = 95;

open(videoWriter);

% METRIC ARRAYS
mse_values = [];
psnr_values = [];
ssim_values = [];
frame_times = [];

%% PROGRESS FIGURE

fig_progress = figure('Name','Processing Progress','NumberTitle','off');

set(fig_progress, 'Position', [100 100 1100 700]);

%% PROCESSING LOOP
processing_start = tic;
frame_num = 0;
while hasFrame(vReader)

    frame_start = tic;
    frame_num = frame_num + 1;

    % READ FRAME
    frame_original = im2double(readFrame(vReader));

    % Ensure RGB
    if size(frame_original, 3) == 1
        frame_original = repmat(frame_original, 1, 1, 3);
    end

    % CLAHE ENHANCEMENT
    lab_frame = rgb2lab(frame_original);
    L_channel = lab_frame(:,:,1) / 100;

    L_clahe = adapthisteq(L_channel,'ClipLimit', 0.02,'NumTiles', [8 8]);
    lab_frame(:,:,1) = L_clahe * 100;
    frame_clahe = lab2rgb(lab_frame);
    frame_clahe = max(min(frame_clahe, 1), 0);

    % MEDIAN FILTERING
    frame_median = medfilt3(frame_clahe, [3 3 1]);

    % UNSHARP MASKING
    frame_sharpened = imsharpen(frame_median, 'Radius', 1.2, 'Amount', 0.7, 'Threshold', 0);
    frame_sharpened = max(min(frame_sharpened, 1), 0);

    % METRIC CALCULATIONS
    orig_uint8 = im2uint8(frame_original);
    sharp_uint8 = im2uint8(frame_sharpened);

    mse_values(frame_num) = immse(sharp_uint8,orig_uint8);
    psnr_values(frame_num) = psnr(sharp_uint8, orig_uint8);
    ssim_values(frame_num) = ssim(sharp_uint8, orig_uint8);

    % WRITE FRAME
    writeVideo(videoWriter, sharp_uint8);

    % PROCESSING TIME
    frame_times(frame_num) = toc(frame_start);

    % SAVE COMPARISON SUBPLOTS
    if mod(frame_num,20)==0 || frame_num==1

        fig_subplot = figure('Visible', 'off', 'Position', [100 100 1200 800]);

        % Original 
        subplot(2,2,1);

        imshow(frame_original);

        title( sprintf('Original (Frame %d)', frame_num), 'FontWeight', 'bold');

        % CLAHE
        subplot(2,2,2);

        imshow(frame_clahe);

        title(sprintf('CLAHE (PSNR %.2f dB)', psnr_values(frame_num)), 'FontWeight', 'bold');

        % Median 
        subplot(2,2,3);

        imshow(frame_median);

        title('Median Filtering', 'FontWeight', 'bold');

        % Final 
        subplot(2,2,4);

        imshow(frame_sharpened);

        title(sprintf('Sharpened (SSIM %.4f)', ssim_values(frame_num)), 'FontWeight', 'bold');

        subplot_filename = fullfile(subplotFolder, sprintf('Frame_%04d_Comparison.png', frame_num));

        exportgraphics( fig_subplot, subplot_filename, 'Resolution', 150);

        close(fig_subplot);
    end

    % PROGRESS DISPLAY
    if mod(frame_num,10)==0 || frame_num==1

        elapsed = toc(processing_start);

        progress_pct = ...
            (frame_num / estimated_total_frames) * 100;

        estimated_total_time = ...
            elapsed * (estimated_total_frames / frame_num);

        remaining_time = ...
            estimated_total_time - elapsed;

        

         % UPDATE PROGRESS FIGURE
         figure(fig_progress);

        % PSNR
        subplot(2,2,1);

        plot( ...
            1:frame_num, ...
            psnr_values, ...
            'b-', ...
            'LineWidth', 2);

        xlabel('Frame');
        ylabel('PSNR (dB)');

        title('PSNR Across Frames');

        grid on;

        % SSIM 
        subplot(2,2,2);

        plot( ...
            1:frame_num, ssim_values, 'g-', 'LineWidth', 2);

        xlabel('Frame');
        ylabel('SSIM');

        title('SSIM Across Frames');

        ylim([0 1]);

        grid on;

        % MSE 
        subplot(2,2,3);

        plot( ...
            1:frame_num, mse_values, 'r-', 'LineWidth', 2);

        xlabel('Frame');
        ylabel('MSE');

        title('MSE Across Frames');

        grid on;

        % Average Metrics 
        subplot(2,2,4);

        avg_psnr = mean(psnr_values);
        avg_ssim = mean(ssim_values);

        bar([avg_psnr avg_ssim]);

        set(gca, ...
            'XTickLabel', ...
            {'PSNR','SSIM'});

        title('Average Metrics');

        grid on;

        drawnow;
    end
end

%% FINALIZE VIDEO

close(videoWriter);

total_processing_time = toc(processing_start);

% FINAL STATISTICS
num_frames = frame_num;

psnr_mean = mean(psnr_values);
psnr_std  = std(psnr_values);

ssim_mean = mean(ssim_values);
ssim_std  = std(ssim_values);

mse_mean  = mean(mse_values);
mse_std   = std(mse_values);

avg_frame_time = mean(frame_times);

processing_fps = num_frames / total_processing_time;

%% DISPLAY SUMMARY

fprintf('---------------- QUALITY METRICS ----------------\n\n');

fprintf('PSNR Mean : %.4f dB\n', psnr_mean);
fprintf('PSNR Std  : %.4f dB\n\n', psnr_std);

fprintf('SSIM Mean : %.4f\n', ssim_mean);
fprintf('SSIM Std  : %.4f\n\n', ssim_std);

fprintf('MSE Mean  : %.6f\n', mse_mean);
fprintf('MSE Std   : %.6f\n\n', mse_std);
