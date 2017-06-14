/**************************************************************************
**	Filename				:   freqmacro_v2.sas
**	Date created			:   12/05/2014
**	Last amended       		:   09/02/2017
**	Purpose Of Program 		:   Creates frequency tables for categorical data
**	Statistician	   		:   Laura Collett
**	SAS version      		:   9.4
**	Datasets created  		:   &tabout
**	Output files			:   No
**	Reviewed by				:   Laura Collett, Alison Pullan, Jo Webster
**	Date reviewed			:   09/02/2017
**************************************************************************/

%macro freqany(dset=,catvar=,catall=,catsort=catformat,trtvar=,trtall=,tot=,header=n,library=library,tabout=,debug=n);
/*dset=		input dataset
  catvar=	categorical variable to summarise
  catall=	y or n, depending on whether you want to output frequencies
 			for all levels of the categorical variable, even if there 
            is no data for that level (useful when categorical variable 
            is yes or no where there is no data for either yes or no, 
            N.B. does not include missing if not already in the data)
  catsort=	catformat [DEFAULT] or totfreq, output table will be sorted 
            either by the order the format has been specified in the spec 
            (catformat) or in order of total frequency ordering those with 
            the highest frequency at the top of the table (totfreq)
  trtvar=	treatment variable, leave blank if do not want to include 
            summaries by treatment variable (useful for open DMEC reports 
            etc.)
  trtall=	y or n, depending on whether you want to output frequencies
			for all levels of the treatment variable, even if there is no
			data for that level (useful if frequency table is out of a 
            subset of participants, and therefore there will not 
            necessarily be data for both/all treatments/levels of the 
            treatment variable)
  tot=		y or n, depending on whether you want to output a total row 
            (useful when levels of the categorical variable are not 
            mutually exclusive for participants, and totals do not add 
            up to the total number of participants in the study/subgroup)
  header=   y or n, n is [DEFAULT], whether you want a header attached 
            to the top of the table
  library=	library [DEFAULT] or any other name given to the format 
            library
  tabout=	output dataset
  debug=    y or n, n is [DEFAULT], option to debug if necessary*/

/*MACRO IS SPLIT UP INTO SECTIONS USING IF/ELSE STATEMENTS, ACCORDING TO THE OPTIONS
FOR WHETHER TO INCLUDE ALL LEVELS OF CATEGORICAL VARIABLE, SUMMARY BY TREATMENT,
ALL LEVELS OF TREATMENT VARIABLE, OR A TOTAL ROW*/

/*CALLS TOTROWMACRO, EDIT THIS IS TOTROWMACRO IS SAVED IN A DIFFERENT PLACE
FOR YOUR OWN TRIAL PROGRAMS*/
%include "C:\Users\laura.collett\Documents\Coding\SAS\table_macros\totrowmacro_v2.sas";

/*GIVES PROMPTS THAT WILL NOT ALLOW THE PROGRAM TO RUN IF CERTAIN CRITERIA
ARE NOT MET OR OPTIONS HAVE NOT BEEN SPECIFIED*/
%let dsempty=0;
data _null_;
  if eof then call symput("dsempty",1); stop;
  set &dset end=eof;
run;
/*LIBRARY=LIBRARY IS DEFAULT BUT IF LIBRARY= IS INCLUDED AND NOT SPECIFIED*/
%if &library= %then %do;
  %put WARNING: You have not specified a format library!;
  %goto exit;
%end;
/*IF LIBRARY DOES NOT EXIST*/
%else %if %sysfunc(libref(&library))>0 %then %do;
  %put WARNING: The &library format library you have specified does not exist!;
  %goto exit;
