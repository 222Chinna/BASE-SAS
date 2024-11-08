/*
Programmed by: Sai Charan Tammisetti
Programmed on: 12/05/2023
Programmed to: Analyze the newly-updated database of electric vechiles and produce a report

Modified by: Sai Charan Tammisetti
Modified on: 12/05/2023
Modified to: add comments
*/

* Preventing date from printing in the report;
options nodate;

* Removing special title;
ods noproctitle;

* Closing listing destination;
ods listing close;

* Set filerefs and librefs using only relative paths;
X 'cd L:\st445\Results\FinalProjectPhase1\';
libname InputDS '.';


*A library that points to the location where the results are created;
X 'cd S:\Desktop\st445\Final';
libname Final '.';

options fmtsearch = (Final);

* Setting output destination;
ods pdf file = "Tammisetti Washington State Electric Vehicle Study.pdf" 
        style = sapphire dpi = 300 columns = 2;
ods graphics on / width = 6in;


* Define macro variables;
%let IdStamp = Output created by &SysUserID on &SysDate9 using &SysVLong;
%let TitleOpts = bold h = 14pt;
%let SubTitleOpts = bold h = 10pt;
%let FootOpts = italic j = left h = 8pt;
proc format library = Final;
  value CAFVElig 3 = 'CAFV Eligibility Unknown'
                 1 = 'CAFV Eligibile'
                 2 = 'Not CAFV Eligible';
  value MYFormat(fuzz=0) low -< 2000 = 'Pre-2000'
                         2000 - 2004 = '2000-2004'
                         2005 - 2009 = '2005-2009'
                         2010 - 2014 = '2010-2014'
                         2015 - 2019 = '2015-2019'
                         2020 - 2024 = '2020-2024'
  ;
  value ERFormat(fuzz=0) 0 = 'Not Yet Known'
                         1 -< 200 = 'Poor'
                         200 -< 250 = 'Average'
                         250 -< 300 = 'Good'
                         300 - high = 'Great'
                         other = 'Invalid/Missing'
   ;
   value ERColor (fuzz = 0) 0 = 'cxDDA0DD'
                         1 -< 200 = 'cxDA70D6'
                         200 -< 250 = 'cxBA55D3'
                         250 -< 300 = 'cx9932CC'
                         300 - high = 'cx191970'
   ;
   value PHEVColor (fuzz = 0) 0 = 'cxDDA0DD'
                         1 -< 25 = 'cxDA70D6'
                         25 -< 50 = 'cxBA55D3'
                         50 -< 75 = 'cx9932CC'
                         75 - high = 'cx191970'
   ;
   value cafcFmt 1 = 'Yes'
                 2 = 'No'
                 3 = 'Unknown';
run;


title &SubTitleOpts 'Output 1';
title2 &TitleOpts 'Listing of BEV Cars Not Known to be CAFV* Eligible';
title3 &SubTitleOpts 'Partial Output -- Up to First 10 Records Shown per CAFV Status';
footnote  &FootOpts "&IDStamp";

* Output 1;
proc print data = InputDS.finaldugginsev (obs=10) label noobs;
  where CAFVCODE eq 2 and Model eq 'IONIQ';
  var CAFVCODE make model ERange; 
  format CAFVCODE CAFVElig.;
  attrib CAFVCODE label = "CAFV Eligibility"
         make label = "Vehicle Make"
         model label = "Vehicle Model"
         Erange label = "Electric Range"
;
run;

* Output 1;
proc print data = InputDS.finaldugginsev (obs=10) label noobs;
  where CAFVCODE eq 3;
  var CAFVCODE make model ERange; 
  format CAFVCODE CAFVElig.;
  attrib CAFVCODE label = "CAFV Eligibility"
         make label = "Vehicle Make"
         model label = "Vehicle Model"
         Erange label = "Electric Range"
;
run;
/*
proc print data = EVSorted  label noobs;
  by CAFVCODE;
  where Erange ne . or CAFVCODE ne .;
  var CAFVCODE make model Erange;
  format CAFVCODE CAFVElig.;
  attrib CAFVCODE label = "CAFV Eligibility";
run;*/

