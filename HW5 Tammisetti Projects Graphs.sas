/*
Programmed by: Sai Charan Tammisetti
Programmed on: 2023-10-31
Programmed to: Produce a report that produces HW4 Duggins Lead Report.pdf 

Modified by: Sai Charan Tammisetti
Modified on: 2023-11-01
Modified to: add comments
*/


*Preventing date from printing in the report;
options nodate;

*Removing special title;
ods noproctitle;

*Set filerefs and librefs using only relative paths;
X "cd L:\st445\";
libname InputDS "Data\";
filename RawData "Data\";
libname Results "Results\";

*A new library that points to the location where are the new data sets are created;
X "cd S:\Desktop\ST445\HW5";
libname HW5 ".";


* To access the formats stored;
OPTIONS FMTSEARCH = (Results InputDS);


* Creates a new macro variable to use in proc compare;
%let CompOpts = outbase outcompare outdiff outnoequal
     method = absolute criterion = 1E-9;


*Reading in O3 dataset;
Data HW5.O3Projects;
  infile RawData("O3Projects.txt") dlm = "," dsd truncover firstobs = 2;
  input StName : $2.
        _JobID : $5.
        _DateRegion : $13.
        _CodeType : $3.
        Equipment : dollar11.
        Personnel : Dollar11.;
run;

*Reading in CO dataset;
Data HW5.COProjects;
  infile Rawdata("COProjects.txt") dlm = "," dsd truncover firstobs = 2;
  input StName : $2.
        _JobID : $5.
        _DateRegion : $13.
        Equipment : dollar11.
        Personnel : Dollar11.;
run;


*Reading in SO2 dataset;
Data HW5.SO2Projects;
  infile Rawdata("SO2Projects.txt") dlm = "," dsd truncover firstobs = 2;
  input StName : $2.
        _JobID : $5.
        _DateRegion : $13.
        Equipment : dollar11.
        Personnel : Dollar11.;
run;


*Reading in TSP dataset;
Data HW5.TSPProjects;
  infile Rawdata("TSPProjects.txt") dlm = "," dsd truncover firstobs = 2;
  input StName : $2.
        _JobID : $5.
        _DateRegion : $13.
        Equipment : dollar11.
        Personnel : Dollar11.;
run;



*Combining all datasets;
Data HW5.HW5tammisettiprojects (label = "Cleaned and Combined EPA Projects Data" drop = _:);
  attrib StName length = $2. label = "State Name"
         Region length = $9.
         JobID length = 8.
         Date length = 8. format = Date9. 
         PolType length = $4. label = "Pollutant Name"
         PolCode length = $8. label = "Pollutant Code"
         Equipment format = Dollar11.
         Personnel format = Dollar11.
         JobTotal format = Dollar11.;
  set Results.hw4dugginslead (in = inLead)
      HW5.O3Projects 
      HW5.COProjects (in = inCO)
      HW5.SO2Projects (in = inSO2)
      HW5.TSPProjects (in = inTSP);
  StName = Upcase(StName);
  if inLead = 0 then do;
      JobID = input(tranwrd(tranwrd(_JobID, 'l', '1'),'O','0'), 5.);
      Date = input(compress(_DateRegion,, 'a'), 5.);
      if Date eq '' then Region = propcase(tranwrd(substr(_DateRegion,1), '1', 'l'));
          else Region = propcase(tranwrd(substr(_DateRegion,6), '1', 'l'));
      end;
  if Equipment = . and Personnel = . then JobTotal = .;
      else JobTotal = sum(Equipment, Personnel);
  if _CodeType eq "5O3" then do;
      PolType = 'O3';
      PolCode = '5';
      end;
      else if _CodeType eq 'O3' then do;
          PolCode = '';
          PolType = 'O3';
      end;
  if inCO = 1 then do;
      PolType = 'CO';
      PolCode = '3';
      end;
      else if inSO2 = 1 then do;
          PolType = 'SO2';
          PolCode = '4';
          end;
      else if inLead = 1 then do;
          PolType = 'LEAD';
          PolCode = '2';
          end; 
      else if inTSP = 1 then do;
          PolType = 'TSP';
          PolCode = '1';
          end;

run;


* Setting output destination;
ods pdf file = "HW5 Tammisetti Projects Graphs.pdf" dpi = 300;

ods exclude all;

*Sorting the data;
proc sort data = HW5.HW5tammisettiprojects;
  by PolCode Region descending JobTotal descending Date StName;
run;

* Creating a new dataset for validation;
ods output Position = HW5.HW5tammisettiprojectsdesc (drop = member);
proc contents data = HW5.HW5tammisettiprojects varnum;
run;

* Comparing the given file to the generated file;
proc compare base = Results.Hw5dugginsprojectsdesc compare = HW5.HW5tammisettiprojectsdesc
  out = HW5.DiffsA
  &CompOpts;
run;


* Comparing the given dataset to the generated dataset;
proc compare  base = Results.Hw5dugginsprojects compare = HW5.HW5tammisettiprojects
  out = HW5.DiffsB
  &CompOpts;
run;

*Store percentile data for graphing;
ods output summary = hw5.stats;
proc means data = HW5.HW5tammisettiprojects
           p25 p75;
  class region date;
  var jobTotal;
  by PolCode;
  format date MyQtr.;
  format PolCode $PolMap.;
  where PolCode ne '';
run;
title;


ods exclude none;
options nobyline;
ods pdf startpage = no;

*Create the requested graph;
ods listing image_dpi = 300;
ods graphics / reset width = 6in imagename = "HW5BadGraph";
title "25th and 75th Percentiles of Total Job Cost";
title2 'By Region and Controlling for Pollutant = #BYVAL1';
title3 h = 8pt "Excluding Records where Region was Unknown (Missing)";
footnote j = left "Bars are labeled with the number of jobs contributing to each bar";
*Creating bar graphs grouped by date;
proc sgplot data = HW5.stats noautolegend;
  vbar region / response = jobtotal_p75 
                group = date groupdisplay = cluster 
                datalabel = nobs datalabelattrs = (size = 7pt) 
                fillattrs = (transparency = 0.3) nooutline name = '75bar';
  vbar region / response = jobtotal_p25 group = date groupdisplay = cluster fillattrs = (color = black) name = '25bar';
  by polCode;
  format jobtotal_p25 dollar6.;
  format jobtotal_p75 dollar6.;
  keylegend '75bar'/ location = outside position = top across = 4;
  xaxis display = (nolabel);
  yaxis display = (nolabel);
run;


*Create the requested graph;
ods listing image_dpi = 300;
ods graphics / reset width = 6in imagename = "HW5GoodGraph";
*Cluster bar graphs using high low option;
proc sgplot data = HW5.stats;
  highlow x = region low = jobtotal_p25 high = jobtotal_p75 
          / type = bar group = date groupdisplay = cluster highlabel = nobs;
  by polCode;
  format jobtotal_p25 dollar6.;
  format jobtotal_p75 dollar6.;
  keylegend / location = inside position = top across = 4;
  xaxis display = (nolabel);
  yaxis display = (nolabel) grid gridattrs = (thickness = 3 color = grayCC) offsetmax=0.125;;
run;

*Clearing title and footnote;
title;
footnote;


*Closing the pdf file;
ods pdf close;

*Turning date back on;
options date;

*Turning special titles back on;
ods proctitle;


