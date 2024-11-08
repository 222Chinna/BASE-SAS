/*
Programmed by: Sai Charan Tammisetti
Programmed on: 2023-10-15
Programmed to: Produce a report that produces HW4 Duggins Lead Report.pdf 

Modified by: Sai Charan Tammisetti
Modified on: 2023-10-16
Modified to: add comments
*/

*Set output destinations;
ods listing close;

*Preventing date from printing in the report;
options nodate;

*Removing special title;
ods noproctitle;



*Set filerefs and librefs using only relative paths;
X "cd L:\st445\";
libname InputDS "Results\";
filename RawData "Data\";

*A new library that points to the location where are the new data sets are created;
X "cd S:\Desktop\ST445\HW4";
libname HW4 ".";

* Creates a new macro variable for 1998;
%let Year = 1998;


* Creates a new macro variable to use in proc compare;
%let CompOpts = outbase outcompare outdiff outnoequal
     method = absolute criterion = 1E-15;

* To access the formats stored;
OPTIONS FMTSEARCH = (HW4);

* Reading in raw data and creating a new dataset;
data HW4.HW4TammisettiLead(drop = _:);
  attrib StName length = $2. label = "State Name"
         Region length = $9.
         JobID length = 8.
         Date length = 8. format = Date9. 
         PolType length = $4. label = "Pollutant Name"
         PolCode length = $8. label = "Pollutant Code"
         Equipment format = Dollar11.
         Personnel format = Dollar11.
         JobTotal format = Dollar11.;
  infile RawData("LeadProjects.txt") dlm = ',' dsd truncover firstobs = 2;
  input _StName : $2.
        _JobID : $5.
        _DateRegion : $13.
        _CodeType : $5.
        Equipment : dollar11.
        Personnel : Dollar11.;
  StName = Upcase(_StName);
  JobID = input(tranwrd(tranwrd(_JobID, 'l', '1'),'O','0'), 5.);
  Date = input(compress(_DateRegion,, 'a'), 5.);
  Region = propcase(tranwrd(substr(_DateRegion,6), '1', 'l'));
  PolType = compress(_CodeType,, 'd');
  PolCode = compress(_CodeType,, 'a');
  JobTotal = Equipment + Personnel;
run;

* Sorting data by region, street name and total job;
proc sort data = HW4.HW4TammisettiLead;
  by Region StName descending JobTotal;
run;

* Setting output destination;
ods pdf file = "HW4 Tammisetti Lead Report.pdf";


ods EXCLUDE ALL;

* Creating a new dataset for validation;
ods output Position = HW4.HW4Tammisettidesc (drop = member);
proc contents data = HW4.HW4TammisettiLead varnum;
run;

*Comparing the given file to the generated file;
proc compare base =InputDS.Hw4dugginslead compare = HW4.HW4TammisettiLead
  out = HW4.DiffsB
  &CompOpts;
run;

*Comparing the given file to the generated file;
proc compare base = InputDS.Hw4dugginsdesc compare = HW4.HW4Tammisettidesc
  out = HW4.DiffsB
  &CompOpts;
run;

*Created a format for date variable (divided quarterly);
proc format library = HW4 fmtlib;
  value MyQtr(fuzz = 0)
    "01JAN&Year."d - "31MAR&Year."d= 'Jan/Feb/Mar'
    "01Apr&Year."d - "30Jun&Year."d = 'Apr/May/Jun'
    "01Jul&Year."d - "30Sep&Year."d = 'Jul/Aug/Sep'
    "01Oct&Year."d - "31Dec&Year."d = 'Oct/Nov/Dec'
  ;
run;

ods EXCLUDE NONE;


title "90th Percentile of Total Job Cost By Region and Quarter";
title2 "Data for &Year.";
*Creating a summary;
proc means data = HW4.HW4TammisettiLead
           p90 maxdec = 2;
  class region date;
  var jobTotal;
  format date MyQtr.;
  output out=HW4.jobTotal90 (where = (Date ne . and Region ne " ") drop =_TYPE_ _FREQ_) p90 = Total90 n = NObs;
run;

*Turning listing back on;
ods listing;

title;

* Turning graphics on;
ods graphics / reset imagename = 'HW4Pctile90';

*Prints a horizontal bar graph using dataset created from proc means;
proc sgplot data = HW4.jobTotal90;
  hbar region / response = Total90
                group = date groupdisplay = cluster 
                datalabel = NObs datalabelattrs = (size = 6pt);
  xaxis label='90th Percentile of Total Job Cost'
        Grid
        gridattrs=(color=gray66);
  keylegend / position = top;
run;

* Turning graphics off;
ods graphics off;
ods listing close;

ods output Freq.Table1.CrossTabFreqs = HW4.hw4tammisettigraph2 (where = (Date ne . and Region ne " ") 
                                          keep = Region Date RowPercent);

title "Frequency of CleanUp By Region and Date";
title2 "Data for &Year";
*Creating a region-date table;
proc freq data = HW4.HW4TammisettiLead;
  tables region*date /nopercent nocol;
  format date MyQtr.;

run;

ods listing;
* Turning graphics on;
ods graphics / reset imagename = 'HW4RegionPct';

*Clearing title;
title;

*Prints a vertical bar graph using dataset created from proc freq;
proc sgplot data = HW4.hw4tammisettigraph2;
  vbar Region / response = RowPercent
                group = date groupdisplay = cluster
  ;
  yaxis label='Region Percentage within Pollutant' labelattrs = (size = 16pt)
        values = (0 to 45 by 5)
        Grid
        gridattrs=(color=gray66);

  xaxis labelattrs = (size = 16pt)
        valueattrs = (size = 14pt)
        ;
  keylegend / position = topright location = inside across = 2 opaque;
run;


ods graphics off;


*Turning date back on;
options date;

* Turning special titles back on;
ods proctitle;



*Closing the pdf file;
ods pdf close;

quit;
