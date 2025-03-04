#! python3
# calc_motion_over_videos.py

# Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
# Date: 25th February 2025
# Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
# Open to collaboration—feel free to contact me!

# The purpose of this script is to calculate motion over each frame of a video
# following a standard formula (https://doi.org/10.1016/j.neuroimage.2019.116060)

# Gives the option for: skipping initial frames (good if there are wait screens to be avoided),
# excluding portions of the video (good for excluding picture in picture), and running motion
# calculations on a frame by frame basis or over time to match another datastream. E.g. if
# matching a 1000Hz EEG signal to a 50 fps video, then motion calculations will be repeated
# at 20 times per frame so that the resulting data has the same sampling rate as the EEG.

# Requires ffmpeg and as a result can take pretty much any video format, just need to
# change the extension below.

import cv2, ffmpeg, math, os
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from tqdm import tqdm

# Define the root directory based on OS
if os.name == 'nt':  # Windows
    disk_letter = 'E'
    root_dir = os.path.join(disk_letter + ':', 'Birkbeck')
elif os.name == 'posix':  # Linux/Mac
    disk_name = 'Zebrafish'
    root_dir = os.path.join('/media', 'babita', disk_name, 'Birkbeck')

root = os.path.join(root_dir, 'Entrainment project', '24m')
video_folder = os.path.join(root, '2.3 Epoched_Screenflows', 'Steady state')
output_folder = os.path.join(root, '3.3 Preprocessed_Screenflows', 'Steady state', 'Motion')

video_folder = r"C:\Users\james\Videos\TRF\Stimuli"
output_folder = r"C:\Users\james\Videos\TRF\Preprocessed_stimuli\Motion"

# Create output folder if it doesn't exist
os.makedirs(output_folder, exist_ok=True)

# Settings
skip_starting_frames = 0  # Skip initial frames
run_luminance_over_time = True  # Calculate motion over time rather than just by frame
motion_threshold = 10  # Threshold to filter out noise
sampling_rate = 1000  # Sampling rate for EEG sync

# Video exclusions: format is (x, y, w, h)
use_video_exclusions = False
video_exclusions = {
    "hd": [(1248, 688, 643, 363)],
    "sd": [(717, 393, 243, 147)]
}

# File type
file_type = ".mov"

# Get list of video files
video_files = [f for f in os.listdir(video_folder) if f.endswith(file_type)]

# Process each video
for video_name in tqdm(video_files, desc="Processing Videos"):
    output_file = os.path.join(output_folder, f"{video_name[:-4]}_motion.csv")

    # Open the video
    video_path = os.path.join(video_folder, video_name)
    cap = cv2.VideoCapture(video_path)

    # Check video is open
    if not cap.isOpened():
        print(f"Error opening video: {video_name}")
        continue

    # Set up
    prev_frame = None
    motion_values = []
    frame_idx = 0

    # Get the video fps rate
    #     video_info = ffmpeg.probe(video_path)
    #     fps = eval(next(s for s in video_info['streams'] if s['codec_type'] == 'video')['r_frame_rate'])
    fps = cap.get(cv2.CAP_PROP_FPS)

    # Calc number of samples needed per frame
    # Use floor as additions can be included later
    if run_luminance_over_time:
        num_samples_per_frame = math.floor((1/fps) / (1/sampling_rate));

    # Loop through all frames
    while cap.isOpened():
#     for i in range(410):
        ret, frame = cap.read()
        if not ret:
            break

        # Count the frames and ignore any frames that need to be skipped
        frame_idx += 1
        if frame_idx <= skip_starting_frames:
            continue

        # Convert frame to grayscale
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)  # Convert to grayscale

        # Apply picture in picture exclusions
        if use_video_exclusions:
            if np.shape(frame) == (1080, 1920, 3):
                for (x, y, w, h) in video_exclusions.get("hd", []):
                    gray_frame[y:y+h, x:x+w] = 0 #np.nan
            elif np.shape(frame) == (540, 960, 3):
                for (x, y, w, h) in video_exclusions.get("sd", []):
                    gray_frame[y:y+h, x:x+w] = 0 #np.nan
            else:
                raise ValueError(f"Unexpected video resolution: {np.shape(frame)}")

        # Used to check what the frames look like
#         cv2.imshow('Frame', frame)
#         cv2.waitKey(0)
#         cv2.imshow('Gray frame', gray_frame)
#         cv2.waitKey(0)

        if prev_frame is not None:
            # Compute absolute difference
            frame_diff = cv2.absdiff(prev_frame, gray_frame)
            
#             cv2.imshow('Frame_diff', frame_diff)
#             cv2.waitKey(0)
#             cv2.destroyAllWindows()
            
            # Replace all values in frame_diff below the motion threshold with 0
            frame_diff[frame_diff < motion_threshold] = 0

            # Calculate the average motion from the remaining frame_diff values
            avg_motion = np.mean(frame_diff)  # No need to check for significant motion anymore, since we've zeroed out small differences

            
            if run_luminance_over_time:
                motion_values.extend([avg_motion] * num_samples_per_frame)
                
                # Calc the expected number of luminance samples
                # Find the expected number of frames (frame_idx - skip_starting_frames)
                # Divide by the fps to get the time in seconds
                # Multiply by the EEG sampling rate to get the expected number of samples to match the EEG sampling rate
                exp_num_samples = ((frame_idx - skip_starting_frames) / fps) * sampling_rate
                
                # If behind by a whole sample then add an extra sample
                if len(motion_values) + 1 <= exp_num_samples:
                    motion_values.append(avg_motion)
            else:
                motion_values.append(avg_motion)

        prev_frame = gray_frame

    cap.release()
    
    # Save motion values to CSV
    if len(motion_values) > 0:
        pd.DataFrame(motion_values).to_csv(output_file, index=False, header=["Motion"])
        
        # Plot motion
        plt.figure()
        plt.plot(motion_values)
        plt.xlabel("Time (ms)" if run_luminance_over_time else "Frame")
        plt.ylabel("Motion")
        plt.title(f"Motion over {'time' if run_luminance_over_time else 'frames'} for {video_name[:-4]}")
        plt.grid(True)
        plt.savefig(os.path.join(output_folder, f"{video_name[:-4]}_motion.png"))
        plt.close()

print("All videos processed successfully.")