/*
proc report data = EVSorted nowd;
  by CAFVCODE;
  where CAFVCODE ne 1;
  columns CAFVCode make model Erange;
  define CAFVCode / display "CAFV Eligibility" format = CAFVElig.;
  define make / display;
  define model / display;

  compute before CAFVCode;
    counter = 0;
  endcomp;

  compute after CAFVCode;
    counter + 1;
    if count > 10 then call define(_row
  endcomp;
run;
*/
ods pdf select BaseMSRP.BasicMeasures
               BaseMSRP.Moments
               BaseMSRP.MissingValues
               Erange.BasicMEasures
               Erange.Moments
;

title &SubTitleOpts 'Output 2';
title2 &TitleOpts 'Selected Summary Statistics of MSRP and Electric Range';
footnote  &FootOpts "&IDStamp";
*Output 2;
proc univariate data = InputDS.finaldugginsev;
  var BaseMSRP ERange;
run;

title &SubTitleOpts 'Output 3';
title2 &TitleOpts 'Quantiles and Missing Data Summary of Base MSRP';
title3 &SubTitleOpts 'Grouped by Model Year';
footnote  &FootOpts "&IDStamp";
ods pdf select Quantiles MissingValues;
*Output 3;
proc univariate data = InputDS.finaldugginsev;
  format ModelYear MYFormat.;
  class ModelYear;
  var BaseMSRP;
run;

ods pdf columns = 1;

title &SubTitleOpts 'Output 4';
title2 &TitleOpts '90% Confidence Interval for Electric Range';
title3 &SubTitleOpts 'Grouped by CAFV* Status and EV Type';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts '*Clean Alternative Fuel Vehicle';
*Output 4;
proc means data = InputDS.finaldugginsuniquevinmask LCLM mean UCLM stderr n nonobs
           alpha = 0.1 maxdec = 3;
  class CAFVCode EVTypeShort;
  var Erange;
run;

ods pdf columns = 2;

title &SubTitleOpts 'Output 5';
title2 &TitleOpts 'Frequency Analysis of State';
title4 &SubTitleOpts '(Cumulative Statistics omitted)';
footnote  &FootOpts "&IDStamp";
* Output 5;
proc freq data = InputDS.finaldugginsev order = FREQ;
  tables StateCode / nocum missing;
run;

ods pdf columns = 1;

title &SubTitleOpts 'Output 6';
title2 &TitleOpts 'Frequency Analysis of EV Type, Primary Utility*';
title3 &TitleOpts 'and CAFV** by EV Type';
title4 &SubTitleOpts '(Cumulative Statistics omitted)';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "*Defined as first electric utility listed in the data base for the vehicle location.";
footnote3 &FootOpts "**Clean Alternative Fuel Vehicle";
*Output 6;
proc freq data = InputDS.finaldugginsev order = FREQ;
  tables EVTypeShort PrimaryUtil CAFV*EVTypeShort / nocum format = comma10.;
run;

title &SubTitleOpts 'Output 7';
title2 &TitleOpts 'Frequency Analysis of Model Year by Electric Range';
title3 &SubTitleOpts 'For BEV Cars Only';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "Range categories: 0 = Not Yet Known; (0,200)=Poor; [200,250)=Average;[250,300)=Good;300+=Great;Other=Invalid/Missing";
*Output 7;
proc freq data = InputDS.finaldugginsev;
  where EVTypeShort = 'BEV';
  tables ModelYear*Erange / missing format = comma10.;
  format ModelYear MYFormat. Erange ERFormat.;
run;

title &SubTitleOpts 'Output 8';
title2 &TitleOpts 'Frequency Analysis of Model Year by Electric Range';
title3 &SubTitleOpts 'Only for BEV Cars with Reported (>0) Ranges';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "Range categories: 0 = Not Yet Known; (0,200)=Poor; [200,250)=Average;[250,300)=Good;300+=Great;Other=Invalid/Missing";
*Output 8;
proc freq data = InputDS.finaldugginsev;
  where EVTypeShort = 'BEV' and Erange > 0;
  tables ModelYear*Erange / missing format = comma10. ;
  format ModelYear MYFormat. Erange ERFormat.;
