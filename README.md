# Frequency tables

Code written as part of role at Leeds Institute of Clinical Trials Research in order to produce summary tables of patient characteristics by trial arm and overall.

```
macro freqany(dset=,catvar=,catall=,catsort=catformat,trtvar=,trtall=,tot=,header=n,library=library,tabout=,debug=n);
/*dset=	input dataset
  catvar= categorical variable to summarise
  catall= y or n, depending on whether you want to output frequencies for all levels of the categorical 
          variable, even if there is no data for that level (useful when categorical variable is yes or 
	  no where there is no data for either yes or no, N.B. does not include missing if not already 
	  in the data)
  catsort= catformat [DEFAULT] or totfreq, output table will be sorted either by the order the format has 
           been specified in the spec (catformat) or in order of total frequency ordering those with the 
	   highest frequency at the top of the table (totfreq)
  trtvar= treatment variable, leave blank if do not want to include summaries by treatment variable (useful 
          for open DMEC reports etc.)
  trtall= y or n, depending on whether you want to output frequencies for all levels of the treatment 
          variable, even if there is no data for that level (useful if frequency table is out of a subset 
	  of participants, and therefore there will not necessarily be data for both/all treatments/levels 
	  of the treatment variable)
  tot= y or n, depending on whether you want to output a total row (useful when levels of the categorical 
       variable are not mutually exclusive for participants, and totals do not add up to the total number 
       of participants in the study/subgroup)
  header= y or n, n is [DEFAULT], whether you want a header attached to the top of the table
  library= library [DEFAULT] or any other name given to the format library
  tabout= output dataset
  debug= y or n, n is [DEFAULT], option to debug if necessary*/
```
 
Worked example:

```
/*libraries*/
libname x "P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\";
libname library "P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\";
%inc "P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\freqmacro_v2.sas";
%inc "P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\totrowmacro_v2.sas";
%inc "P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\unimacro_v2.sas";
/*defines directory*/
%let dir=P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\;

/*formats*/
proc format library=library; 
  value gender 1="Male" 2="Female"; 
  value trt3tx 1="Treatment A" 2="Treatment B" 3="Treatment C"; 
run;
proc format library=library cntlout=formats;
run;
/*data*/
data ex1;
  input patno age gender trt;
  datalines;
  1 56 1 3
  2 45 2 2
  3 65 1 1
  4 78 2 1
  5 34 2 2
  6 74 1 3
  7 85 1 3
  8 56 2 2
  9 65 1 3
  10 62 1 3
  ;
run;
data ex2;
  set ex1;
  label patno="Participant number"
		age="Age"
		gender="Gender"
		trt="Randomised Treatment";
  format gender gender. trt trt3tx.;
run;

/*macro*/
%freqany(dset=ex2,catvar=gender,catall=n,trtvar=trt,trtall=y,tot=y,header=y,tabout=_extable);

/*ods output specifying ctru style and filename*/
ods rtf file="&dir\_extable.rtf" bodytitle style=ctru; 
options papersize="A4" orientation="portrait";
ods escapechar='^'; footnote;
proc report data=_extable headskip nowindows split="#"
  /*to set the styles for the table*/
  style(report)=[cellspacing=1 borderwidth=4 bordercolor=black just=left rules=groups] 
  style(column)=[fontfamily=arial fontsize=2.5 cellwidth=2.8cm] 
  style(header)=[fontfamily=arial fontsize=2.5 background=CXBFBFBF] 
  style(lines)=[background=white];
  /*specifies columns to use in proc report*/
  column (label treatment_a treatment_b treatment_c tot);
  /*defines specific attributes to give to different columns*/
  define label / left style(column)={cellwidth=6cm} "";
  define treatment_a / center;
  define treatment_b / center;
  define treatment_c / center;
  define tot / center;
  /*to highlight the total row in bold*/
  compute label;
    if _c1_="Total" then call define(_row_,"STYLE","style={fontweight=bold}");
  endcomp;
  /*gives appropriate title*/
  title font=arial height=2.5 bold justify=left
  "This is a wonderfully lovely table";
run;
ods rtf close;

/*saves log with name of executing sas filename*/
%let filename=%sysget(sas_execfilename);
dm 'output; file "P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\&filename..lst" replace;'; 
dm 'log; file "P:\CTRU\Stats\Programming\SAS\Programs\Analytical techniques\TableMacros2017\&filename..log" replace;'; 

```


