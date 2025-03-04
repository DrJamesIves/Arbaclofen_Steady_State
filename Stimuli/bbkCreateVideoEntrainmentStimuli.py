#! python3
# bbkCreateVideoEntrainmentStimuli.py

# ------------------------------------------------------------------------------------------------------
# Author: James Ives
# Email: james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
# Date: 15th March 2024
# 
# This script was written by James Ives and is released under the GNU General Public License v3.0. 
# 
# You are free to redistribute and/or modify this script under the terms of the GNU General Public 
# License as published by the Free Software Foundation, either version 3 of the License, or (at 
# your option) any later version.
# 
# This script is provided "as-is" without any warranty; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more 
# details: https://www.gnu.org/licenses/gpl-3.0.html
# 
# I am happy to collaborate on any projects related to this script. 
# Feel free to contact me at the email addresses provided.
# -----------------------------------------------------------------------------------------------------


# This script creates abrupt onset/offset visual steady state stimuli using still images. Steady state videos
# are created with black frames in between. Screen time for the images and black frames are the same. This
# script takes in a folder of images, and an output folder where the video stimuli will be created. Images are
# distributed evenly throughout the video.

# The script assumes that ffmpeg and moviepy have been installed and set up.

# Settings include:
    # duration of the clip in seconds
    # the frequency of the flashing in Hz
    # screen refresh rate in Hz
    # output video format
    # screen resolution in pixels
    
# If the target frequency chosen does not align with the screen refresh rate then images will not be displayed
# properly. E.g. if the refresh rate is 144Hz and a 10Hz target frequency is chosen then the screen will try to
# change the image every 14.4 frames, screens work in whole frames only. So it is likely that your image will be
# displayed early 2/5 of the time, late 2/5 of the time and on time 1/5 of the time. To correct for this, this
# script calculates the closest frequency that divides perfectly into the refresh rate and changes the target
# frequency. This is printed to shell.

# With macs especially, you should check not only the screen refresh rate but whether the screen settings allow
# it to actually refresh at the rate you are expecting.
    

import logging, math, os
from moviepy.editor import *

def create_stimulus_video(image_folder, output_path, duration, stimulus_frequency, screen_refresh_rate=144, output_format='mp4', screen_res=(1920, 1080)):
   
    # Get all image files from the folder
    image_files = [f for f in os.listdir(image_folder) if os.path.isfile(os.path.join(image_folder, f))]

    # Frame calculations
    total_frames = screen_refresh_rate * duration
    # Calculate the number of frames for each image
    total_stimulus_frames = round(total_frames / len(image_files))
    # Calculate the stimulus duration
    total_stimulus_duration = duration / len(image_files)
    # Calculate how many frames before flashing image on or off
    stimulus_frequency_frames = total_stimulus_frames / (stimulus_frequency * total_stimulus_duration * 2)

    # The stimulus_frequency_frames rate is required to be a whole number. If not then a new
    # corrected stimulus frequency is calculated and used.
    if stimulus_frequency_frames != round(stimulus_frequency_frames):
        # Calculate the closest stimulus frequency that divides into the screen refresh rate
        stimulus_frequency = total_stimulus_frames / (round(stimulus_frequency_frames) * total_stimulus_duration * 2)
        # Recalculate above variables
        stimulus_frequency_frames = total_stimulus_frames / (stimulus_frequency * total_stimulus_duration * 2)

        logging.warning(f"Stimulus frequency does not divide into the screen refresh rate.\nCorrected stimulus frequency is now: {stimulus_frequency}Hz")


    # Calculate number of flash cycles, if there are more cycles than the assign duration then go over
    num_flash_cycles = math.ceil(total_stimulus_frames / (stimulus_frequency_frames * 2))
    # Flash duration in seconds
    flash_duration = stimulus_frequency_frames / screen_refresh_rate
    # Calculate total duration in seconds
    total_stimulus_duration = flash_duration * num_flash_cycles * 2

    # Initialize variables
    total_duration = 0
    clips = []

    # Loop through image files
    for image_file in image_files:
        # Load image clip
        image_path = os.path.join(image_folder, image_file)
        image_clip = ImageClip(image_path).set_duration(flash_duration)
        black_clip = ColorClip(screen_res, color=(0, 0, 0)).set_duration(flash_duration)

        # Create the flashing sequence for the image
        image_flashes = []
        
        for _ in range(num_flash_cycles):
            # Add a black screen clip for each flash
            image_flashes.append(image_clip)
            image_flashes.append(black_clip)
        
        # Concatenate flashes to create the repeated flashing sequence for each image
        repeated_image_clip = concatenate_videoclips(image_flashes)
        # Add the repeated flashing sequence to the final clips
        clips.append(repeated_image_clip)
        total_duration += total_stimulus_duration

    # Concatenate clips to create the final video
    final_clip = concatenate_videoclips(clips)

    # Add black border around the images
    final_clip = final_clip.on_color(size=screen_res, color=(0, 0, 0))

    # Write the video to the specified output path
    final_output_path = output_path + 'Test.' + output_format
    final_clip.write_videofile(final_output_path, fps=screen_refresh_rate, codec='libx264')

    print(f"Stimulus video created: {final_output_path}")
    
    
# Example usage
image_folder = 'F:\\Entrainment stims\\entrain_stimuli\\Test\\' #"path/to/your/image/folder"
output_path = 'F:\\Entrainment stims\\entrain_stimuli\\Test output\\' #"path/to/output/video"
duration = 15  # seconds
stimulus_frequency = 1.5  # Hz
create_stimulus_video(image_folder, output_path, duration, stimulus_frequency, output_format='mp4')