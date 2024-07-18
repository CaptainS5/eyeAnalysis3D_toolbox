# eyeAnalysis3D_toolbox
_Acknowledgement: This toolbox is adapted from the [eye movement analysis scripts](https://github.com/Ookenfooken/Shared-eye-movement-code) used in Miriam Spering's [Oculomotor Lab](http://visualcognition.ca/spering/index.html) at UBC, with a lot of my own contributions and modifications to form the current eye/head analysis._

WIP, but the toolbox should run once you get the raw data pre-processed properly. More details coming later...



## Pre-processing raw data:

`sortRawData.m`: function to reorganize data into the format assumed by the toolbox, including coordinate system transformation, aligning timestamps, and calculating variables when needed.

**Output data format expected:** 
A structure variable `eyeTrial` which has the following fields:
(the coordinate system should be x+ = foward, y+ = left, and z+ = up, right-handed rotation)

- _headAligned_ (table containing the following variables, [`xx`] are optional, depending on what data you have):
    - `qW, qX, qY, qZ`: head orientation quaternions, rotation from a reference frame
    - [`posX, posY, posZ`]: head position in world frame, unit in meters
    - [`frameXYZ`]: head-centered coordinate axes in world coordinates; 3 by 3 matrix, each row is the x, y, and z world coordinates, each column is one basis axis of the head frame (forward, leftward, and upward directions of the head)
    - `timestamp`: difference is the time between frames in seconds
- `eyeAligned` (table containing the following variables, some are optional depending on whether it is available from your data): 
    - *Note that if you are using a video-based eye tracker, please make sure values of all the loss-of-signal frames are NaN instead of other numbers; this will be used for blink detection
    - Cyclopean gaze data:
        - [`eyePosHeadX, eyePosHeadY, eyePosHeadZ`]: eye position in head coordinates, unit in meters
        - [`gazePosHeadX, gazePosHeadY, gazePosHeadZ`]: gaze position in head coordinates, unit in meters
        - [`gazeVecHeadX, gazeVecHeadY, gazeVecHeadZ`]: normalized gaze direction vector in head coordinates
        - `gazeOriHeadX, gazeOriHeadY`: gaze-in-head orientation, azimuth (X, right is positive) and elevation (Y, up is positive), unit in degrees
        - [`eyePosWorldX, eyePosWorldY, eyePosWorldZ`]: eye position in world coordinates, unit in meters
        - [`gazePosWorldX, gazePosWorldY, gazePosWorldZ`]: gaze position in world coordinates, unit in meters
        - [`gazeVecWorldX, gazeVecWorldY, gazeVecWorldZ`]: normalized gaze direction vector in world coordinates
        - `gazeOriWorldX, gazeOriWorldY`: gaze-in-world orientation, azimuth (X, right is positive) and elevation (Y, up is positive), unit in degrees
        - `gazeDepth`: gaze depth in meters
        - [`frameXYZ`]: eye-centered coordinate axes in world coordinates; 3 by 3 matrix, each row is the x, y, and z world coordinates, each column is one basis axis of the eye frame (forward, leftward, and upward directions of the eye)
        - `timestamp`: same as the timestamp in headAligned
    - If you want to keep the original binocular data as well (all optional):
        - [basically everything above (when applicable) with _L or _R to indicate left or right eye]
- `sampleRate` (one number): the sampling rate of eye/head data (eye and head should have identical timestamps; this will be automatically calculated after you organized headAligned and eyeAligned). This is used as a quick reference for choosing filter types later.

Note that I’m using “trial” to label each continuous recording, and generate one .mat for each recording. The pre-processed data files are e.g., data_1.mat, data_2.mat, and I will use the number to index them in later processing as well. Feel free to manage your data in other ways, but at least the data within one “trial” should be continuous in time. Otherwise the filtering or velocity calculation could be messed up when we have gaps (inserting NaN around the gap might solve the issue, better double check first).

## Processing pre-processed data:

`startTrialAnalysis.m`: the starting script to either use the GUI to click through trials and look at  traces (set `autoProcess = 0`), or auto-process all trials without opening the GUI (`autoProcess = 1`). I’d recommend first viewing traces in the GUI to confirm that the filters and classification look reasonable at least for a few trials, do adjustments as needed, then move on to auto-process all data.
- Set `dataPath` (path + file name before the trial number) accordingly
- `loadEyeTrial`: Indicate if you want to re-do filtering (which may take a while) or just load the previously processed data, and plot. Classification will always be re-run
- `currentTrial`: which pre-processed data file to start from
- Set all classification parameters as you’d like
- `plotMode`: if using the GUI, which plots to start with (refer to updatePlot.m). Can go to other plots in the GUI later

**Tips for using the GUI:** TBD


`processTrial.m`: the main function of data processing including filtering, classification, and processing eye movement properties. 

**Steps in processTrial.m:**

_Filtering:_
- `filterHeadTrace.m`:
- `filterEyeTrace.m`:

_Classification:_ classification is done in the order below, see each function for more details and references. `classID` contains the classification of each frame. It is initialized in `findBlink.m`, then updated at each step.
- `findBlink.m`
- `findSaccade.m`
- `findGazeFix.m`
- `findVOR.m`

_Processing eye movement stats:_
- `processBlink.m`
- `processSaccade.m`
- `processGazeFix.m`
- `processVOR.m`