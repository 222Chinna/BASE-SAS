/*
Programmed by: Sai Charan Tammisetti
Programmed on: 2023-10-04
Programmed to: Produce a report that produces HW3 Duggins 3 Month Clinical Report.pdf 

Modified by: Sai Charan Tammisetti
Modified on: 2023-10-04
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
libname Results "Results";
filename RawData "Data\BookData\ClinicalTrialCaseStudy\";

*A new library that points to the location where are the new data sets are created;
X "cd S:\Desktop\ST445\HW3";
libname HW3 ".";

* To access the formats stored;
OPTIONS FMTSEARCH = (HW3);

* Created a VarAttrs macro variable for attributes;
%let VarAttrs = Subj label = "Subject Number"
                sfReas label = "Screen Failure Reason" length = $50
                sfStatus label = "Screen Failure Status (0 = Failed)" length = $1
                BioSex label = "Biological Sex" length = $1
                visitDate label = "Visit Date" length = $10
                failDate label = "Failure Notification Date" length = $10
                sbp label = "Systolic Blood Pressure"
                dbp label = "Diastolic Blood Pressure"
                bpUnits label = "Units (BP)" length = $5
                pulse label = "Pulse"
                pulseUnits label = "Units (Pulse)" length = $9
                position label = "Position" length = $9
                temp label = "Temperature" format = 5.1
                tempUnits label = "Units (Temp)" length = $1
                weight label = "Weight"
                weightUnits label = "Units (Weight)" length = $2
                pain label = "Pain Score"               
;

* Created a Visit macro variable to use in titles and sites;
%let Visit = 3 Month Visit;


*Reading Site 1 raw data;
data HW3.site1;
  attrib &VarAttrs;
  infile RawData("Site 1, &Visit..txt") dlm = '09'x dsd;
  input Subj sfReas sfStatus BioSex VisitDate failDate sbp dbp bpUnits pulse pulseUnits
        position temp tempUnits weight weightUnits pain; 
run;

*Reading Site 2 raw data;
data HW3.site2;
  attrib &VarAttrs;
  infile RawData("Site 2, &Visit..csv") dlm = ',' dsd;
  input Subj sfReas sfStatus BioSex VisitDate failDate sbp dbp bpUnits pulse pulseUnits
        position temp tempUnits weight weightUnits pain;
  list;
run;

*Reading Site 3 raw data;
data HW3.site3;
  attrib &VarAttrs;
  infile RawData("Site 3, &Visit..dat");
  input Subj 7. sfReas 8-58  @59 sfStatus  @62 BioSex @63 VisitDate @73 failDate 73-82 @83 sbp 3.
        @86 dbp 3. @89 bpUnits 89-94 @95 pulse 3. @98 pulseUnits @108 position @119 temp 5.
        @124 tempUnits @125 weight 3. @128 weightUnits @130 pain;
  putlog 'SUBJECT and PULSE values are: ' Subj= pulse=;  
run;




*Set output destinations;
ods rtf file = "HW3 Tammisetti &Visit Clinical Report.rtf" style = Sapphire;
ods pdf file = "HW3 Tammisetti &Visit Clinical Report.pdf" style = Printer;

* Created a macro variable for sorting;
%let ValSort = by descending sfStatus sfReas descending VisitDate descending failDate Subj;

* Sorts Site 1 dataset;
proc sort data = HW3.site1 out = HW3.sortedSite1;
  &ValSort;
run;

* Sorts Site2 dataset;
proc sort data = HW3.site2 out = HW3.sortedSite2;
  &ValSort;
run;

* Sorts Site 3 dataset;
proc sort data = HW3.site3 out = HW3.sortedSite3;
  &ValSort;
run;


ODS EXCLUDE ALL;

* Creates a new macro variable to use in proc compare;
%let CompOpts = outbase outcompare outdiff outnoequal
     method = absolute criterion = 1E-10;
               
* Compares two datasets (Site 1);
proc compare base = Results.hw3dugginssite1 compare = HW3.sortedSite1
  out = HW3.site1diffs
  &CompOpts;
run;

* Compares two datasets (Site 2);
proc compare base = Results.hw3dugginssite2 compare = HW3.sortedSite2
  out = HW3.site2diffs
  &CompOpts;
run;

* Compares two datasets (Site 3);
proc compare base = Results.hw3dugginssite3 compare = HW3.sortedSite3
  out = HW3.site3diffs
  &CompOpts;
run;


*Creates requested format for the variable dbp and sbp;
proc format library = HW3 fmtlib;
  value DBPVALUE(fuzz = 0)
    low -< 79 = "Acceptable"
    80 - high = "HIGH"
  ;

  value SBPVALUE(fuzz = 0)
    low -< 129 = "Acceptable"
    130 - high = "High"
  ;
run;

ods EXCLUDE NONE;

ods exclude Attributes EngineHost;


title "Variable-level Attributes and Sort Information: Site 1 at &Visit";
footnote j=left h=10pt "Prepared by &sysUserID on &sysDate";
*Creates descriptor information for site 1;
proc contents data = HW3.sortedSite1 Varnum;
run;

ods exclude Attributes EngineHost;

title "Variable-level Attributes and Sort Information: Site 2 at &Visit";
footnote j=left h=10pt "Prepared by &sysUserID on &sysDate";
*Creates descriptor information for site 2;
proc contents data = HW3.sortedSite2 Varnum;
run;

ods exclude Attributes EngineHost;

title "Variable-level Attributes and Sort Information: Site 3 at &Visit";
footnote j=left h=10pt "Prepared by &sysUserID on &sysDate";
*Creates descriptor information for site 3;
proc contents data = HW3.sortedSite3 Varnum;
run;

* sets output destination;
ods powerpoint file = "HW3 Tammisetti &Visit Clinical Report.pptx" style = POWERPOINTDARK;

title "Selected Summary Statistics on Measurements";
title2 "for Patients from Site 1 at &Visit";
footnote j=left h=10pt "Statistic and SAS keyword: Sample size(n), Mean (mean), Standard Deviation (stddev), Median (median), IQR (qrange)";
footnote2 j=left h=10pt "Prepared by &sysUserID on &sysDate";
* Creates requested Selected Summary Statistics on Measurements 4 
for Patients from Site 1 at 3 Month Visit;
proc means data = HW3.sortedSite1
           nonobs n mean STDDEV median QRange
           maxdec = 1;
  class pain;
  var weight temp pulse dbp sbp;
run;



ods pdf Columns=2;

title "Frequency Analysis of Positions and Pain Measurements by Blood Pressure Status";
title2 "for Patients from Site 2 at &Visit";
footnote j=left h=10pt "Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80";
footnote2 j=left h=10pt "Prepared by &sysUserID on &sysDate";
* Creates Frequency Analysis of Positions and Pain Measurements by Blood Pressure Status 5
for Patients from Site 2 at 3 Month Visit;
proc freq data = HW3.sortedSite2;
  tables position pain*dbp*sbp /norow nocol;
  format dbp DBPVALUE. sbp SBPVALUE.;
run;

* Closing file;
ods powerpoint close;

ods pdf Columns = 1;

title "Selected Listed of Patients with a Screen Failure and Hypertension";
title2 "for Patients from Site 3 at &Visit";
footnote1 j=left h=10pt "Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80";
footnote2 j=left h=10pt "Only patients with a screen failure are included.";
footnote3 j=left h=10pt "Prepared by &sysUserID on &sysDate";
* Selected Listing of Patients with a Screen Failure and Hypertension 6
for patients from Site 3 at 3 Month Visit;
proc print data = HW3.sortedSite3 noobs label;
  where sfStatus = '0';
  id subj pain;
  var visitDate sfStatus sfReas failDate BioSex sbp dbp pulseUnits weight weightUnits;
run;

*Closing files;
ods rtf close;
ods pdf close;

*Clearing title and footnotes;
title;
footnote;

*Turning date back on;
options date;

* Turning special titles back on;
ods proctitle;

*Turning listing back on;
ods listing;

quit;
