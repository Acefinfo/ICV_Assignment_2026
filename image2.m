%==========================================================================
% IMAGE 2: COLOR DEBLURRING AND ENHANCEMENT
%==========================================================================
% Purpose: Recover clarity from a blurred color image
% Problem: Strong defocus blur (loss of detail)
% Techniques: Blind Deconvolution (per channel), Sharpening, Contrast Enhance
%==========================================================================

clear all; close all; clc;

%% Initial path setup
path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path);

% Paths
imagePath = 'Assets/Image2.JPG';
outputFolder = 'Output/Image2/';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Load Image
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

%% Split Channels
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

%% Blind Deconvolution (Per Channel)

psf_size = 35;
psf_sigma = 7;
iterations = 50;

PSF = fspecial('gaussian', psf_size, psf_sigma);

R_deblur = deconvblind(R, PSF, iterations);
G_deblur = deconvblind(G, PSF, iterations);
B_deblur = deconvblind(B, PSF, iterations);

% Merge channels
img_deblurred = cat(3, R_deblur, G_deblur, B_deblur);
img_deblurred = min(max(img_deblurred, 0), 1);

%% Sharpening (Mild)

img_sharpened = imsharpen(img_deblurred, ...
    'Radius', 2, ...
    'Amount', 1.5);

%% Light Smoothing (Artifact Reduction)

img_smoothed = imgaussfilt(img_sharpened, 0.5);

%% Contrast Enhancement

img_final = zeros(size(img_smoothed));

for i = 1:3
    channel = img_smoothed(:,:,i);
    img_final(:,:,i) = imadjust(channel, stretchlim(channel), []);
end

img_final = min(max(img_final, 0), 1);

%% Display Results
figure;

subplot(1,3,1);
imshow(img);
title('Original Blurry Image');

subplot(1,3,2);
imshow(img_deblurred);
title('After Deconvolution');

subplot(1,3,3);
imshow(img_final);
title('Final Enhanced Image');

%% ===== SAVE IMAGES =====
fprintf('\nSaving images...\n');

imwrite(img, fullfile(outputFolder, 'original.jpg'));

% Save intermediate result
imwrite(img_deblurred, fullfile(outputFolder, 'deblurred.jpg'));

% Save final result
imwrite(img_final, fullfile(outputFolder, 'final_enhanced.jpg'));

%% Quality Metrics

fprintf('\n--- Quality Metrics ---\n');

orig_uint8 = im2uint8(img);
final_uint8 = im2uint8(img_final);

% PSNR
[psnr_val, ~] = psnr(final_uint8, orig_uint8);
fprintf('PSNR: %.2f dB\n', psnr_val);

% SSIM
ssim_val = ssim(final_uint8, orig_uint8);
fprintf('SSIM: %.4f\n', ssim_val);
