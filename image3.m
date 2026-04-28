clear; close all; clc;

path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path);

% Paths
imagePath = 'Assets/Image3.bmp';
outputFolder = 'Output/Image3/';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end


%% Read Image
img = imread(imagePath);
if size(img,3) == 3
    img = rgb2gray(img);
end
img = im2double(img);

figure('Name','Denoising Comparison');

subplot(2,3,1);
imshow(img);
title('Original (Noisy)');

%% Gaussian Filter
gaussian_filtered = imgaussfilt(img, 2);

subplot(2,3,2);
imshow(gaussian_filtered);
title('Gaussian');

%% STEP 3: Median Filter
median_filtered = medfilt2(img, [3 3]);

subplot(2,3,3);
imshow(median_filtered);
title('Median');

%% Non-Local Means
try
    nlm_filtered = imnlmfilt(img, 'DegreeOfFiltering', 0.05);
catch
    warning('NLM not available, using Gaussian fallback');
    nlm_filtered = imgaussfilt(img, 1.5);
end

subplot(2,3,4);
imshow(nlm_filtered);
title('NLM');

%% PSNR Calculations
psnr_gauss = psnr(gaussian_filtered, img);
psnr_median = psnr(median_filtered, img);
psnr_nlm   = psnr(nlm_filtered, img);

fprintf('Gaussian PSNR: %.2f dB\n', psnr_gauss);
fprintf('Median   PSNR: %.2f dB\n', psnr_median);
fprintf('NLM      PSNR: %.2f dB\n', psnr_nlm);

%% Best method
[best_psnr, idx] = max([psnr_gauss, psnr_median, psnr_nlm]);
methods = {'Gaussian','Median','NLM'};
best_method = methods{idx};

fprintf('\nBest Method: %s (%.2f dB)\n', best_method, best_psnr);

%% Plot comparison
subplot(2,3,5);
bar([psnr_gauss, psnr_median, psnr_nlm]);
set(gca,'XTickLabel',methods);
ylabel('PSNR (dB)');
title('PSNR Comparison');
grid on;

subplot(2,3,6);
text(0.1,0.8,sprintf(['Gaussian: %.2f dB\nMedian: %.2f dB\nNLM: %.2f dB\n\nBest: %s'], ...
    psnr_gauss, psnr_median, psnr_nlm, best_method));
axis off;

%% Save results
imwrite(gaussian_filtered, fullfile(outputFolder,'Gaussian.jpg'));
imwrite(median_filtered,   fullfile(outputFolder,'Median.jpg'));
imwrite(nlm_filtered,      fullfile(outputFolder,'NLM.jpg'));