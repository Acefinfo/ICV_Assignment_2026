clear all; close all; clc;

%% Initial path setup for root folder and loading assets
path = "C:\Users\DELL\Desktop\ICV_Assignment";
cd(path);


sequencePath = 'Assets/FrameSeq1/';
outputFolder = 'Output/Sequence_Video/';
videoOutputPath = 'Output/Sequence_Video/ProcessedSequence.avi';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

fprintf('\n=== Enhanced image to video ===\n\n');

% Get image files
imgfiles = dir([sequencePath '*.jpg']);
if isempty(imgfiles)
    imgfiles = dir([sequencePath '*.png']);
end

num_frames = length(imgfiles);
fprintf('Total frames found: %d\n', num_frames);

if num_frames == 0
    error('No images found!');
end

% Sort files correctly
[~, idx] = sort({imgfiles.name});
imgfiles = imgfiles(idx);

%% Video writer
videoWriter = VideoWriter(videoOutputPath, 'Motion JPEG AVI');
videoWriter.FrameRate = 30;
videoWriter.Quality = 100;
open(videoWriter);

fprintf('Generating video from frames... \n\n');

% Stats
all_frames = [];
frame_count = 0;

% Temporal smoothing variables
prev_frame = [];
alpha = 0.2;   % smoothing strength (0 = no smoothing, 1 = no memory)

%% Processing images 
fig = figure('Name','Processing','NumberTitle','off');

for i = 1:num_frames
    
    % Read image
    frame = im2double(imread(fullfile(sequencePath, imgfiles(i).name)));

    % Ensure RGB
    if size(frame,3) == 1
        frame = cat(3, frame, frame, frame);
    end

    % IMAGE PROCESSING PIPELINE

    % Advanced denoising (best for sequences)
    denoised = imnlmfilt(frame);

    % Gamma correction (natural brightness)
    gamma_corrected = imadjust(denoised, [], [], 0.9);

    % Convert to LAB color space
    lab = rgb2lab(gamma_corrected);
    L = lab(:,:,1) / 100;

    % Soft CLAHE (avoid flicker)
    L = adapthisteq(L, ...
        'ClipLimit', 0.01, ...
        'NumTiles', [8 8]);

    lab(:,:,1) = L * 100;
    enhanced = lab2rgb(lab);

    % Edge-preserving sharpening
    sharpened = imsharpen(enhanced, ...
        'Radius', 1.2, ...
        'Amount', 0.6);

    % Contrast normalization
    final_frame = imadjust(sharpened, [0.02 0.98], []);

    % Clamp values
    final_frame = min(max(final_frame,0),1);

    % ==============================
    % TEMPORAL SMOOTHING
    % ==============================
    if ~isempty(prev_frame)
        final_frame = alpha * final_frame + (1 - alpha) * prev_frame;
    end

    prev_frame = final_frame;

    % Write frame to video
    writeVideo(videoWriter, im2uint8(final_frame));

    % Collect stats
    all_frames = [all_frames; final_frame(:)];
    frame_count = frame_count + 1;

    % Progress display
    if mod(i,30)==0 || i==1 || i==num_frames
        fprintf('Processed %d/%d (%.1f%%)\n', ...
            i, num_frames, (i/num_frames)*100);
        imshow(final_frame);
        title(['Frame ', num2str(i)]);
        drawnow;
    end
end

% Close video
close(videoWriter);

fprintf('\n✓ Video created successfully!\n');
fprintf('Frames: %d\n', frame_count);
fprintf('Duration: %.2f sec\n', frame_count/30);

% ==============================
% STATISTICS
% ==============================

mean_intensity = mean(all_frames);
std_intensity = std(all_frames);

fprintf('\nStatistics:\n');
fprintf('Mean: %.4f\n', mean_intensity);
fprintf('Std: %.4f\n', std_intensity);

%% SAVE SAMPLE FRAMES

vReader = VideoReader(videoOutputPath);
sample_interval = ceil(vReader.NumFrames / 6);

for k = 1:6
    frame_num = (k-1)*sample_interval + 1;

    if frame_num <= vReader.NumFrames
        vReader.CurrentTime = (frame_num-1)/vReader.FrameRate;
        sample = readFrame(vReader);

        filename = sprintf('Sample_%02d.jpg', k);
        imwrite(sample, fullfile(outputFolder, filename));
    end
end


saveas(fig, fullfile(outputFolder,'Progress.png'));

