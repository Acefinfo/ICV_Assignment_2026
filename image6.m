%==========================================================================
% IMAGE 6: COLOR CORRECTION AND IMAGE ENHANCEMENT PIPELINE
%==========================================================================
% Problem: Blur, noise, low contrast, drab colors
% Solution: Gamma + white balance + color analysis
%==========================================================================
 
clc; clear; close all;

%% Path setup
path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path);

imagePath = 'Assets/Image6.jpg';
outputFolder = fullfile('Output','Image6');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Load image
img = im2double(imread(imagePath));

if size(img,3)==1
    img = repmat(img,[1 1 3]);
end

%% White Balance
meanRGB = mean(reshape(img, [], 3));
avgMean = mean(meanRGB);

wb = img;
for c = 1:3
    wb(:,:,c) = img(:,:,c) * (avgMean / (meanRGB(c) + eps));
end
wb = min(max(wb,0),1);

%% Dehazing
dark = min(wb,[],3);
flat_dark = dark(:);
[~, idx] = sort(flat_dark, 'descend');
topPixels = idx(1:round(0.001 * numel(flat_dark)));

A = mean(wb(topPixels));

t = 1 - 0.9 * dark ./ (A + eps);
t = max(t, 0.5);

dehazed = zeros(size(wb));
for c = 1:3
    dehazed(:,:,c) = (wb(:,:,c) - A) ./ t + A;
end
dehazed = min(max(dehazed,0),1);

%% Contrast
enhanced = imadjust(dehazed, stretchlim(dehazed, [0.01 0.99]), []);

%% Sharpen
final = imsharpen(enhanced, 'Radius',1.2,'Amount',1.2);

%% FIGURE 1: ALL PROCESS STEPS

figure('Name','Processing Pipeline','NumberTitle','off');

subplot(2,3,1); imshow(img); title('Original');
subplot(2,3,2); imshow(wb); title('White Balanced');
subplot(2,3,3); imshow(dehazed); title('Dehazed');
subplot(2,3,4); imshow(enhanced); title('Contrast Enhanced');
subplot(2,3,5); imshow(final); title('Final Enhanced');

%% FIGURE 2: HISTOGRAM

figure('Name','Histogram','NumberTitle','off');
imhist(rgb2gray(final));
title('Final Image Histogram');


%% FIGURE 3: BEFORE vs AFTER

figure('Name','Original vs Final','NumberTitle','off');

subplot(1,2,1);
imshow(img);
title('Original');

subplot(1,2,2);
imshow(final);
title('Final Enhanced');

%% METRICS

orig_gray = rgb2gray(img);
final_gray = rgb2gray(final);

% PSNR
mse = mean((orig_gray(:) - final_gray(:)).^2);
psnr_val = 10 * log10(1 / (mse + eps));

% SSIM
ssim_val = ssim(final_gray, orig_gray);

% Laplacian Variance (Sharpness)
lap = del2(final_gray);
lap_var = var(lap(:));

fprintf('\n=== IMAGE QUALITY METRICS ===\n');
fprintf('PSNR: %.2f dB\n', psnr_val);
fprintf('SSIM: %.4f\n', ssim_val);
fprintf('Laplacian Variance (Sharpness): %.6f\n', lap_var);


%% SAVE ALL IMAGES

imwrite(img, fullfile(outputFolder,'Original.jpg'));
imwrite(wb, fullfile(outputFolder,'WhiteBalanced.jpg'));
imwrite(dehazed, fullfile(outputFolder,'Dehazed.jpg'));
imwrite(enhanced, fullfile(outputFolder,'ContrastEnhanced.jpg'));
imwrite(final, fullfile(outputFolder,'FinalEnhanced.jpg'));

saveas(figure(1), fullfile(outputFolder,'Pipeline.png'));
saveas(figure(2), fullfile(outputFolder,'Histogram.png'));
saveas(figure(3), fullfile(outputFolder,'Comparison.png'));



