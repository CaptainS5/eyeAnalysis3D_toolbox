# eyeAnalysis3D_toolbox
currently only focusing on head movement data from Quest 3 for the FOV study

- not updated on github, but there should be a "data" folder in the root folder, containing a "raw" subfolder for all raw data, and "pre_processed" subfolder for the initially sorted data; filtered and processed data will be put in the "data" folder

- use sortRawData.m to transform your data into the required coordinate systems and corresponding parameter names used by the toolbox; can resample if needed (currently commented out, let me know if you need this function and I'll quickly debug)
  - the coordinate system of oculus (from raw data) is x+=right, y+=up, z+=backward, left-handed rotation
  - the coordinate system used by the toolbox is the same as Matlab plot3, x+=forward, y+=left, z+=up, right-handed rotation
  - sorted data variables:
    - qW/X/Y/Z: head orientation quaternions, rotation from a reference frame depending on the raw data, likely just the default axis
    - ori_yaw/pitch/roll: head orientation euler angles tranformed from the quaternions, easier for visualization
    - posX/Y/Z: head position in world coordinates, meters? (unit is the same as the raw data, need to confirm)
    - timestamp: difference should be in secs


- use viewTrialAnalysis.m to plot trial by trial, you can check out filtering and head velocities
  - once the GUI is open and there is no errors, you can nagivate across trials/figures by using the buttons on the GUI; the current default plots are the second one, "head velocity filtering" (classification not implemted yet)
  - if you need to change something in the plots, edit in updatePlots.m, and then re-run updateGUI.m, the plots will be updated on the open GUI; you don't need to rerun viewTrialAnalysis.m if the processing is the same

- the main processing steps are in processTrial.m
  - it started with filtering the traces; velocity traces are also calculated at this step; depending on your data, you may not need filtering
  - added variables in filterHeadTrace.m (other than the filtered orientation and position):
    - rotRawQw/x/y/z: head rotation between frames calculated from filtered orientation data, the raw velocity quaternions
      - if you want to skip filtering and directly use raw data, change line 19 to "headOriFilt = [headData.qW headData.qX headData.qY headData.qZ];" and comment out lines 21-56
    - velRaw_yaw/pitch/roll: euler angle transformed from rotRawQw/x/y/z
    - rotFiltQw/x/y/z: filtered quaternions of rotRawQw/x/y/z
    - velFilt_yaw/pitch/roll: euler angle transformed from rotFiltQw/x/y/z
    - rotVel3D(Filt) & rotAxisX/Y/Z: angular head velocity in 3D (and the filtered version), around the rotation axis rotAxisX/Y/Z transformed from rotFiltQw/x/y/z
      - again, if you want the unfiltered version of this, modify lines 96 and 98  
  
With new data, always start with checking if the filtering works ok or needs any adjustment (filterHeadTrace.m). To automatically process all data without visualization, wrap the steps in processTrial.m into a function (should have done this earlier...)
