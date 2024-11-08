/*
Programmed by: Sai Charan Tammisetti
Programmed on: 2023-09-13
Programmed to: Produce a report that produces HW1 Duggins Weather Analysis.pdf 

Modified by: Sai Charan Tammisetti
Modified on: 2023-09-13
Modified to: Worked on Proc Print statement
*/

*A library that points to the provided data set;
x "cd L:\st445\Data";
libname Shared ".";

*A new library that points to the location where are the new data sets are created;
x "cd S:\Desktop\ST445\HW1";
libname HW1 ".";

*Set output destinations;
ods listing close;
ods pdf file = "HW1 Tammisetti Weather Analysis.pdf" style = Festival;

*Title of page 1;
title "Descriptor Information After Sorting";

*Sorting data by descending Year, if matching then by MonthN, if still matching then by DayN variable;
proc sort data = Shared.rtptall
          out = HW1.rtptall;
  by descending Year MonthN DayN;
  

run;

*Removing special title and excluding Attributes, EngineHost from printing in proc contents;
ods noproctitle;
ods exclude Attributes;
ods exclude EngineHost;

*Preventing data from printing in the report;
options nodate;

*Creates descriptor information;
proc contents data= HW1.rtptall Varnum;
  
run;

               
*Title and footnotes for page 2;

title  "Raleigh, NC: Summary of Temperature and Precipitation";
title2 "in June , July, and August";
title3 h = 8pt "by 15-Year Groups (Since 1887)";
footnote j = left h = 8pt "Excluding Years Prior to 1900";

*Creates requested Summary of Temperature and Precipitation in June, July and August
 Data prior to 1900 is excluded
 Also changed labels to few variables;

proc means data = HW1.rtptall
           nonobs n median QRange mean STDDEV
           maxdec = 2;
  where Year >= 1900 and MonthC in ("June" "July" "August");
  class GroupDesc;
  var Tmax Tmin Prcp;
  label Tmax = "Daily Max Temp";
  label Tmin = "Daily Min Temp";
  label Prcp = "Daily Precip.";
run;

*Creates requested format for the variables tmin and tmax (min and max temperatures)
 Any missing values are formatted as 'Not Recoreded';
proc format;
  value min(fuzz = 0) 
    other = "Not Recorded"
    low -< 32 = "<32"
    32  -< 50 = "[32,50)"
    50  -< 70 = "[50,70)"
    70  - high = ">=70"
  ;


  value max(fuzz = 0) low -< 50 = '<50'
    50  -< 75 = '[50,75)'
    75  -< 90 = '[75,90)'
    90  - high = '>=70'
  ;
run;

*Gave required titles and footnotes. Footnotes use an 8pt font
 title "Raleigh, NC: Amount of Precipitation by 15-Year Group (Since 1887)";
title2 "and by Temperature Group Cross-Clarification";
footnote j = left h = 8pt "Excluding Weekends";

*Get frequencies of requested data i.e Amount of Precipitation by 15-Year Group (Since 1887)"
 and by Temperature Group Cross-Clarification. Uses formats used in the previous proc format
 Creates two tables;
proc freq data = HW1.rtptall(where = (DayC not in ("Saturday", "Sunday")));;
  tables GroupDesc;
  tables tmin * tmax /missing;
  format tmin min. tmax max.;
  weight Prcp;
run;


*Given required titles and footnotes;
ods select 'Type III Model ANOVA';
title 'Predicting Precipitation from Temperature (Min&Max) and Day of the Week';
title2 'Using Independent Models for each 15-Year Group (Since 1887)';
footnote j = left h = 8pt 'Only displaying the Type III ANOVA table';

* Used to add statistical model to the report;
proc glm data = HW1.rtptall;
  By descending GroupDesc;
  class DayC;
  model Prcp = tMax tMin DayC;
run;

*Given required titles and footnotes;
title "Listing of Temperature and Precipitation Values";
footnote j = left h = 8pt "Restricted to January and December of 2021";

*Prints requested data to the report. Also sums the precipitation variable.
 Every data excluding January 2021 and December 2021 is excluded;
proc print data = HW1.rtptall noobs label;
  where Year = 2021 and MonthC in ("January", "December");
  by MonthN;
  id monthC DayN;
  format Prcp 4.2;
  var monthC DayN DayC Tmin Tmax Prcp;
  sum Prcp;
run;

*Clearing title and footnotes;
title;
footnote;

* Turning special titles back on;
ods proctitle;

*Turning date back on;
options date;

*Turning listing back on;
ods listing;

*Closing the pdf;
ods pdf close;

quit;
