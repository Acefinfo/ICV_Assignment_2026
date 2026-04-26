%==========================================================================
% IMAGE 1: COLOR CORRECTION AND HARRIS CORNER DETECTION
%==========================================================================
% Purpose: Correct color cast using Gray World white balance
% Problem: Image has improper lighting causing color cast
% Techniques: Gray World, White Balance, Harris Corners, Histogram
%==========================================================================

clear all; close all; clc;

%% Initial path setup for root folder and loading assets
path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path);

% Defining the image path and output folder path
imagePath = 'Assets/Image1.jpg';
outputFolder = 'Output/Image1/';

% Create output folder if doesn't exist
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Load the image
img = imread(imagePath);
img = im2double(img);

%% Image Metrics

[rows, cols, channels] = size(img);
numPixels = rows * cols;

fprintf('--- Image Metrics ---\n');
fprintf('Width: %d pixels\n', cols);
fprintf('Height: %d pixels\n', rows);
fprintf('Channels: %d\n', channels);
fprintf('Total Pixels: %d\n', numPixels);

% Mean intensity per channel
meanR = mean(img(:,:,1), 'all');
meanG = mean(img(:,:,2), 'all');
meanB = mean(img(:,:,3), 'all');

fprintf('Mean R: %.4f\n', meanR);
fprintf('Mean G: %.4f\n', meanG);
fprintf('Mean B: %.4f\n', meanB);


%% Split channels
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

%% Gray World White Balance
R_avg = mean(R(:));
G_avg = mean(G(:));
B_avg = mean(B(:));

avg = (R_avg + G_avg + B_avg) / 3;

R_corr = R * (avg / R_avg);
G_corr = G * (avg / G_avg);
B_corr = B * (avg / B_avg);

% Merge corrected image
img_grayworld = cat(3, R_corr, G_corr, B_corr);

%% Additional Green Cast Reduction
G_corr2 = G_corr * 0.85;   % reduce green
R_corr2 = R_corr * 1.05;   % slight boost red

img_corrected = cat(3, R_corr2, G_corr2, B_corr);

% Clip values to [0,1]
img_corrected = min(max(img_corrected, 0), 1);

%% Contrast Enhancement (Histogram Stretching)
img_enhanced = zeros(size(img_corrected));

for i = 1:3
    channel = img_corrected(:,:,i);
    img_enhanced(:,:,i) = imadjust(channel, stretchlim(channel), []);
end

%% Metrics After Enhancement

meanR2 = mean(img_enhanced(:,:,1), 'all');
meanG2 = mean(img_enhanced(:,:,2), 'all');
meanB2 = mean(img_enhanced(:,:,3), 'all');

fprintf('\n--- After Enhancement ---\n');
fprintf('Mean R: %.4f\n', meanR2);
fprintf('Mean G: %.4f\n', meanG2);
fprintf('Mean B: %.4f\n', meanB2);

%% Save intermediate results
imwrite(img_grayworld, fullfile(outputFolder, 'grayworld.jpg'));
imwrite(img_corrected, fullfile(outputFolder, 'color_corrected.jpg'));
imwrite(img_enhanced, fullfile(outputFolder, 'enhanced.jpg'));

%% Convert to Grayscale for Harris Corner Detection
gray = rgb2gray(img_enhanced);

%% Harris Corner Detection (Tuned)

% Detect corners with parameters
corners = detectHarrisFeatures(gray, ...
    'MinQuality', 0.01, ...   % sensitivity (lower = more points)
    'FilterSize', 5);         % neighborhood size

% Select strongest N corners
numCorners = 150;  
strongCorners = corners.selectStrongest(numCorners);

% Marker size control
markerSize = 8;

% Overlay corners
img_corners = insertMarker(img_enhanced, strongCorners.Location, ...
    'o', 'Color', 'red', 'Size', markerSize);

%% 7. Save final output
imwrite(img_corners, fullfile(outputFolder, 'harris_corners.jpg'));

%% 8. Display results
figure;

subplot(2,2,1);
imshow(img);
title('Original Image');

subplot(2,2,2);
imshow(img_grayworld);
title('Gray World Correction');

subplot(2,2,3);
imshow(img_enhanced);
title('Final Enhanced Image');

subplot(2,2,4);
imshow(img_corners);
title('Harris Corners');

%% 9. PSNR Calculation

% Convert to same format
original_uint8 = im2uint8(img);
enhanced_uint8 = im2uint8(img_enhanced);

% Compute PSNR
[peaksnr, snr] = psnr(enhanced_uint8, original_uint8);

fprintf('PSNR between original and enhanced image: %.2f dB\n', peaksnr);

%% SSIM Calculation
ssim_val = ssim(enhanced_uint8, original_uint8);
fprintf('SSIM between original and enhanced image: %.4f\n', ssim_val);