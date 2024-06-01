# Eye Analysis Toolbox, as modified by Dani & Xiuyun

Find documentation [here](https://docs.google.com/document/d/1eV4cBu7QHC302jiJiQ47yoHoQkK_hb30ZTdw2M0yfs0/edit?usp=sharing). 


Final data updates by Xiuyun (and thanks Dani for all the hard work before!) for the ETDDC project:

May 31, 2024

Procedure of processing eye data:
1. **pre-processing**, run _sortRawData.m_, make sure you have the correct folder address for the raw data on your pc, and define the correct folder to save the data locally.\
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;the pre processed files are one .mat for one raw file, named as “prep_[userID]_s[session number]_f[which file/ten-min chunk within the session].mat”
2. **post-processing**, run _processAllData_perFile.m_. Again, make sure the folder directories for loading and saving data are defined correctly.\
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;the post processed files are one .mat for one chunk, named as “post_[userID]_s[session number]_f[which file/ten-min chunk within the session].mat”
3. **summary stats per 10-min chunk**, run _sortSummaryStats.m_, again make sure the folder directories for loading and saving data are defined correctly.
4. **summary stats in sliding windows**, run _sortSummaryStats_slidingWindow.m_, again make sure the folder directories for loading and saving data are defined correctly.
5. to get **sanity check plots**, everything is in _getDataInfo.m_