run;

title &SubTitleOpts 'Output 9';
title2 &TitleOpts 'Frequency of EV Type for Each CAFV Elibility Category';
footnote  &FootOpts "&IDStamp";

*Output 9;
proc sgplot data = InputDS.finaldugginscafvcrossev;
  vbar CAFVCODE / response = RowPercent group = EVTypeShort
                  barwidth = 0.5 nooutline;
  format CAFVCODE cafcFmt.;
  keylegend / location = inside position = topright across = 1 opaque title = 'EV Type'; 
  xaxis label = 'CAFV Eligibility';
  yaxis label = "% of CAFV Category" Grid values = (0 to 100 by 10) 
        gridattrs = (color = gray88 thickness=1);
run;


ods pdf startpage = never;

title &SubTitleOpts 'Output 10';
title2 &TitleOpts 'Frequency of CAFV Elibility Category for Each EV Type';
footnote  &FootOpts "&IDStamp";
*Output 10;
proc sgplot data = InputDS.finaldugginscafvcrossev;
  hbar EVtypeShort / response = ColPercent nooutline group = CAFVCODE groupdisplay = cluster
                clusterwidth = 0.5 datalabel=ColPercent datalabelattrs=(color=gray size=10pt); ;
  format CAFVCODE CAFVElig.;
  keylegend / location = inside position = topright across = 1 opaque title = 'CAFV'; 
  xaxis label = '% of EV Type'  Grid values = (0 to 100 by 10) grid values = (0 to 100 by 10) 
        gridattrs = (color = gray88 thickness=1);
  yaxis label = "EV Type";
run;
ods pdf startpage = yes;

title &SubTitleOpts 'Output 11';
title2 &TitleOpts 'Comparative Boxplots for Electric Range';
title3 &SubTitleOpts 'Excluding Missing or Non-US State Postal Codes';
footnote  &FootOpts "&IDStamp";
*Output 11;
proc sgplot data = InputDS.finaldugginsev;
  where (not missing(ERange) or not missing(StateCode)) ;
  vbox ERange / group = StateCode groupdisplay=cluster;
  keylegend / location = outside position = right across = 2 title = 'State'; 
  yaxis label = "Electric Range " Grid values = (0 to 300 by 100);
run;

ods pdf columns = 2;

title &SubTitleOpts 'Output 12';
title2 &TitleOpts 'Frequency of Masked VIN Under 70/30 Plan';
title3 &SubTitleOpts 'Showing Only: Make = JEEP';
footnote  &FootOpts "&IDStamp";
*Output 12;
proc freq data = InputDS.finaldugginsuniquevinmask order = FREQ;
  where make eq 'JEEP';
  tables MaskVin / nocum;
run;

ods pdf columns = 1;


title &SubTitleOpts 'Output 13';
title2 &TitleOpts 'Listing of EV Makes and Models';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "Wow. This is just an awful table. Please don't ever make something like this ever again. Seriously. This is bad.";
* Output 13;
proc report data = InputDS.finaldugginsmodels nowd;
  column Make ("Models in Database" Model1-Model12);
  define Make / id;
  define Model1-Model12 / display;
run;

title &SubTitleOpts 'Output 14';
title2 &TitleOpts 'Analyis of Electric Range and Base MSRP';
title3 &SubTitleOpts 'Grouped by Model Year, EV Type*, and CAFV Eligibility';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "*Due to substantial differences between range for PHEV and BEV, pooled statistics should not be used for inferences";
* Output 14;
proc report data = InputDS.finaldugginsev nowd;
  columns ModelYear EVTypeShort CAFVCode (ERange BaseMSRP), (mean std n);
  format ModelYear MYFormat. CAFVCode CAFVElig.; 
  define ModelYear / group order = internal;
  define EVTypeShort / group "EV Type" ;
  define CAFVCode / group "CAFV" descending;
  define ERange / 'Electric Range';
  define BaseMSRP / 'Base MSRP';
  define mean / 'Mean';
  define std / 'Std. Dev.';
  define n / 'Count';
  break after ModelYear / summarize;
  compute ERange;
    if not missing(ERange.mean) then call define ('_c4_', 'FORMAT', '5.1');
    if not missing(ERange.std) then call define ('_c5_', 'FORMAT', '5.2');
    if not missing(ERange.n) then call define ('_c6_', 'FORMAT', 'comma5.');
  endcomp;
  compute BaseMSRP;
    if not missing(BaseMSRP.mean) then call define ('_c7_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.std) then call define ('_c8_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.n) then call define ('_c9_', 'FORMAT', 'comma5.');
  endcomp;
