/*
Programmed by: Sai Charan Tammisetti
Programmed on: 2023-09-25
Programmed to: Produce a report that produces HW2 Duggins Weather Analysis.pdf 

Modified by: Sai Charan Tammisetti
Modified on: 2023-09-25
Modified to: Worked on Proc print (last proc step)
*/

*Set filerefs and librefs using only relative paths;
x "cd L:\st445\Data";
libname InputDS ".";
filename RawData ".";

*A new library that points to the location where are the new data sets are created;
x "cd S:\Desktop\ST445\HW2";
libname HW2 ".";

* To access the formats stored;
OPTIONS FMTSEARCH = (InputDS);

*Set output destinations;
ods listing close;

*Reading BasicSalesNorth raw data;
data HW2.BasicSalesNorth;
  attrib EmpID label = "Employee ID" length = $4
         Cust label = "Customer" length = $45
         Date label = "Bill Date" format = YYMMDD10.
         Region label = "Customer Region" length = $5
         Hours label = "Hours Billed" format = 5.2
         Rate label = "Bill Rate" format = dollar4.
         TotalDue label = "Amount Due" format = dollar9.2
  ;
  infile RawData("BasicSalesNorth.dat") dlm = '09'x firstobs = 11;
  input Cust $ EmpID $ Region $ Hours Date Rate TotalDue;
run;

*Reading BasicSalesSouth raw data;
data HW2.BasicSalesSouth;
  attrib EmpID label = "Employee ID" length = $4
         Cust label = "Customer" length = $45
         Date label = "Bill Date" format = MMDDYY10.
         Region label = "Customer Region" length = $5
         Hours label = "Hours Billed" format = 5.2
         Rate label = "Bill Rate" format = dollar4.
         TotalDue label = "Amount Due" format = dollar9.2
  ;
  infile RawData("BasicSalesSouth.prn") firstobs = 12;
  input Cust $ 1 - 45 EmpID $ 46-49 Region $ 50-54 Hours 55-59 Date 60-64 Rate 65-67 TotalDue 68-74;
run;

*Reading BasicSalesEastWest raw data;
data HW2.BasicSalesEastWest;
  attrib EmpID label = "Employee ID" length = $4
         Cust label = "Customer" length = $45
         Date label = "Bill Date" format = Date9.
         Region label = "Customer Region" length = $5
         Hours label = "Hours Billed" format = 5.2
         Rate label = "Bill Rate" format = dollar4.
         TotalDue label = "Amount Due" format = dollar9.2
  ;
  infile RawData("BasicSalesEastWest.txt") dlm = ',' firstobs = 12;
  input Cust $ EmpID $ 46-49  Region $ 50-53 Hours 54-57 Date Rate TotalDue;
run;

*Set output destinations;
ods pdf file = "HW2 Tammisetti Basic Sales Report.pdf" style = Journal;
ods rtf file = "HW2 Tammisetti Basic Sales Metadata.rtf" style = Sapphire;
*Preventing data from printing in the report;
options nodate;

*Removing special title;
ods noproctitle;

*Excluding from reporting on PDF;
ODS PDF EXCLUDE ALL;

*Excluding Attributes, EngineHost from printing in proc contents;
ods exclude Attributes EngineHost;

*Title of page 1 of rtf file;
title h = 14pt "Variable-Level Metadata (Descriptor) Information";
title2 h = 10pt "for Records from North Region";

*Creates descriptor information of Basic Sales North data;
proc contents data = HW2.BasicSalesNorth Varnum;
run;

ods exclude Attributes EngineHost;
*Title of page 2 of rtf file;
title2 h = 10pt "for Records from South Region";
proc contents data = HW2.BasicSalesSouth Varnum;
run;

ods exclude Attributes EngineHost;
*Title of page 3 of rtf file;
title2 h = 10pt "for Records from East and West Regions";

*Creates descriptor information of Basic Sales North data;
proc contents data = HW2.BasicSalesEastWest Varnum;
run;


*Title of page 1 of rtf file;
title h = 14pt "Salary Format Details";

*Uses format named BasicAmt- Due and is located in the InputDS library.;
proc format library = InputDS fmtlib;
  select BasicAmt-Due;
run;

* Closing rtf file since we are not gonna use it anymore;
ods rtf close;

* Will be reporting on pdf;
ODS PDF EXCLUDE NONE;

*Title of page 1 of pdf file;
title h = 14pt "Five Number Summaries of Hours and Bill Rate";
title2 h = 10pt "Grouped by Employee and Total Bill Quartile";
footnote j = left h = 8pt "Produced using data from East and West Regions";

*Five Number Summaries of Hours and Bill Rate using data from East and West Regions;
proc means data = HW2.BasicSalesEastWest
          min P25 P50 P75 max
          maxdec = 2 NOLABELS;
  class EmpId TotalDue;
  var Hours Rate;
  format TotalDue BasicAmtDue.;
run;

*Title of page 2 of pdf file;
title h = 14pt "Breakdown of Records by Customer and Customer by Quarter";
footnote j = left h = 8pt "Produced using data from North Region";

*Breakdown of Records by Customer and Customer by Quarter using data from North Region;
proc freq data = HW2.BasicSalesNorth;
  tables Cust Cust * Date /norow nocol;
  format Date QTRR.;
run;

*Sorting data by customer name, if matching then descending date;
proc sort data = HW2.BasicSalesSouth
          out = HW2.Sorted;
  by Cust descending Date;
run;

*Title of page 3 of pdf file;
title h = 14pt "Listing of Selected Billing Records";
footnote j = left h = 8pt "Included: Records with an amount due of atleast $1,000 or from Frank's Franks with a bill rate of $75 or $150.";
footnote2 j = left h = 8pt "Produced using data from South Region";

*Prints Data with an amount due of atleast $1,000 or from Frank's Franks with a bill rate of $75 or $150;
proc print data = HW2.Sorted noobs label; 
  where (TotalDue >= 1000) | (Cust = "Frank's Franks" and (Rate = 75 | Rate = 150));
  id Cust Date EmpID;
  var Hours Rate TotalDue;
  sum Hours TotalDue;
run;

*Clearing title and footnotes;
title;
footnote;

*Turning date back on;
options date;

* Turning special titles back on;
ods proctitle;


*Turning listing back on;
ods listing;

*Closing the pdf file;
ods pdf close;


quit;
