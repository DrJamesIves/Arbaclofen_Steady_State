# READ ME: Arbaclofen Steady State Pipeline
Preprocessing and basic SNR then FFT/PLV of steady state data for the Arbaclofen trials.
## Background
Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com<br />
For: Arbaclofen RCT project 
-	[https://www.bbk.ac.uk/school/psychological-sciences/research/scalable-transdiagnostic-early-assessment-of-mental-health](https://www.aims-2-trials.eu/our-research/testing-new-medicines/medicine-social-difficulties/)
<!-- end of the list -->
Date: 22nd January 2024<br />
Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html<br />
Open to collaboration—feel free to contact me!<br />
## Goal
Process the EEG data from raw and complete some basic analyses (fft/itpc).
## Prerequisites
All scripts are written in MATLAB and expect EEG data in a semi-processed FieldTrip format, with raw data initially in TaskEngine format. Preprocessing is done using EEGLAB as I am not familiar with FieldTrip preprocessing.
## Optional
### sanity_check_arbaclofen.m
An optional sanity check that:
-	Verifies save names, sample numbers, event counts, and event types.
-	Breaks down ASSR vs. SSVEP events, showing burst durations for ASSR events.
<!-- end of the list -->
## Step 1 – Preprocessing
### eeg_clean.m
This MATLAB script automates the preprocessing of EEG data stored in FieldTrip format, aiming to clean data by removing noise.
Features:
-	Batch Processing: Processes multiple EEG files in a directory.
-	Data Conversion: Converts FieldTrip data to EEGLAB format.
-	Preprocessing:
	-	Bandpass filter (0.1–48 Hz) and notch filter (50 Hz).
	-	Identifies and rejects noisy channels.
	-	Interpolates noisy or bridged channels.
	-	Rejects noisy data segments based on percentage thresholds.
-	Flexible Settings: Customizable filter settings and rejection thresholds.
-	Channel Management: Ensures accurate channel labels for Enobio 20 systems.
-	Data Quality Metrics: Outputs data quality information, including rejected channels and segments.
<!-- end of the list -->
Folder Structure
-	Root Path: E:\Birkbeck\Arbaclofen\
-	Raw Data: E:\Birkbeck\Arbaclofen\Raw_data – Input directory for raw EEG files.
-	Preprocessed Data: E:\Birkbeck\Arbaclofen\Preprocessed_data – Output for cleaned EEG data.
-	Rejected Data: E:\Birkbeck\Arbaclofen\Rejected_data – Stores files rejected due to excessive noise.
<!-- end of the list -->
Prerequisites
-	MATLAB with the EEGLAB toolbox.
-	FieldTrip-compatible EEG data.
-	Enobio 20 channel location file (Enobio20Arbaclofen.loc) and 10-5 system coordinates file (standard-10-5-cap385.elp) in the root path.
<!-- end of the list -->
Usage
1.	Place raw EEG files in the Raw_data directory.
2.	Configure preprocessing settings in the script (filter ranges, rejection thresholds, etc.).
3.	Run the script in MATLAB.
4.	Check the output directories for preprocessed files and inspect any rejected files.
<!-- end of the list -->
## Step 2 – Analysis
In this step, FFT and ITPC are calculated, including a signal-to-noise ratio (SNR) calculation for FFT spikes. Run steady_state_analysis_vssr and steady_state_analysis_assr for the analysis. To isolate channels for regional analysis, run isolate_chans_and_save. Use group_fft_stats and group_itpc_stats to calculate group statistics, and run plot_itpc for ITPC plots.
### steady_state_analysis_assr.m
Purpose:
Processes EEG data to detect and analyse steady-state responses (ASSR) in 10 Hz and 40 Hz frequency trials. Outputs include FFT, SNR, ITPC data, and PowerPoint presentations for visualisation.
Key Features:
1.	Settings:
	-	Highpass: 0.1 Hz, Lowpass: 48 Hz, Trial Duration: 1000 ms, Trial Type: Audio
2.	Paths:
	-	Root Data: E:\Birkbeck\Arbaclofen (update to your folder)
	-	Saves ITPC, FFT, SNR, and presentations in specified subfolders.
3.	Pipeline Overview:
	-	Processes EEG files (skips analysed files).
	-	Epochs data based on event markers (40 for 10 Hz and 41 for 40 Hz).
	-	Detects short trials, concatenates and averages trials.
	-	Runs FFT, SNR, and ITPC analysis.
4.	Output:
	-	Two PowerPoint presentations: concatenated_trials.pptx and averaged_freq_trials.pptx.
	-	Saves ITPC, FFT, and SNR results.
5.	Modular Functions:
	-	fft_snr, itpc_snr, createPresentation.
<!-- end of the list -->
### steady_state_analysis_vssr.m
Purpose:
Processes EEG data for steady-state responses in VSSR trials, performing event filtering, trial epoching, data concatenation, and FFT/SNR/ITPC calculation.
Key Features:
1.	Settings: Defines filter limits, trial duration, and paths.
2.	Path Management: Ensures required directories exist.
3.	Data Processing: Loads and filters EEG data, segments into epochs, concatenates trials.
4.	Analysis: Runs FFT/SNR and ITPC calculations.
5.	Results Storage: Saves FFT, SNR, ITPC data in structured arrays.
6.	Visualisation: Optionally generates PowerPoint presentations.
7.	Clean-Up: Clears intermediate variables.
<!-- end of the list -->
Usage:
Designed for VSSR EEG data analysis, automating trial segmentation, data concatenation, and frequency-based analysis.
### fft_snr
Purpose:
Calculates FFT and SNR of EEG data for frequency-domain analysis.
Key Features:
1.	Inputs: PowerPoint object, root directory, EEG data, sampling frequency, frequency bounds, title, and plot flag.
2.	Steps: Processes single or multiple data segments, calculates FFT and SNR, and saves results.
3.	Output: SNR plot in PowerPoint, FFT data saved in FFT_data folder, SNR results in SNR_data folder.
<!-- end of the list -->
### itpc and itpc_gpu
Purpose:
Calculates inter-trial phase coherence (ITPC) for EEG data, quantifying phase alignment across trials.
Key Features:
1.	Inputs: Save path, title, EEG data structure, frequency bounds, and plot flag.
2.	Steps: Decomposes EEG data using Morlet wavelets, computes ITPC, saves results, and optionally generates plots.
3.	Output: ITPC data saved as .mat file. Optionally generates time-frequency and frequency-only plots.
<!-- end of the list -->
### group_fft_stats
Purpose:
Calculates and saves group statistics for SNR data, generating visual summaries in PowerPoint.
Key Features:
1.	Directory Setup: Defines paths for input/output, creates necessary folders.
2.	Data Processing: Loads SNR data, extracts key factors (Hz, site, test/retest).
3.	Group Statistics: Computes mean SNR power by frequency, site, and test/retest status.
4.	Visualisation: Generates plots for individual and grouped factors, adds them to PowerPoint.
5.	Results: Saves aggregated SNR data and generates PowerPoint presentation.
<!-- end of the list -->
### group_itpc_stats
This MATLAB function analyzes Inter-Trial Phase Coherence (ITPC) data and computes statistics for grouped conditions. It processes and visualizes ITPC averages based on experimental factors.
Purpose:
-	Input: ITPC data in .mat files with filenames encoding experimental conditions (e.g., Hz, site, test/retest status).
-	Processing: Groups and averages ITPC data across conditions.
-	Output:
	-	Grouped ITPC data in .mat files.
	-	PowerPoint slides with ITPC averages.
<!-- end of the list -->
Key Features:
-	Paths Configuration: Specifies directories containing ITPC data.
-	Folder Management: Checks and creates necessary output directories.
-	Data Loading: Reads .mat files, extracts experimental factors, and trims datasets to the same length.
-	Averaging: Computes averages for individual conditions and subgroups.
-	Visualization: Generates PowerPoint slides summarizing ITPC averages.
<!-- end of the list -->
### isolate_and_save_chans.m
Purpose: Isolates specified EEG channels for FFT, SNR, and ITPC analyses, then saves the results into new directories. Optionally plots and saves these results to PowerPoint.
Key Features:
-	Channel Settings: Channels of interest are predefined (e.g., 'P7', 'P4').
-	Loop Configuration: Operates on data categories (e.g., 500ms audio, 1000ms video).
-	Data Processing: Isolates channels for analysis and saves results to new directories.
-	Plotting: Optionally generates plots and saves them to PowerPoint.
<!-- end of the list -->
Execution Flow:
1.	Input Directories: Reads data from specified root paths.
2.	Processing: Loads data, isolates channels, and computes metrics (e.g., mean SNR).
3.	Output: Saves processed data and generates PowerPoint presentations.
4.	Visualization: If enabled, plots results and adds them to PowerPoint.
<!-- end of the list -->
Warnings/Errors:
-	Suppresses specific MATLAB warnings.
-	Includes a placeholder error for unhandled cases.
<!-- end of the list -->
Customization:
-	Modify channel groups and switch settings for different analyses.
<!-- end of the list -->
Dependencies:
-	Utility functions (e.g., GenColours, createPresentation, addImgToPresentation).
<!-- end of the list -->
### plot_itpc
Purpose: Generates time-frequency plots of ITPC data and optionally embeds them into a PowerPoint presentation.
Key Features:
-	Inputs:
	-	time_axis: Corresponding time points.
	-	itpc: Precomputed ITPC matrix (frequency x time).
	-	ppt: PowerPoint object for embedding (optional).
	-	inTitle: Title for the plot.
-	Outputs:
	-	fig: MATLAB figure handle for the plot.
	-	ppt: Updated PowerPoint with the embedded plot.
-	Plot Details:
	-	Displays ITPC as a time-frequency heatmap.
	-	Customizable frequency scale and titles.
	-	Log scale for frequency axis.
-	Additional Features:
	-	Saves plots to PowerPoint using addImgToPresentation.
<!-- end of the list -->