%end;
%else %do;
  /*IF DSET NOT SPECIFIED*/
  %if &dset= %then %do; 
    %put WARNING: You have not specified an input dataset!;
    %goto exit;
  %end;
  /*IF DSET DOES NOT EXIST*/
  %else %if %sysfunc(exist(&dset))=0 %then %do;
    %put WARNING: The input dataset you have specified does not exist!;
    %goto exit;
  %end;
  /*IF DSET EXISTS BUT IS EMPTY*/
  %else %if &dsempty=1 %then %do;
    %put WARNING: the dataset you have specified is empty!;
    %goto exit;
  %end;
  /*IF LIBRARY AND DSET PRESENT AND CORRECT*/
  %else %do;
	/*IF TREATMENT IS LEFT BLANK THEN D0 NOT WANT TREATMENT BY ARM, ONLY TOTAL*/
    %if &trtvar= %then %do;
	  /*IF CATVAR SPECIFIED DOES NOT EXIST*/
      %let dsid=%sysfunc(open(&dset));
	  %if %sysfunc(varnum(&dsid,&catvar))=0 %then 
	    %put WARNING: The specified variable &catvar does not exist in dataset &dset!;
	  /*IF CATVAR DOES EXIST, CARRY ON WITH MACRO*/
	  %else %do;
        %let rc=%sysfunc(close(&dsid));
		/*THESE DATASTEPS CREATE MACRO VARIABLES FOR ALL RELEVANT AND NECESSARY INFORMATION
		REQUIRED IN THE REST OF THE MACRO AND USED THROUGHOUT, INLUDING FORMAT NAMES AND LABELS*/
        data _setcall1;
	      set &dset;
	      /*CATEGORICAL VARIABLE SETTINGS*/
		  /*CF=CATEGORICAL VARIABLE FORMAT NAME*/
          cf=vformatn(&catvar);
		  /*MACRO VARIABLE CREATION*/
	      call symput("catf",vformatn(&catvar));
	      call symput("catlab",vlabel(&catvar));
		  call symput("cflen",cat(vformatw(&catvar),".",vformatd(&catvar)));
		  /*SEE WHETHER CATEGORICAL OR CONTINUOUS*/
		  if cf="F" or cf="BEST" then call symput("cont",1);
		  else call symput("cont",0);
        run;
		data _dset;
		  set &dset;
		  if &cont=0 then do;
		    if &catvar=. then &catvar=9876;
			end;
		run;
		data _setcall2;
		  set _dset;
		  /*STORES MAX LENGTH OF CATVAR SO LABELS WILL NOT BE TRUNCATED*/
          cvl=max(vformatw(&catvar),length("Total"));
          call symput("catlen",cvl);
		  /*FIND CODE FOR OTHER*/
		  othert=put(&catvar,&catf..);
		  other=cats(&catvar);
		  if othert="Other" then call symput("otherf",other);
		run;
		%put &otherf;
	  %end;
    %end;
	/*IF TREATMENT IS NOT LEFT BLANK TREATMENT VARIABLE HAS BEEN SPECIFIED, TO BE SUMMARISED*/
    %else %if &trtvar~= %then %do;
	  /*IF CATVAR SPECIFIED DOES NOT EXIST*/
      %let dsid=%sysfunc(open(&dset));
	  %if %sysfunc(varnum(&dsid,&catvar))=0 and %sysfunc(varnum(&dsid,&trtvar))>0 %then %do;
        %put WARNING: The specified variable &catvar does not exist in dataset &dset!;
        %let rc=%sysfunc(close(&dsid));
		%goto exit;
	  %end;
	  /*IF TRTVAR SPECIFIED DOES NOT EXIST*/
      %else %if %sysfunc(varnum(&dsid,&catvar))>0 and %sysfunc(varnum(&dsid,&trtvar))=0 %then %do;
        %put WARNING: The specified variable &trtvar does not exist in dataset &dset!;
        %let rc=%sysfunc(close(&dsid));
		%goto exit;
      %end;
	  /*IF NEITHER CATVAR NOR TRTVAR SPECIFIED DO NOT EXIST*/
      %else %if %sysfunc(varnum(&dsid,&catvar))=0 and %sysfunc(varnum(&dsid,&trtvar))=0 %then %do;
        %put WARNING: The specified variables &catvar and &trtvar do not exist in dataset &dset!;
        %let rc=%sysfunc(close(&dsid));
		%goto exit;
      %end;
	  /*IF BOTH CATVAR AND TRTVAR SPECIFIED EXIST CARRY ON WITH MACRO*/
      %else %do;
        %let rc=%sysfunc(close(&dsid));
		/*THESE DATASTEPS CREATE MACRO VARIABLES FOR ALL RELEVANT AND NECESSARY INFORMATION
		REQUIRED IN THE REST OF THE MACRO AND USED THROUGHOUT, INLUDING FORMAT NAMES AND LABELS*/
        data _setcall1;
  	      set &dset;
	      /*CATEGORICAL VARIABLE SETTINGS*/
		  /*CF=CATEGORICAL VARIABLE FORMAT NAME*/
		  cf=vformatn(&catvar);
	      /*TREATMENT VARIABLE SETTINGS*/
		  tf=vformatn(&trtvar);
		  /*MACRO VARIABLE CREATION*/
	      call symput("catf",vformatn(&catvar));
	      call symput("catlab",vlabel(&catvar));
		  call symput("cflen",cat(vformatw(&catvar),".",vformatd(&catvar)));
	      call symput("trtf",vformatn(&trtvar));
		  /*SEE WHETHER CATEGORICAL OR CONTINUOUS*/
          if cf="F" or cf="BEST" then call symput("cont",1);
		  else call symput("cont",0);
		run;
		data _dset;
		  set &dset;
	      if &trtvar=. then &trtvar=9876;
		  if &cont=0 then do;
		    if &catvar=. then &catvar=9876;
			end;
		run;
		data _setcall2;
		  set _dset;
		  /*STORES MAX LENGTH OF CATVAR SO LABELS WILL NOT BE TRUNCATED*/
          cvl=max(vformatw(&catvar),length("Total"));
          call symput("catlen",cvl);
		  /*FIND CODE FOR OTHER*/
		  othert=put(&catvar,&catf..);
		  other=cats(&catvar);
		  if othert="Other" then call symput("otherf",other);
		run;
		%put &otherf;
      %end;
	%end;
    /*creates header*/
	data _header;
	  length label $255.;
	  label="^S={font_weight=bold}&catlab";
    run;
	/*X#Y# CORRESPOND TO WHETHER TO INCLUDE ALL LEVELS OF CATEGORICAL VARIABLE, 
	SUMMARY BY TREATMENT, ALL LEVELS OF TREATMENT VARIABLE, OR A TOTAL ROW:
	X0Y1=NOT SPLIT BY TREATMENT, ONLY TOTAL COLUMN, ONLY CAT WITH DATA
    X0Y2=NOT SPLIT BY TREATMENT, ONLY TOTAL COLUMN, ALL CAT IN FORMAT
    X1Y1=ONLY TREATMENTS WITH DATA, ONLY CAT WITH DATA
    X1Y2=ONLY TREATMENTS WITH DATA, ALL CAT IN FORMAT
    X2Y1=ALL TREATMENTS IN FORMAT, ONLY CAT WITH DATA
    X2Y2=ALL TREATMENTS IN FORMAT, ALL CAT IN FORMAT*/

	/*CAN CREATE TOTAL COLUMN FIRST, FOR TABLES WITH ONLY CATEGORICAL LEVELS WITH DATA
    THEN AGAIN FOR ALL CATEGORICAL VARIABLES IN FORMAT, THEN CAN REFER TO THESE DATASETS
    IN ALL THE OTHER TABLES*/
    /*COUNT AND PERCENT BY CATVAR FOR TOTAL COLUMN*/
    proc freq data=_dset noprint;
	  tables &catvar / out=_ov1;
    run;
    /*COMBINES COUNT AND PERCENT TO ONE DECIMAL PLACE IN NEW VAR TOT*/
    data _ov2 (keep=&catvar tot count);
	  set _ov1;
	  length tot $15.;
	  tot=cat(cats(put(count,4.))," (",cats(put(percent,5.1)),"%)");
    run;
    /*TOTAL ROW USING TOTROW MACRO*/
    %totrow(dset=_dset,trtvar=&trtvar,trtall=n,library=&library,tout=_tot);

	/*X0Y1=NOT SPLIT BY TREATMENT, ONLY TOTAL COLUMN, ONLY CAT WITH DATA*/
	%if &catall=n %then %do;
	  /*CATSORT OPTION*/
	  %if &catsort=catformat %then %do;
        data _ov3;
	      set _ov2 (drop=count);
        run;
      %end;
      %else %if &catsort=totfreq %then %do;
        proc sort data=_ov2 out=_ov3a (drop=count);
	      by descending count;
        run;
		data _ov3;
		  set _ov3a (where=(&catvar~=&otherf))
		      _ov3a (where=(&catvar=&otherf));
		run;
	  %end;
	  /*REFORMATS LABEL VARIABLE AS TEXT TO INCLUDE TOTAL ROW*/
	  data x0y1_1 (drop=&catvar);
	    length label $&catlen.;
	    set _ov3;
	    label=cats(put(&catvar,&catf..));
	    label label="&catlab" tot="Total";
	  run;
	  /*ADDS TOTAL ROW*/
	  data x0y1_2;
	    set x0y1_1 _tot;
	  run;
	  %if &trtvar= %then %do;
        /*HEADER OR NOT*/
	    %if &header=y %then %do;
		  data &tabout;
		    set _header x0y1_2;
		  run;
		%end;
	    /*IF NOT SUMMARIES BY TREATMENT OUTPUT ABOVE DATASET*/
        %else %if &header=n %then %do;
	      data &tabout;
	        set x0y1_2;
	      run;
		%end;
		%goto exit;
	  %end;
	%end;
    /*X0Y2=NOT SPLIT BY TREATMENT, ONLY TOTAL COLUMN, ALL CAT IN FORMAT*/
	%else %if &catall=y %then %do;
	  /*DETERMINES WHETHER CHARACTER OR NUMERIC*/
	  %if &cont=1 %then %do;
	  proc sql;
	    create table x0y2_2 as 
		  select distinct &catvar
		  from _dset
		  group by &catvar
		  order by &catvar;
	  quit;
	  %end;
	  %else %if &cont=0 %then %do;
	  /*ISOLATES CATVAR FORMAT LIBRARY*/
	  proc format library=&library cntlout=x0y2_1 (keep=fmtname start label);
	    select &catf;
	  run;
	  /*ISOLATES NUMBERS IN CATVAR FORMAT*/
	  data x0y2_2 (keep=&catvar);
		set x0y2_1;
		&catvar=input(cats(start),4.);
		lab=lowcase(label);
		if lab~="missing";
	  run;
	  %end;
	  /*MERGES WITH FREQUENCY DATASET*/
	  data _ov3;
		merge _ov2 x0y2_2;
		by &catvar;
		if count=. then do;
		  count=0;
		  if tot="" then tot=cat(cats(put(count,4.))," (0.0%)");
		end;
	  run;
	  /*CATSORT OPTION*/
	  %if &catsort=catformat %then %do;
        data _ov4;
	      set _ov3 (drop=count);
        run;
      %end;
      %else %if &catsort=totfreq %then %do;
        proc sort data=_ov3 out=_ov4a (drop=count);
	      by descending count;
        run;
		data _ov4;
		  set _ov4a (where=(&catvar~=&otherf))
		      _ov4a (where=(&catvar=&otherf));
		run;
	  %end;
	  /*REFORMATS LABEL VARIABLE AS TEXT TO INCLUDE TOTAL ROW*/
	  data x0y2_3 (drop=&catvar);
		length label $&catlen.;
		set _ov4;
		label=cats(put(&catvar,&catf..));
		label label="&catlab" tot="Total";
	  run;
	  /*ADDS TOTAL ROW*/
	  data x0y2_4;
		set x0y2_3 _tot;
	  run;
	  %if &trtvar= %then %do;
	    /*HEADER OR NOT*/
	    %if &header=y %then %do;
		  data &tabout;
		    set _header x0y2_4;
		  run;
		%end;
		%else %if &header=n %then %do;
	      /*IF NOT SUMMARIES BY TREATMENT OUTPUT ABOVE DATASET*/
	      data &tabout;
	        set x0y2_4;
	      run;
		%end;
		%goto exit;
	  %end;
	%end;

    /*WHEN TRTVAR HAS BEEN SPECIFIED*/
    %if &trtvar~= %then %do;
	  /*CREATE COLUMN PERCENTAGES USING PROC SQL*/
      proc sql;
        create table _tab2 as
        select _dset.&trtvar, &catvar, count(&catvar) as count,
        calculated count/subtotal as percent format=percent8.1
        from _dset,
          (select &trtvar, count(*) as subtotal from _dset group by &trtvar) as _dset2
          where _dset.&trtvar=_dset2.&trtvar
          group by _dset.&trtvar, &catvar
		  order by _dset.&catvar, &trtvar;
      quit;
	  /*PUTS COUNTS AND PERCENTAGES INTO ONE VARIABLE*/
      data _tab13 (keep=&trtvar &catvar freq count);
	    set _tab2;
	    length freq $15.;
	    freq=cat(cats(put(count,4.))," (",cats(put(percent,percent8.1)),")");
      run;

      /*X1=ONLY TREATMENTS WITH DATA*/
      %if &trtall=n %then %do;
        %totrow(dset=_dset,trtvar=&trtvar,trtall=n,library=library,tout=_tot);
	    /*X1Y1=ONLY TREATMENTS WITH DATA, ONLY CAT WITH DATA*/
	    %if &catall=n %then %do;
	      data _tab14;
	        set _tab13;
	      run;
	    %end;
	    /*X1Y2=ONLY TREATMENTS WITH DATA, ALL CAT IN FORMAT*/
	    %if &catall=y %then %do;
	      /*DETERMINES WHETHER CHARACTER OR NUMERIC*/
	      %if &cont=1 %then %do;
	      proc sql;
	        create table x1y2_2 as 
		      select distinct &catvar
		      from _dset
		      group by &catvar
		      order by &catvar;
	      quit;
	      %end;
	      %else %if &cont=0 %then %do;
	      /*ISOLATES CATVAR FORMAT LIBRARY*/
	      proc format library=&library cntlout=x1y2_1 (keep=fmtname start label);
	        select &catf;
	      run;
	      /*ISOLATES NUMBERS IN CATVAR FORMAT*/
	      data x1y2_2 (keep=&catvar);
	        set x1y2_1;
	        &catvar=input(cats(start),4.);
	        lab=lowcase(label);
	        if lab~="missing";
	      run;
		  %end;
	      /*MERGES WITH SUMMARY TABLE USING PROC SQL*/
		  data _tab14;
		    merge x1y2_2 _tab13;
            by &catvar;
          run;
	    %end;
      %end;

      /*X2=ALL TREATMENTS IN FORMAT*/
      %else %if &trtall=y %then %do;
        %totrow(dset=_dset,trtvar=&trtvar,trtall=y,library=library,tout=_tot);
        /*X2Y1=ALL TREATMENTS IN FORMAT, ONLY CAT WITH DATA*/
	    %if &catall=n %then %do;
	      /*ISOLATES TRTVAR FORMAT LIBRARY*/
	      proc format library=&library cntlout=x2y1_1 (keep=fmtname start label);
	        select &trtf;
	      run;
	      /*ISOLATES NUMBERS IN TRTVAR FORMAT*/
		  data x2y1_2 (keep=&trtvar);
			set x2y1_1;
			&trtvar=input(cats(start),4.);
			lab=lowcase(label);
			if lab~="missing";
		  run;
		  /*MERGES WITH SUMMARY TABLE*/
		  proc sort data=_tab13 out=x2y1_3;
		    by &trtvar;
		  run;
		  data _tab14;
		    merge x2y1_2 x2y1_3;
            by &trtvar;
          run;
	    %end;
		/*X2Y2=ALL TREATMENTS IN FORMAT, ALL CAT IN FORMAT*/
	    %else %if &catall=y %then %do;
	      /*ISOLATES TRTVAR FORMAT LIBRARY*/
	      proc format library=&library cntlout=x2y2_2 (keep=fmtname start label);
		    select &trtf;
          run;
	      /*ISOLATES NUMBERS IN TRTVAR FORMAT*/
	      data x2y2_4 (keep=fmtnametrt labeltrt leveltrt);
		    set x2y2_2;
		    fmtnametrt=fmtname;
		    labeltrt=label;
		    leveltrt=start*1;
		    lab=lowcase(label);
		    if lab~="missing";
	      run;
	      /*DETERMINES WHETHER CHARACTER OR NUMERIC*/
	      %if &cont=1 %then %do;
	      proc sql;
	        create table x2y2_3 as 
		      select distinct &catvar
		      from _dset
		      group by &catvar
		      order by &catvar;
	      quit;
	      /*MERGES CATVAR AND TRTVAR FORMAT NUMBERS TO CREATE ALL COMBINATIONS*/
		  data x2y2_5;
            set x2y2_3 (keep=&catvar);
            do i=1 to n;
              set x2y2_4 (keep=leveltrt rename=(leveltrt=&trtvar)) point=i nobs=n;
	          output;
            end;
          run;
	      %end;
	      %else %if &cont=0 %then %do;
	      /*ISOLATES CATVAR FORMAT LIBRARY*/
	      proc format library=&library cntlout=x2y2_1 (keep=fmtname start label);
		    select &catf;
	      run;
	      /*ISOLATES NUMBERS IN CATVAR FORMAT*/
	      data x2y2_3 (keep=fmtnamecv labelcv levelcv);
		    set x2y2_1;
		    fmtnamecv=fmtname;
		    labelcv=label;
		    levelcv=start*1;
		    lab=lowcase(label);
		    if lab~="missing";
	      run;
	      /*MERGES CATVAR AND TRTVAR FORMAT NUMBERS TO CREATE ALL COMBINATIONS*/
		  data x2y2_5;
            set x2y2_3 (keep=levelcv rename=(levelcv=&catvar));
            do i=1 to n;
              set x2y2_4 (keep=leveltrt rename=(leveltrt=&trtvar)) point=i nobs=n;
	          output;
            end;
          run;
		  %end;
		  /*MERGES WITH SUMMARY TABLE*/
		  data _tab14;
		    merge x2y2_5 _tab13;
            by &catvar &trtvar;
          run; 
	    %end;
      %end;

      /*CREATES ZEROS FOR CELLS THAT ARE BLANK WHEN OPTIONS TRTALL=Y OR CATALL=Y*/
      /*SORTS DATASET BY CATVAR*/
      proc sort data=_tab14 out=_tab3;
	    by &catvar;
      run;
      /*TRANSPOSES TO DISTINGUISH BLANK CELLS*/
      proc transpose data=_tab3 out=_tab4 prefix=&trtvar;
	    var &trtvar freq count;
	    by &catvar;
	    id &trtvar;
      run;
      proc transpose data=_tab4 out=_tab5;
	    var &trtvar:;
	    by &catvar;
      run;
      /*ADDS ZEROS TO CELLS WHERE BLANK*/
      data _tab6 (drop=count len trtlen);
	    set _tab5;
	    count2=count*1;
	    if count2=. then do;
	      count2=0;
	      trtlen=length("&trtvar.");
	      len=length(_name_);
	      if &trtvar="" then &trtvar=substr(_name_,trtlen+1,len);
	      if freq="" then freq=cat(cats(put(count2,4.))," (0.0%)");
	      if &catvar=. and vtype(&catvar)="N" then delete;
	      &trtvar=tranwrd(&trtvar,"_"," ");
	    end;
      run;
	  /*CREATES TOTAL COUNTS BY TREATMENT SO CAN SORT BY THIS IF DESIRED*/
      proc sort data=_tab6 out=_tab7;
	    by &catvar &trtvar;
      run;
      data _tab8 (drop=count2);
	    set _tab7;
	    retain count3;
	    by &catvar;
	    if first.&catvar then count3=count2;
	    else count3=count3+count2;
      run;
      proc sort data=_tab8 out=_tab9;
	    by &catvar descending &trtvar;
      run;
      data _tab10 (drop=count3);
	    set _tab9;
	    retain count;
	    by &catvar;
	    if first.&catvar then count=count3;
	    else count=count;
      run;
      proc sort data=_tab10 out=_tab11;
	    by &catvar &trtvar;
      run;
      /*TRANSPOSES TO TABLE LAYOUT*/
      proc transpose data=_tab11 out=_tab12 (drop=_name_);
	    var freq;
	    by &catvar count;
	    id &trtvar;
	    idlabel &trtvar;
      run;
      /*MERGED WITH TOTAL COLUMN*/
	  %if &catall=n %then %do;
      data _fin1 (drop=&catvar);
	    merge _tab12 _ov2;
	    by &catvar;
		if &cont=1 then label=putn(&catvar,&cflen);
		else if &cont=0 then label=put(&catvar,&catf..);
      run;
	  %end;
	  %else %if &catall=y %then %do;
      data _fin1 (drop=&catvar);
	    merge _tab12 _ov3;
	    by &catvar;
		if &cont=1 then label=putn(&catvar,&cflen);
		else if &cont=0 then label=put(&catvar,&catf..);
      run;
	  %end;
	%end;
	/*CATSORT OPTION*/
    %if &catsort=catformat %then %do;
      data _fin2;
	    set _fin1 (drop=count);
      run;
    %end;
    %else %if &catsort=totfreq %then %do;
      proc sort data=_fin1 out=_fin2a (drop=count);
	    by descending count;
      run;
		data _fin2;
		  set _fin2a (where=(label~="Other"))
		      _fin2a (where=(label="Other"));
		run;
	%end;
    /*ADDS TOTAL ROW*/
    %if &tot=y %then %do;
	  /*HEADER OR NOT*/
	  %if &header=y %then %do;
	    data &tabout;
	      length label $255.;
	      set _header _fin2 _tot;
	      label label=&catlab
	  	        tot="Total";
        run;
	  %end;
	  %else %if &header=n %then %do;
        data &tabout;
	      length label $255.;
	      set _fin2 _tot;
	      label label=&catlab
	  	        tot="Total";
        run;
	  %end;
    %end;
	/*ADDS WITHOUT TOTAL ROW*/
    %else %if &tot=n %then %do;
	  /*HEADER OR NOT*/
	  %if &header=y %then %do;
        data &tabout;
	      length label $255.;
	      set _header _fin2;
	      label label=&catlab
		        tot="Total";
        run;
	  %end;
	  %else %if &header=n %then %do;
        data &tabout;
	      length label $255.;
	      set _fin2;
	      label label=&catlab
		        tot="Total";
        run;
	  %end;
    %end;
  %end;
%end;
/*GIVES PROMPT TO TELL USER CONTINUOUS VARIABLE HAS BEEN USED INSTEAD OF CATEGORICAL*/
%if &cont=1 %then %put WARNING: the character variable you have specified is numeric or does not 
have a categorical format. The summary produced may not be as informative as you would like!;

%exit:

/*DEBUG YES OR NO, DELETES INTERMEDIATE DATASETS IF YES*/
%if &debug=n %then %do;
  proc datasets lib=work nolist;
    delete _dset _header _setcall: x0y1: x0y2: x1y1: x1y2: x2y1: x2y2: _tab1-_tab15 _fin: _ov: _tot;
  run; 
quit;
%end;
%mend;


*****************************END OF MACRO*********************************;