run;


title &SubTitleOpts 'Output 15';
title2 &TitleOpts 'Analyis of Electric Range and Base MSRP';
title3 &SubTitleOpts 'Grouped by Model Year, EV Type*, and CAFV Eligibility';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "*Due to substantial differences between range for PHEV and BEV, pooled statistics should not be used for inferences";
footnote3 &FootOpts "Alternative Display: EV Type displays on all non-summary rows";
* Output 15;
proc report data = InputDS.finaldugginsev nowd;
  columns ModelYear EVTypeShort CAFVCode (ERange BaseMSRP), (mean std n);
  format ModelYear MYFormat. CAFVCode CAFVElig.; 
  define ModelYear / group order = internal ;
  define EVTypeShort / group "EV Type";
  define CAFVCode / group "CAFV";
  define ERange / 'Electric Range';
  define BaseMSRP / 'Base MSRP';
  define mean / 'Mean';
  define std / 'Std. Dev.';
  define n / 'Count';
  break after ModelYear / summarize;
  compute ERange;
    if not missing(ERange.mean) then call define ('_c4_', 'FORMAT', '5.1');
    if not missing(ERange.std) then call define ('_c5_', 'FORMAT', '5.2');
    if not missing(ERange.n) then call define ('_c6_', 'FORMAT', 'comma5.');
  endcomp;
  compute BaseMSRP;
    if not missing(BaseMSRP.mean) then call define ('_c7_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.std) then call define ('_c8_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.n) then call define ('_c9_', 'FORMAT', 'comma5.');
  endcomp;
  compute before EVTypeShort;
    EVDUP = scan(EVTypeShort,1);
  endcomp;
  compute EVTypeShort;
    if _break_ ne '_RBREAK_' then do;
      if _break_ ne 'ModelYear' then do;
        if missing(EVTypeShort) then EVTypeShort = EVDup;
      end;
    end;
  endcomp;
run;

title &SubTitleOpts 'Output 16';
title2 &TitleOpts 'Analyis of Electric Range and Base MSRP';
title3 &SubTitleOpts 'Grouped by Model Year, EV Type*, and CAFV Eligibility';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "*Due to substantial differences between range for PHEV and BEV, pooled statistics should not be used for inferences";
footnote3 &FootOpts "*Despite PHEV and BEV range differences, all color-coding uses BEV cutoffs.";
footnote4 &FootOpts "Alternative Display: EV Type displays on all non-summary rows";
* Output 16;
proc report data = InputDS.finaldugginsev nowd 
            style(lines) = [color=white]
            style(summary) = [backgroundcolor = gray]
            ;
  columns ModelYear EVTypeShort CAFVCode (ERange BaseMSRP), (mean std n);
  format ModelYear MYFormat. CAFVCode CAFVElig.; 
  define ModelYear / group order = internal ;
  define EVTypeShort / group "EV Type";
  define CAFVCode / group "CAFV";
  define ERange / 'Electric Range'  ;
  define BaseMSRP / 'Base MSRP';
  define mean / 'Mean';
  define std / 'Std. Dev.';
  define n / 'Count';
  break after ModelYear / summarize;

  compute ERange;

    if not missing(ERange.mean) then do;
      call define ('_c4_', 'FORMAT', '5.1');
      if EVTypeShort = "BEV" then call define ('_c4_', 'style', 'style=[backgroundcolor = ERcolor.]');
      else if EVTypeShort = "PHEV" then call define ('_c4_', 'style', 'style=[backgroundcolor = PHEVcolor.]');
    end;
    if not missing(ERange.std) then call define ('_c5_', 'FORMAT', '5.2');
    if not missing(ERange.n) then call define ('_c6_', 'FORMAT', 'comma5.');
  endcomp;
  compute BaseMSRP;
    if not missing(BaseMSRP.mean) then call define ('_c7_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.std) then call define ('_c8_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.n) then call define ('_c9_', 'FORMAT', 'comma5.');
  endcomp;
  compute before EVTypeShort;
    EVDUP = scan(EVTypeShort,1);
  endcomp;
  compute EVTypeShort;
    if _break_ ne '_RBREAK_' then do;
      if _break_ ne 'ModelYear' then do;
        if missing(EVTypeShort) then EVTypeShort = EVDup;
      end;
    end;
  endcomp;
  compute after _page_ / style=[backgroundcolor = black just = right];
    line 'Electric range-based coloring:<200, 200-250, 250-300, >300';
  endcomp;
