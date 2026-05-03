%==========================================================================
% IMAGE 4: COMPREHENSIVE ENHANCEMENT
%==========================================================================
% Problem: Dark, low-contrast, uneven brightness, blurry
% Solution: CLAHE + complete 9-stage enhancement pipeline
%==========================================================================

clear all; close all; clc;

%% Initial path setup
path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path);

imagePath = 'Assets/Image4.jpg';
outputFolder = 'Output/Image4/';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Load image
img = imread(imagePath);
img = im2double(img);

%% Pre-processing metrics 

img_uint8 = uint8(img * 255);

% Variance (texture/detail measure)
img_variance = var(double(img_uint8(:)));

% Sharpness (Laplacian variance)
lap_kernel = [0 -1 0; -1 4 -1; 0 -1 0];
lap_img = imfilter(img, lap_kernel, 'replicate');
img_sharpness = var(lap_img(:));

fprintf('--- Original Image Metrics ---\n');
fprintf('Variance: %.4f\n', img_variance);
fprintf('Sharpness (Laplacian Var): %.4f\n', img_sharpness);
fprintf('PSNR: N/A (reference image)\n');

%% CLAHE

clahe_enhanced = zeros(size(img));

for i = 1:3
    clahe_enhanced(:,:,i) = im2double( ...
        adapthisteq(uint8(img(:,:,i)*255), ...
        'ClipLimit',0.02,'NumTiles',[8 8]));
end

%% DENOISING 

denoised = zeros(size(img));

for i = 1:3
    denoised(:,:,i) = im2double( ...
        medfilt2(uint8(clahe_enhanced(:,:,i)*255)));
end

%% SHARPENING 

sharpened = imsharpen(denoised,'Radius',2,'Amount',1);
sharpened = min(max(sharpened,0),1);

%% CONTRAST 

contrast_stretched = zeros(size(img));

for i = 1:3
    contrast_stretched(:,:,i) = imadjust(sharpened(:,:,i));
end

%% HISTOGRAM EQUALIZATION 

hist_equalized = zeros(size(img));

for i = 1:3
    hist_equalized(:,:,i) = im2double( ...
        histeq(uint8(contrast_stretched(:,:,i)*255)));
end

%%  EDGE DETECTION 

gray_final = rgb2gray(hist_equalized);
edges = edge(gray_final,'Canny');

%%  Images of all the steps 
figure('Name','Image Processing Stages');

subplot(2,4,1); imshow(img); title('Original');
subplot(2,4,2); imshow(clahe_enhanced); title('CLAHE');
subplot(2,4,3); imshow(denoised); title('Denoised');
subplot(2,4,4); imshow(sharpened); title('Sharpened');
subplot(2,4,5); imshow(contrast_stretched); title('Contrast');
subplot(2,4,6); imshow(hist_equalized); title('Hist Equalized');
subplot(2,4,7); imshow(edges); title(sprintf('Edges (%d)', sum(edges(:))));

%% Histogram of all the images 
figure('Name','Histograms');

subplot(2,2,1);
imhist(rgb2gray(img)); title('Original');

subplot(2,2,2);
imhist(rgb2gray(clahe_enhanced)); title('CLAHE');

subplot(2,2,3);
imhist(rgb2gray(contrast_stretched)); title('Contrast');

subplot(2,2,4);
imhist(rgb2gray(hist_equalized)); title('Final');

%% Final comparisn 
figure('Name','Original vs Final Enhanced');

subplot(1,2,1);
imshow(img);
title('Original Image');

subplot(1,2,2);
imshow(hist_equalized);
title('Final Enhanced Image');

%% Metrics after processing
fprintf('Metrics after processing image\n');

img_uint8 = uint8(img*255);
hist_uint8 = uint8(hist_equalized*255);

diff = double(img_uint8(:)) - double(hist_uint8(:));
mse = mean(diff.^2);

psnr_val = 20 * log10(255 / sqrt(mse + eps));

laplacian_kernel = [0 -1 0; -1 4 -1; 0 -1 0];
laplacian_img = imfilter(hist_equalized, laplacian_kernel,'replicate');
laplacian_var = var(laplacian_img(:));

fprintf('✓ MSE: %.4f\n', mse);
fprintf('✓ PSNR: %.2f dB\n', psnr_val);
fprintf('✓ Laplacian Variance: %.4f\n', laplacian_var);

%% Saving reasult
imwrite(uint8(clahe_enhanced*255), [outputFolder 'Image4_CLAHE.jpg']);
imwrite(uint8(denoised*255), [outputFolder 'Image4_Denoised.jpg']);
imwrite(uint8(sharpened*255), [outputFolder 'Image4_Sharpened.jpg']);
imwrite(uint8(hist_equalized*255), [outputFolder 'Image4_Enhanced.jpg']);
imwrite(edges, [outputFolder 'Image4_Edges.jpg']);

saveas(figure(1), [outputFolder 'Image4_Images.png']);
saveas(figure(2), [outputFolder 'Image4_Histograms.png']);

