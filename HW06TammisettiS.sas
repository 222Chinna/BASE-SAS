/*
Programmed by: Sai Charan Tammisetti
Programmed on: 2023-11-10
Programmed to: Produce a report that produces HW6 Duggins IPUMS Report.pdf 

Modified by: Sai Charan Tammisetti
Modified on: 2023-11-10
Modified to: add comments
*/

* Preventing date from printing in the report;
options nodate;

* Removing special title;
ods noproctitle;

* Clsoing listing destination;
ods listing close;
 
* Set filerefs and librefs using only relative paths;
X 'cd L:\st445\';
libname InputDS "Data";
filename RawData "Data";
libname Results "Results";

*A new library that points to the location where are the new data sets are created;
X 'cd S:\Desktop\ST445\HW6';
libname HW6 ".";

* Creates a new macro variable to use in proc compare;
%let CompOpts = outbase outcompare outdiff outnoequal
     method = absolute criterion = 1E-15;

* To access the formats stored;
OPTIONS FMTSEARCH = (HW6);

* Reading in Contract data;
data Contract;
  infile RawData("Contract.txt") dlm = '09'x firstobs = 2 truncover;
  input Serial : 8.
        Metro : 8.
        CountyFIPS : $3.
        MortPay : dollar6.
        HHI : dollar10.
        HomeVal : dollar10.;
run;

* Reading in Mortgaged data;
data Mortgaged;
  infile RawData("Mortgaged.txt") dlm = '09'x firstobs = 2 truncover;
  input Serial : 8.
        Metro : 1.
        CountyFIPS : $3.
        MortPay : dollar6.
        HHI : dollar10.
        HomeVal : dollar10.;
run;

* Reading in Cities data;
data Cities;
  attrib City length = $40.;
  infile RawData("Cities.txt") dlm = '09'x firstobs = 2 dsd;
  input City : $40.
        CityPop : Comma6.;
  City = tranwrd(City, '/', '-');
run;

* Reading in States data;
data States (drop = _:);
  attrib Serial length = 8.
         State length = $20.
         City length = $40.;
  infile RawData("States.txt") dlm = '09'x firstobs = 2;
  input _SerialState : $29.
        City : $40.;
  Serial = input(scan(_SerialState,1,'.'), 8.);
  State = scan(_SerialState,2,'.');
run;

proc sort data = Cities;
  by City;
run;

proc sort data = States;
  by City;
run;

* Merging City and States datasets;
data CityStates;
  merge States Cities;
  by City;
run;

proc format library = HW6 fmtlib;
  value MetroFmt
    0 = "Indeterminable"
    1 = "Not in a Metro Area"
    2 = "In Central/Principal City"
    3 = "Not in Central/Principal City"
    4 = "Central/Principal Indeterminable"
  ;
run;



* Merging Household datasets;
data household (drop = HOS_TYPE FIPS);
  attrib Ownership length = $6.
         MortStat length = $45.
         MetroDesc length = $32.;
  set InputDS.FreeClear (in = Fc)
      InputDS.Renters (in = Rt)
      Contract (in = Ct)
      Mortgaged (in = Mt);
  HOS_TYPE = 1 * Fc + Rt * 2 + 3 * Ct + 4 * Mt;

  if HOMEVAL eq . then HomeVal = .M;

  if HOS_TYPE = 1 then do;
    MortStat = "No, owned free and clear";
    Ownership = "Owned";
  end;
    else if HOS_TYPE = 2 then do;
      MortStat = "N/A";
      CountyFIPS = FIPS;
      HomeVal = .R;
      Ownership = "Rented";
    end;
    else if HOS_TYPE = 3 then do;
      MortStat = "Yes, contract to purchase";
      Ownership = "Owned";
    end;
    else do;
      MortStat = "Yes, mortgaged/ deed of trust or similar debt";
      Ownership = "Owned";
    end;

  MetroDesc = put(Metro, Metrofmt.);
run;

proc sort data = Household;
  by Serial;
run;

proc sort data = CityStates;
  by Serial;
run;

* Merging CityStates and Household datasets;
Data HW6.Hw6TammisettiIpums2005;
  attrib Serial label = "Household Serial Number"
         CountyFIPS label = "County FIPS Code"
         Metro label = "Metro Status Code"
         MetroDesc label = "Metro Status Description" length = $32.
         CityPop label = "City Population (in 100s)" format = Comma6.
         MortPay label = "Monthly Mortgage Payment" format = Dollar6. 
         HHI label = "Household Income" format = DOLLAR10.
         HomeVal label = "Home Value" format = DOLLAR10.
         State label = "State, District, or Territory" length = $20.
         City label = "City Name" length = $40.
         MortStat length = $45. label = "Mortgage Status"
         Ownership length = $6. label = "Ownership Status"
         ;
  merge Household CityStates;
  by Serial;
run;
* Setting output destination;
ods pdf file = "HW6 Tammisetti IPUMS Report.pdf" dpi = 300;

ods EXCLUDE all;

* Producing meta data of the main dataset;
* Creating a new dataset for validation;
ods output Position = HW6.HW6tammisettidesc (drop = member);
proc contents data = HW6.HW6tammisettiIpums2005 varnum;
run;



* Comparing the data of the given dataset and the produced dataset;
proc compare base = Results.hw6dugginsipums2005 compare = HW6.hw6tammisettiipums2005
  out = HW6.DiffsA
  &CompOpts;
run;

* Comparing the meta data of the given dataset and the produced dataset;
proc compare base = Results.hw6dugginsdesc compare = HW6.hw6tammisettidesc
  out = HW6.DiffsB
  &CompOpts;
run;

ods exclude none;
options nobyline;
ods pdf startpage = never;

title "Listing of Households in NC with Incomes Over $500,000";
* Printing the required report;
proc report data = HW6.hw6tammisettiipums2005 nowd;
  where HHI > 500000 and State = 'North Carolina';
  columns City Metro MortStat HHI HomeVal;
run;

*Clearing title;
title;

/* ods select BasicMeasures (where = (var ne "MortPay"))
           Quantiles (where = (var in ("CityPop", "MortPay")))
           ExtremeObs (where = (var in ("HHI", "HomeVal")))
           MissingValues (where = (var = "HomeVal")); */
ods select BasicMeasures Quantiles ExtremeObs MissingValues;
* Creating summary statistics;
proc univariate data = HW6.hw6tammisettiipums2005;
  var CityPop MortPay HHI HomeVal;
run;


ods graphics / reset width = 5.5in;
title "Distribution of City Population";
title2 "(For Households in a Recognized City)";
footnote "Recognized cities have a non-zero value for City Population.";
* Creating summary statistics;
proc univariate data = HW6.hw6tammisettiipums2005;
  histogram CityPop / kernel;
run;

title "Distribution of Household Income Stratified by Mortgage Status";
footnote "Kernel estimate parameters were determined automatically.";
proc sgpanel data = HW6.hw6tammisettiipums2005 noautolegend;
  panelby MortStat;
  histogram HHI / scale = proportion;
run;

*Clearing title;
title;
footnote;

*Closing the pdf;
ods pdf close;

* Turned listing back on;
ods listing;

*Turning date back on;
options date;

*Turning special titles back on;
ods proctitle;

options date;
