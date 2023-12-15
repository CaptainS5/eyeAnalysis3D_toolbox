# eyeAnalysis3D_toolbox
WIP, using Tobii Crystal data as an example. More detailed explanations to come later...

- use sortRawData.m to transform your data into the required coordinate systems of the toolbox, and align/resample eye & head data if needed

- use viewTrialAnalysis.m to plot trial by trial, you can check out filtering, eye movement classificaiton, and head motion
  - once the GUI is open and there is no errors, you can nagivate across trials/figures by using the buttons on the GUI
  - if you need to change something in the plots, edit in updatePlots.m, and then re-run updateGUI.m, the plots will be updated; you don't need to rerun viewTrialAnalysis.m if the processing is the same

- the processing steps are in processTrial.m
  - it started with filtering both head and eye traces; velocity traces are also calculated at this step
  - then it classify eye movements in the order of blink, saccade, and fixation (findXXX.m)
  - then the stats of eye movements are calculated (processXXX.m)

With new data, always start with checking if the filtering works ok (filterHeadTrace.m and filterEyeTrace.m), then tune the classification functions (findBlink.m, findSaccade.m, etc.)
