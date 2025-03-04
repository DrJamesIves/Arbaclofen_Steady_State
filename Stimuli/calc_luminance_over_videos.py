#! python3
# calc_luminance_over_videos.py

# Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
# Date: 25th February 2025
# Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
# Open to collaboration—feel free to contact me!

# The purpose of this script is to calculate luminance over each frame of a video
# following a standard formula (https://doi.org/10.1093/cercor/bhm107 or
# https://doi.org/10.1016/j.neuroimage.2019.116060)

# Gives the option for: skipping initial frames (good if there are wait screens to be avoided),
# excluding portions of the video (good for excluding picture in picture), and running luminance
# calculations on a frame by frame basis or over time to match another datastream. E.g. if
# matching a 1000Hz EEG signal to a 50 fps video, then luminance calculations will be repeated
# at 20 times per frame so that the resulting data has the same sampling rate as the EEG.

# Requires ffmpeg and as a result can take pretty much any video format, just need to
# change the extension below.

import cv2, ffmpeg, math, os
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from tqdm import tqdm

# Paths
# video_folder = r"E:\Birkbeck\Entrainment project\24m\2.3 Epoched_Screenflows\Steady state"
# output_folder = r"E:\Birkbeck\Entrainment project\24m\3.3 Preprocessed_Screenflows\Steady state\Luminance"
video_folder = r"C:\Users\james\Videos\TRF\Stimuli"
output_folder = r"C:\Users\james\Videos\TRF\Preprocessed_stimuli"

# Create output folder if it doesn't exist
os.makedirs(output_folder, exist_ok=True)

### Settings
# Skip initial frames, in this case the videos have been epoched with one waiting screen frame
skip_starting_frames = 0  
run_luminance_over_time = True      # Calculate luminance over time rather than just by frame
sampling_rate = 1000                # Sampling rate for EEG sync

# Video exclusions: format is (x, y, w, h)
use_video_exclusions = False         # To exclude an area (or multiple areas) of the screen
video_exclusions = {                # There are multiple sizes of video to handle
    "hd": [(1250, 690, 641, 361)],  # Example exclusion region
    "sd": [(718, 394, 242, 146)]
}

# File type
file_type = ".mov"

# Get list of video files
video_files = [f for f in os.listdir(video_folder) if f.endswith(file_type)]

# Process each video
for v, video_name in enumerate(tqdm(video_files, desc="Processing Videos")):
    # Check that this file hasn't already been processed
    output_file = os.path.join(output_folder, f"{video_name[:-4]}_luminance.csv")
    #     if os.path.exists(output_file):
    #         continue

    # Open the video
    video_path = os.path.join(video_folder, video_name)
    cap = cv2.VideoCapture(video_path)

    # Check that the video has opened and if not continue
    if not cap.isOpened():
        print(f"Error opening video: {video_name}")
        continue

    # Get the video fps rate
    video_info = ffmpeg.probe(video_path)
    fps = 30
#     fps = eval(next(s for s in video_info['streams'] if s['codec_type'] == 'video')['r_frame_rate'])

    # Calc number of samples needed per frame
    # Use floor as additions can be included later
    if run_luminance_over_time:
        num_samples_per_frame = math.floor((1/fps) / (1/sampling_rate));
        
    # Set up empty starting containers
    luminance_values = []
    frame_idx = 0
    added_frames = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_idx += 1
        if frame_idx <= skip_starting_frames:
            continue
        
        # Converts the image to a float32 type and scales pixel values to the range [0, 1]. The image remains a three-channel (color) image.
        frame = frame.astype(np.float32) / 255  # Normalize
        luminance = 0.2126 * frame[:, :, 2] + 0.7152 * frame[:, :, 1] + 0.0722 * frame[:, :, 0]

        # Apply exclusions
        if use_video_exclusions:
            if np.shape(frame) == (1080, 1920, 3):
                for (x, y, w, h) in video_exclusions.get("hd", []):
                    luminance[y:y+h, x:x+w] = np.nan  # Mask excluded area
            elif np.shape(frame) == (540, 960, 3):
                for (x, y, w, h) in video_exclusions.get("sd", []):
                    luminance[y:y+h, x:x+w] = np.nan  # Mask excluded area
            else:
                raise ValueError(f"Unexpected video resolution: {np.shape(frame)}")

        # Calc average luminance
        avg_luminance = np.nanmean(luminance)  # Ignore excluded areas

        # if running temporally rather than by frame then calculate the number of samples needed
        if run_luminance_over_time:
            # Add required samples per frame
            for i in range(num_samples_per_frame):
                luminance_values.append(avg_luminance)
            
            # Calc the expected number of luminance samples
            # Find the expected number of frames (frame_idx - skip_starting_frames)
            # Divide by the fps to get the time in seconds
            # Multiply by the EEG sampling rate to get the expected number of samples to match the EEG sampling rate
            exp_luminance_samples = ((frame_idx - skip_starting_frames) / fps) * sampling_rate
            
            # If behind by a whole sample then add an extra sample
            if len(luminance_values) + 1 <= exp_luminance_samples:
#                 print(f'Expected:{exp_luminance_samples}\tActual:{len(luminance_values)}\t')
                luminance_values.append(avg_luminance)
#                 added_frames += 1
        else:
            luminance_values.append(avg_luminance)

    cap.release()
#     print(f'Num added frames for {video_name}: {added_frames}')

    # Save luminance values to CSV
    if len(luminance_values) > 0:
        pd.DataFrame(luminance_values).to_csv(output_file, index=False, header=["Luminance"])
    #     print(f"Saved: {output_file}")

        # Plot luminance
        plt.figure()
        plt.plot(luminance_values)
        plt.xlim([0, len(luminance_values)])
        if run_luminance_over_time:
            plt.xlabel("Time (ms)")
            plt.title(f"Luminance over time for {video_name[:-4]}")
        else:
            plt.xlabel("Frame")
            plt.title(f"Luminance over frame for {video_name[:-4]}")
        plt.ylabel("Luminance")
        plt.grid(True)
        plt.savefig(os.path.join(output_folder, f"{video_name[:-4]}_luminance.png"))
        plt.close()

print("All videos processed successfully.")
