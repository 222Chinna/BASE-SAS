/*
Programmed by: Sai Charan Tammisetti
Programmed on: 11/27/2023
Programmed to: Analyze the newly-updated database of electric vechiles

Modified by: Sai Charan Tammisetti
Modified on: 11/28/2023
Modified to: add comments
*/

* Preventing date from printing in the report;
options nodate;

* Removing special title;
ods noproctitle;

* Closing listing destination;
ods listing close;


* Set filerefs and librefs using only relative paths;
X 'cd L:\st445\Data\WashingtonState\';
libname InputDS 'FormatCatalogs';
filename RawData 'RawData';
libname LookUp access 'StructuredData\LookUp.accdb';

*A new library that points to the location where are the new data sets are created;
X 'cd S:\Desktop\st445\Final';
libname Final '.';


* Setting output destination;
ods pdf file = "Tammisetti Washington State Electric Vehicle Study.pdf";

ods EXCLUDE all;

* To access the formats stored;
OPTIONS FMTSEARCH = (Final InputDS);

* Reading in data from EV-CAFV(no).txt file;
Data NODATA;
  attrib Vin length = $10.
         Zip length = $5.
         LegDist length = $2.
         CensusTract2020 length = $11.
         DOLID length = $9.
         ElecUtil length = $200.
         Location length = $200.
         RegDate format = YYMMDD10.
         ;
  infile RawData('EV-CAFV(no).txt') firstobs = 8 truncover;
  input Vin 10. Zip 11-15 LegDist 16-17 DOLID 18-26 @28 
        CensusTract2020 28-38 RegDate
        / ElecUtil 1-200
        / Location 1-200;
run;

* Reading in data from EV-CAFV(yes).txt file;
Data YesDATA (drop = _:);
  attrib RegDate format = YYMMDD10.
         Zip length = $5.
         Vin length = $10.
         LegDist length = $2.;
  infile RawData("EV-CAFV(yes).txt") dlm = '09'x firstobs = 6 dsd truncover;
  input _VinZipDist_ : $19.
        DOLID : $9.
        CensusTract2020 : $11.
        RegDate : YYMMDD10.
        ElecUtil : $200.
        Location : $200.;
  Vin = scan(_VinZipDist_, 1, ',');
  Zip = scan(_VinZipDist_, 2, ',');
  LegDist = scan(_VinZipDist_, 3, ',');
run;

proc format library = Final fmtlib;
  value $Months
    'January' = '01'
    'February' = '02'
    'March' = '03'
    'April' = '04'
    'May' = '05'
    'June' = '06'
    'July' = '07'
    'August' = '08'
    'September' = '09'
    'October' = '10'
    'November' = '11'
    'December' = '12'
  ;
run;

* Reading in data from EV-CAFV(yes).txt file;
/* Used sas documentation to learn about the leave statement
https://documentation.sas.com/doc/en/vdmmlcdc/8.1/lestmtsref/n03wnjww9jjpm8n1q16exvgtoae9.htm#:~:text=The%20LEAVE%20statement%20causes%20processing,only%20in%20a%20DO%20loop. */
data UnkData (keep = VIN Zip LegDist DOLID CensusTract2020 RegDate ElecUtil Location);
  attrib RegDate format = YYMMDD10.
         VIN format = $10.;
  infile RawData("EV-CAFV(unk).txt") dlm = ';' firstobs = 12 dsd truncover;
  array allData[1751] $ 200;
  do i = 1 to 1751;
    input allData[i] : $200. @;
  end;

  VIN = allData[1];
  array ZIPARRAY[250] $5.;
  array LegDistArray[250] $2.;
  array DOLArray[250] $9.;
  array CensusTractArray[250] $11.;
  array RegDateArray[250] $20.;
  array ElecUtilArray[250] $200.;
  array LocationArray[250] $200.;
  do i = 1 to 250;
    ZIPARRAY[i] = allData[i + 1];
    LegDistArray[i] = allData[i + 251];
    DOLArray[i] = allData[i + 501];
    CensusTractArray[i] = allData[i + 751];
    RegDateArray[i] = allData[i + 1001];
    ElecUtilArray[i] = allData[i + 1251];
    LocationArray[i] = allData[i + 1501];
  end;

  do i = 1 to 250 until (missing(ZIPARRAY[i]) and missing(DOLArray[i]) and missing(CensusTractArray[i]) and 
                         missing(RegDateArray[i]) and missing(LegDistArray[i]) and
                         missing(ElecUtilArray[i]) and missing(LocationArray[i]));
    Zip = ZIPARRAY[i];
    LegDist = LegDistArray[i];
    DOLID = DOLArray[i];
    CensusTract2020 = CensusTractArray[i];
    _RegDate_ = RegDateArray[i];
    Month = input(put(scan(_RegDate_, 1, ' '), $Months.), 2.);
    Day = input(scan(scan(_RegDate_,2, ' '), 1, ','), 2.);
    Year = input(scan(_RegDate_,3, ' '), 4.);
    RegDate = mdy(Month, Day, Year);
    ElecUtil = ElecUtilArray[i];
    Location = LocationArray[i];
    if (missing(Zip) and missing(LegDist) and missing(DOLID) and 
                         missing(CensusTract2020) and missing(RegDate) and
                         missing(ElecUtil) and missing(Location)) then leave;
    output;
  end;
run;

