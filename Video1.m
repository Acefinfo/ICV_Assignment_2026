%==========================================================================
% VIDEO 1: FRAME-BASED COLOR ENHANCEMENT AND DETAIL REFINEMENT
%==========================================================================
% Input: video1.avi
% Objective: Improve visual quality by processing each frame individually 
%            while preserving color fidelity and enhancing structural details
%
% Processing Pipeline:
%   1. Frame Extraction from input video
%   2. CLAHE applied on luminance channel (LAB color space)
%   3. Median filtering for noise suppression
%   4. Image sharpening for edge enhancement
%   5. Subplot generation for visual comparison (4 stages)
%
% Output:
%   - Frame-wise comparison images (saved as subplots)
%   - Final reconstructed video using sharpened frames
%==========================================================================

clear; close all; clc;

path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path)

inputVideoPath = 'Assets/video1.avi';
outputFolder = 'Output/Video1/';
subplotFolder = fullfile(outputFolder, 'Subplots/');
videoOutputPath = fullfile(outputFolder, 'Sharpened_Video.avi');

%% Create folders
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end
if ~exist(subplotFolder, 'dir'), mkdir(subplotFolder); end

fprintf('\n=== FRAME EXTRACTION & PROCESSING ===\n\n');

%% Read video
vReader = VideoReader(inputVideoPath);
num_frames = vReader.NumFrames;
fps = vReader.FrameRate;

fprintf('Total frames: %d\n', num_frames);

%% Video writer
videoWriter = VideoWriter(videoOutputPath, 'Motion JPEG AVI');
videoWriter.FrameRate = fps;
videoWriter.Quality = 100;
open(videoWriter);

%% METRICS STORAGE

mse_all = zeros(num_frames,1);
psnr_all = zeros(num_frames,1);
ssim_all = zeros(num_frames,1);

%% Processing loop
for i = 1:num_frames
    
    % Read frame
    vReader.CurrentTime = (i-1)/fps;
    original = im2double(readFrame(vReader));
    
    % Ensure RGB
    if size(original,3) == 1
        original = cat(3, original, original, original);
    end

    
    % CLAHE
    
    lab = rgb2lab(original);
    L = lab(:,:,1) / 100;

    L = adapthisteq(L, 'ClipLimit', 0.02);
    
    lab(:,:,1) = L * 100;
    clahe_rgb = lab2rgb(lab);

    
    % MEDIAN FILTER (per channel)
    
    median_filtered = zeros(size(clahe_rgb));

    for c = 1:3
        median_filtered(:,:,c) = medfilt2(clahe_rgb(:,:,c), [3 3]);
    end

    % SHARPENING
    
    sharpened = imsharpen(median_filtered, ...
        'Radius', 1.2, ...
        'Amount', 0.7);

    sharpened = min(max(sharpened,0),1);

    
    % Metrics Calculation
    
    orig_uint8 = im2uint8(original);
    sharp_uint8 = im2uint8(sharpened);

    mse_all(i) = immse(sharp_uint8, orig_uint8);
    psnr_all(i) = psnr(sharp_uint8, orig_uint8);
    ssim_all(i) = ssim(sharp_uint8, orig_uint8);


    % CREATE SUBPLOT

    fig = figure('visible','off');

    subplot(2,2,1);
    imshow(original);
    title('Original');

    subplot(2,2,2);
    imshow(clahe_rgb);
    title('CLAHE RGB');

    subplot(2,2,3);
    imshow(median_filtered);
    title('Median Filter');

    subplot(2,2,4);
    imshow(sharpened);
    title('Sharpened');

    % Save subplot
    subplot_filename = sprintf('Frame_%04d.png', i);
    saveas(fig, fullfile(subplotFolder, subplot_filename));
    close(fig);

    
    % WRITE FINAL VIDEO 
    
    writeVideo(videoWriter, im2uint8(sharpened));

    % Progress
    if mod(i,50)==0 || i==1 || i==num_frames
        fprintf('Processed %d/%d (%.1f%%)\n', i, num_frames, (i/num_frames)*100);
    end
end

% Close video
close(videoWriter);


%% DISPLAY FINAL METRICS

fprintf('\n=== QUALITY METRICS ===\n');
fprintf('Average MSE  : %.4f\n', mean(mse_all));
fprintf('Average PSNR : %.4f dB\n', mean(psnr_all));
fprintf('Average SSIM : %.4f\n', mean(ssim_all));