run;

title &SubTitleOpts 'Output 17';
title2 &TitleOpts 'Analyis of Electric Range and Base MSRP';
title3 &SubTitleOpts 'Grouped by Model Year, EV Type*, and CAFV Eligibility';
footnote  &FootOpts "&IDStamp";
footnote2 &FootOpts "*Due to substantial differences between range for PHEV and BEV, pooled statistics should not be used for inferences";
footnote3 &FootOpts "*BEV and PHEV rows use their respective cutoffs. Summary rows use BEV cutoffs.";
footnote4 &FootOpts "Alternative Display: EV Type displays on all non-summary rows";
* Output 17;
proc report data = InputDS.finaldugginsev nowd 
            style(lines) = [color=white]
            style(summary) = [backgroundcolor = gray]
            ;
  columns ModelYear EVTypeShort CAFVCode (ERange BaseMSRP), (mean std n);
  format ModelYear MYFormat. CAFVCode CAFVElig.; 
  define ModelYear / group order = internal;
  define EVTypeShort / group "EV Type";
  define CAFVCode / group "CAFV" descending;
  define ERange / 'Electric Range'  ;
  define BaseMSRP / 'Base MSRP';
  define mean / 'Mean';
  define std / 'Std. Dev.';
  define n / 'Count';
  break after ModelYear / summarize;
  compute ERange;
    if EVTypeShort = "BEV" then call define ('_c4_', 'style', 'style=[backgroundcolor = ERcolor.]');
    else if EVTypeShort = "PHEV" then call define ('_c4_', 'style', 'style=[backgroundcolor = PHEVcolor.]');
    else call define ('_c4_', 'style', 'style=[backgroundcolor = ERcolor.]');
    if not missing(ERange.mean) then call define ('_c4_', 'FORMAT', '5.1');
    if not missing(ERange.std) then call define ('_c5_', 'FORMAT', '5.2');
    if not missing(ERange.n) then call define ('_c6_', 'FORMAT', 'comma5.');
  endcomp;
  compute after _page_ / style=[backgroundcolor = black just = right];
    line 'BEV range-based coloring:<200, 200-250, 250-300, >300';
    line 'PHEV range-based coloring:<25, 25-50, 50-75, >75';
  endcomp;
  compute BaseMSRP;
    if not missing(BaseMSRP.mean) then call define ('_c7_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.std) then call define ('_c8_', 'FORMAT', 'dollar7.');
    if not missing(BaseMSRP.n) then call define ('_c9_', 'FORMAT', 'comma5.');
  endcomp;
  compute before EVTypeShort;
    EVDUP = scan(EVTypeShort,1);
  endcomp;
  compute EVTypeShort;
    if _break_ ne '_RBREAK_' then do;
      if _break_ ne 'ModelYear' then do;
        if missing(EVTypeShort) then EVTypeShort = EVDup;
      end;
    end;
  endcomp;
run;

* Clearing title and footnote;
title;
footnote;
ods pdf close;

*Turning special titles back on;
ods proctitle;

* Turned listing back on;
ods listing;

*Turning date back on;
options date;

quit;