* Used to combine all the datasets;
data AllCAFV;
  attrib Vin length = $10. format = $10.
         ZipN format = Z5.
         RegDate format = YYMMDD10.
         CAFV length = $60.
         ;
  set NoData (in = no)
      YesData (in = yes)
      UnkData (in = Unv)
      ;
  if not missing(Zip) then ZipN = input(Zip, 5.);
  CAFVCODE = 1 * Yes + 2 * No + 3 * Unv;
  if CAFVCODE = 1 then CAFV = 'Clean Alternative Fuel Vehicle Eligible';
    else if CAFVCODE = 2 then CAFV = 'Not eligible due to low battery range';
    else CAFV = 'Eligibility unknown as battery range has not been researched';
run;

proc sort data = ALLCAFV;
  by DOLID;
run;

* Used to merge all datasets and non-domestic registrations access data;
data Final1 (drop = St);
  attrib StateCode length = $2.
         StateName length = $25.;
  merge ALLCAFV LookUp."Non-Domestic Registrations"n;
  by DOLID;
  StateCode = St;
  if StateCode = "AP" then do;
    StateName = "Armed Forces Pacific";
    ElecUtil = "NON WASHINGTON STATE ELECTRIC UTILITY";
  end;
    else if StateCode = "BC" then do;
      StateName = "British Columbia";
      ElecUtil = "NON WASHINGTON STATE ELECTRIC UTILITY";
    end;
run;

proc sort data = Final1;
  by VIN;
run;

* Used to merge all datasets and demographics access data;
data Final2;
  merge Final1(in = inMy) LookUp."Demographics"n; 
  by VIN;
  if inMy = 1 then output Final2;
run;

proc sort data = Final2;
  by ZIPN;
run;

* Used to merge the Final2 and Sashelp.zipcode datasets and almost all the data cleaning is done here;
data Final.FinalTammisettiEV (drop = STATENAME2 X Y State City City2 ALIAS_CITY
                                     AREACODE AREACODES COUNTY DST GMTOFFSET MSA
                                     PONAME TIMEZONE ZIP_CLASS COUNTYNM ALIAS_CITYN
                                     LOCATION makeCat modelCat);
  attrib Vin label = "Vehicle Identification Number"
         MaskVin label = "Partially Masked VIN" length = $10.
         Zip label = "Vehicle Registration Zip Code"
         ZipN label = "Vehicle Registration Zip Code"
         CityName label = "City Name"
         StateFips label = "State FIPS"
         StateCode label = "State Postal Code"
         StateName label = "State Name"
         CountyFips label = "County FIPS"
         CountyName label = "County Name"
         LegDist label = "Vechile Registration Legislative District"
         DOLID label = "WA Department of Licensing ID"
         CensusTract2020 label = "Vehicle Registration US Census Tract"
         RegDate label = "Last Registration Date"
         ModelYear label = "Vehicle Model Year"
         EVType label = "EV Type (long)"
         EVTypeShort label = "EV Type (short)" length = $4.
         Erange label = "Electric Range"
         BaseMSRP label = "Reported Base MSRP"
         Make label = "Vehicle Make" length = $20.
         Model label = "Vehicle Model" length = $25.
         CAFV label = "Clean Alternative Fuel Vehicle Eligible Description"
         CAFVCode label = "Clean Alternative Fuel Vehicle Eligible (1=Y,2=N,3=U)"
         ElecUtil label = "Electric Utilities Servicing Vehicle Registration Address"
         PrimaryUtil label = "Primary Electric Utility at Vehicle Location"
         Latitude label = "Vehicle Registration Latitude (decimal)" format = 13.8
         Longitude label = "Vehicle Registration Longitude (decimal)" format = 13.8
         ;
  merge Final2 (in = inA) Sashelp.ZipCode(rename=(Zip = ZipN));
  by ZipN;
  StateFIPS = State;
  CityName = City;
  CountyFips = COUNTY;
  CountyName = CountyNM;
  MaskVin = CATS('*******', substr(Vin, 8));
  if not missing(ElecUtil) then do;
    PrimaryUtil = scan(ElecUtil, 1, "|");
  end;
  EVTypeShort = scan(scan(EVType, 2, "("), 1, ")");
  Latitude = input(scan(scan(Location, 2, "("), 1, " "), 13.8);
  Longitude = input(scan(scan(scan(Location, 2, "("), 2, " "),1,")"), 13.8);
  Make = MakeCat;
  Model = ModelCat;
  informat Model $EVModel.;
  informat Make $EVMake.;
  if missing(BaseMSRP) then BaseMSRP = .M;
    else if BaseMSRP = 0 then BaseMSRP = .Z;
    else if BaseMSRP < 0 then BaseMSRP = .I;
  if inA = 1 then output Final.FinalTammisettiEV;
run;

proc sort data = Final.FinalTammisettiEV out = Final.FinalTammisettiUniqueVinMask nodupkey;
  by VIN;
run;


proc sort data = Final.FinalTammisettiEV out = finalDataset3 (keep = Make Model) nodupkey;
  by Make Model;
run;


proc transpose data = finalDataset3 out = Final.FinalTammisettiModels
               prefix = Model;
  by Make;
  var Model;
run;


proc freq data = Final.FinalTammisettiEV;
  tables CAFVCode * EVTypeShort / out=Final.FinalTammisettiCafvCrossEv;
run;

libname LookUp clear;
ods pdf close;

*Turning special titles back on;
ods proctitle;

* Turned listing back on;
ods listing;

*Turning date back on;
options date;
