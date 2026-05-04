%==========================================================================
% IMAGE 5: BILATERAL FILTERING AND CONTRAST ENHANCEMENT
%==========================================================================
% Problem: Noise, low contrast, softness
% Solution: Edge-preserving bilateral filter + contrast enhancement
%==========================================================================

clc; clear; close all;

%% Path setup
path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path);

imagePath = 'Assets/Image5.jpg';
outputFolder = fullfile('Output','Image5');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Load image
img = imread(imagePath);
img = im2double(img);
fprintf('✓ Image loaded\n');

%% Bilateral Filtering
fprintf('Applying bilateral filtering...\n');
bilateral_filtered = imbilatfilt(img, 15, 0.1);
fprintf('✓ Bilateral filter applied\n');

%% CLAHE Contrast Enhancement
fprintf('Enhancing contrast using CLAHE...\n');

lab = rgb2lab(bilateral_filtered);
L = lab(:,:,1) / 100;

L_enhanced = adapthisteq(L, 'ClipLimit', 0.02, 'NumTiles', [8 8]);

lab(:,:,1) = L_enhanced * 100;
contrast_enhanced = lab2rgb(lab);

fprintf('✓ Contrast enhanced\n');

%% Sharpening
fprintf('Sharpening...\n');

sharpened = imsharpen(contrast_enhanced, ...
    'Radius', 1.2, ...
    'Amount', 1.0, ...
    'Threshold', 0.02);

sharpened = min(max(sharpened, 0), 1);
fprintf('✓ Sharpening applied\n');

%% Convert for metrics
orig_uint8 = uint8(img * 255);
sharp_uint8 = uint8(sharpened * 255);

%% Metrics
fprintf('Computing metrics...\n');

% MSE
mse = mean((double(orig_uint8(:)) - double(sharp_uint8(:))).^2);

% PSNR
MAX_I = 255;
psnr_val = 10 * log10((MAX_I^2) / (mse + eps));

% Laplacian Variance
laplacian_kernel = [0 -1 0; -1 4 -1; 0 -1 0];
laplacian_img = imfilter(double(sharp_uint8), laplacian_kernel, 'replicate');
laplacian_var = var(laplacian_img(:));

% Contrast (no toolbox)
contrast_val = max(sharpened(:)) - min(sharpened(:));

% SSIM
gray_orig = rgb2gray(img);
gray_sharp = rgb2gray(sharpened);
ssim_val = ssim(gray_sharp, gray_orig);

fprintf('✓ PSNR: %.2f dB\n', psnr_val);
fprintf('✓ SSIM: %.4f\n', ssim_val);
fprintf('✓ Laplacian Variance: %.2f\n', laplacian_var);

%% Visualization

%Figure 1: Processing Stages
figure('Name', 'Processing Stages', 'NumberTitle', 'off');

subplot(2,2,1);
imshow(img);
title('Original');

subplot(2,2,2);
imshow(bilateral_filtered);
title('Bilateral Filtered');

subplot(2,2,3);
imshow(contrast_enhanced);
title('CLAHE Enhanced');

subplot(2,2,4);
imshow(sharpened);
title('Final Sharpened');

% Figure 2: Histogram
figure('Name', 'Histogram Comparison', 'NumberTitle', 'off');

imhist(orig_uint8);
hold on;
imhist(sharp_uint8);
hold off;

legend('Original', 'Enhanced');
title('Histogram Comparison');

%Figure 3: Before vs After
figure('Name', 'Before vs After', 'NumberTitle', 'off');

subplot(1,2,1);
imshow(img);
title('Original Image');

subplot(1,2,2);
imshow(sharpened);
title('Final Enhanced Image');

%% Saving outputs

imwrite(uint8(bilateral_filtered * 255), fullfile(outputFolder, 'Image5_Bilateral.jpg'));
imwrite(uint8(contrast_enhanced * 255), fullfile(outputFolder, 'Image5_Contrast.jpg'));
imwrite(uint8(sharpened * 255), fullfile(outputFolder, 'Image5_Enhanced.jpg'));

saveas(figure(1), fullfile(outputFolder, 'Processing_Stages.png'));
saveas(figure(2), fullfile(outputFolder, 'Histogram.png'));
saveas(figure(3), fullfile(outputFolder, 'Before_After.png'));

%% Save metrics to file

fprintf('PSNR: %.2f dB\n', psnr_val);
fprintf('SSIM: %.4f\n', ssim_val);
fprintf('Laplacian Variance: %.2f\n', laplacian_var);