/**************************************************************************
**	Filename				:   freqmacro_v2.1.sas
**	Date created			:   12/05/2014
**	Last amended       		:   08/06/2017
**	Purpose Of Program 		:   Creates frequency tables for categorical data
**	Statistician	   		:   Laura Collett
**************************************************************************/

/*directory*/
%let dir=P:\LSTM\SAS\frecMacro;
/*macros*/
%include "&dir\totrow.sas";
%include "&dir\procs.sas";

/*main macro*/
%macro freqany(dset=,catvar=,catall=,catsort=catformat,trtvar=,trtall=,tot=,header=n,library=library,tabout=,debug=n);

/*GIVES PROMPTS THAT WILL NOT ALLOW THE PROGRAM TO RUN IF CERTAIN CRITERIA
ARE NOT MET OR OPTIONS HAVE NOT BEEN SPECIFIED*/
%let dsempty=0;
data _null_;
  if eof then call symput("dsempty",1); stop;
  set &dset end=eof;
run;
%if &library= %then %do;
  %put WARNING: You have not specified a format library!;
  %goto exit;
%end;
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
          if &trtvar=. then &trtvar=9876;
          if &cont=0 and &catvar=. then &catvar=9876;
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
          /*MACRO VARIABLE CREATION*/
          call symput("catf",vformatn(&catvar));
          call symput("catlab",vlabel(&catvar));
          call symput("cflen",cat(vformatw(&catvar),".",vformatd(&catvar)));
          /*TREATMENT VARIABLE SETTINGS*/
          tf=vformatn(&trtvar);
          call symput("trtf",vformatn(&trtvar));
          /*SEE WHETHER CATEGORICAL OR CONTINUOUS*/
          if cf="F" or cf="BEST" then call symput("cont",1);
          else call symput("cont",0);
        run;
        data _dset;
          set &dset;
          if &trtvar=. then &trtvar=9876;
          if &cont=0 and &catvar=. then &catvar=9876;
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
      %end;
	%end;
	/*creates header*/
	%header(out=_header,lab=&catlab);
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
	    %set(in=_ov2 (drop=count),out=_ov3);
      %end;
      %else %if &catsort=totfreq %then %do;
	    %procSortDescCount(in=_ov2,out=_ov3a);
	    %set(in=_ov3a (where=(&catvar~=&otherf)) _ov3a (where=(&catvar=&otherf)),out=_ov3);
	  %end;
	  /*REFORMATS LABEL VARIABLE AS TEXT TO INCLUDE TOTAL ROW*/
	  data x0y1_1 (drop=&catvar);
	    length label $&catlen.;
	    set _ov3;
	    label=cats(put(&catvar,&catf..));
	    label label="&catlab" tot="Total";
	  run;
	  /*ADDS TOTAL ROW*/
	  %set(in=x0y1_1 _tot,out=x0y1_2);
	  %if &trtvar= %then %do;
        /*HEADER OR NOT*/
	    %if &header=y %then %do;
	      %set(in=_header x0y1_2,out=&tabout);
		%end;
	    /*IF NOT SUMMARIES BY TREATMENT OUTPUT ABOVE DATASET*/
        %else %if &header=n %then %do;
	      %set(in=x0y1_2,out=&tabout);
		%end;
		%goto exit;
	  %end;
	%end;
    /*X0Y2=NOT SPLIT BY TREATMENT, ONLY TOTAL COLUMN, ALL CAT IN FORMAT*/
	%else %if &catall=y %then %do;
	  /*DETERMINES WHETHER CHARACTER OR NUMERIC*/
	  %if &cont=1 %then %do;
        %procSqlDistinct(in=_dset,out=x0y2_2,var=&catvar);
	  %end;
	  %else %if &cont=0 %then %do;
	    /*ISOLATES CATVAR FORMAT LIBRARY*/
        %procFormat(library=&library,var=&catf,cntlout=x0y2_1);
	    /*ISOLATES NUMBERS IN CATVAR FORMAT*/
        %isolateFormat(in=x0y2_1,out=x0y2_2,var=&catvar);
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
	    %set(in=_ov3 (drop=count),out=_ov4);
      %end;
      %else %if &catsort=totfreq %then %do;
	    %procSortDescCount(in=_ov3,out=_ov4a);
	    %set(in=_ov4a (where=(&catvar~=&otherf)) _ov4a (where=(&catvar=&otherf)),out=_ov4);
	  %end;
	  /*REFORMATS LABEL VARIABLE AS TEXT TO INCLUDE TOTAL ROW*/
	  data x0y2_3 (drop=&catvar);
		length label $&catlen.;
		set _ov4;
		label=cats(put(&catvar,&catf..));
		label label="&catlab" tot="Total";
	  run;
	  /*ADDS TOTAL ROW*/
	  %set(in=x0y2_3 _tot,out=x0y2_4);
	  %if &trtvar= %then %do;
	    /*HEADER OR NOT*/
	    %if &header=y %then %do;
	      %set(in=_header x0y2_4,out=&tabout);
		%end;
		%else %if &header=n %then %do;
	      /*IF NOT SUMMARIES BY TREATMENT OUTPUT ABOVE DATASET*/
	      %set(in=x0y2_4,out=&tabout);
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
	      %set(in=_tab13,out=_tab14);
	    %end;
	    /*X1Y2=ONLY TREATMENTS WITH DATA, ALL CAT IN FORMAT*/
	    %if &catall=y %then %do;
	      /*DETERMINES WHETHER CHARACTER OR NUMERIC*/
	      %if &cont=1 %then %do;
            %procSqlDistinct(in=_dset,out=x1y2_2,var=&catvar);
	      %end;
	      %else %if &cont=0 %then %do;
	        /*ISOLATES CATVAR FORMAT LIBRARY*/
            %procFormat(library=&library,var=&catf,cntlout=x1y2_1);
	        /*ISOLATES NUMBERS IN CATVAR FORMAT*/
            %isolateFormat(in=x1y2_1,out=x1y2_2,var=&catvar);
		  %end;
	      /*MERGES WITH SUMMARY TABLE USING PROC SQL*/
		  %merge(in=x1y2_2 _tab13,out=_tab14,by=&catvar);
	    %end;
      %end;

      /*X2=ALL TREATMENTS IN FORMAT*/
      %else %if &trtall=y %then %do;
        %totrow(dset=_dset,trtvar=&trtvar,trtall=y,library=library,tout=_tot);
        /*X2Y1=ALL TREATMENTS IN FORMAT, ONLY CAT WITH DATA*/
	    %if &catall=n %then %do;
	      /*ISOLATES TRTVAR FORMAT LIBRARY*/
          %procFormat(library=&library,var=&trtf,cntlout=x2y1_1);
	      /*ISOLATES NUMBERS IN TRTVAR FORMAT*/
          %isolateFormat(in=x2y1_1,out=x2y1_2,var=&trtvar);
		  /*MERGES WITH SUMMARY TABLE*/
		  %procSortVar(in=_tab13,out=x2y1_3,var=&trtvar);
		  %merge(in=x2y1_2 x2y1_3,out=_tab14,by=&trtvar);
	    %end;
		/*X2Y2=ALL TREATMENTS IN FORMAT, ALL CAT IN FORMAT*/
	    %else %if &catall=y %then %do;
	      /*ISOLATES TRTVAR FORMAT LIBRARY*/
          %procFormat(library=&library,var=&trtf,cntlout=x2y2_2);
	      /*ISOLATES NUMBERS IN TRTVAR FORMAT*/
		  %isolateFormatBoth(in=x2y2_2,out=x2y2_4,fmtname=fmtnametrt,label=labeltrt,level=leveltrt);
	      /*DETERMINES WHETHER CHARACTER OR NUMERIC*/
	      %if &cont=1 %then %do;
            %procSqlDistinct(in=_dset,out=x2y2_3,var=&catvar);
	        /*MERGES CATVAR AND TRTVAR FORMAT NUMBERS TO CREATE ALL COMBINATIONS*/
			%mergeCom(in=x2y2_3 (keep=&catvar),out=x2y2_5,set=x2y2_4 (keep=leveltrt rename=(leveltrt=&trtvar)));
	      %end;
	      %else %if &cont=0 %then %do;
	        /*ISOLATES CATVAR FORMAT LIBRARY*/
            %procFormat(library=&library,var=&catf,cntlout=x2y2_1);
	        /*ISOLATES NUMBERS IN CATVAR FORMAT*/
		    %isolateFormatBoth(in=x2y2_1,out=x2y2_3,fmtname=fmtnamecv,label=labelcv,level=levelcv);
	        /*MERGES CATVAR AND TRTVAR FORMAT NUMBERS TO CREATE ALL COMBINATIONS*/
		    %mergeCom(in=x2y2_3 (keep=levelcv rename=(levelcv=&catvar)),out=x2y2_5,set=x2y2_4 (keep=leveltrt rename=(leveltrt=&trtvar)));
		  %end;
		  /*MERGES WITH SUMMARY TABLE*/
		  %merge(in=x2y2_5 _tab13,out=_tab14,by=&catvar &trtvar);
	    %end;
      %end;

      /*CREATES ZEROS FOR CELLS THAT ARE BLANK WHEN OPTIONS TRTALL=Y OR CATALL=Y*/
      /*SORTS DATASET BY CATVAR*/
	  %procSortVar(in=_tab14,out=_tab3,var=&catvar);
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
	  %procSortVar(in=_tab6,out=_tab7,var=&catvar &trtvar);
      data _tab8 (drop=count2);
	    set _tab7;
	    retain count3;
	    by &catvar;
	    if first.&catvar then count3=count2;
	    else count3=count3+count2;
      run;
	  %procSortVar(in=_tab8,out=_tab9,var=&catvar descending &trtvar);
      data _tab10 (drop=count3);
	    set _tab9;
	    retain count;
	    by &catvar;
	    if first.&catvar then count=count3;
	    else count=count;
      run;
	  %procSortVar(in=_tab10,out=_tab11,var=&catvar &trtvar);
      /*TRANSPOSES TO TABLE LAYOUT*/
      proc transpose data=_tab11 out=_tab12 (drop=_name_);
	    var freq;
	    by &catvar count;
	    id &trtvar;
	    idlabel &trtvar;
      run;
      /*MERGED WITH TOTAL COLUMN*/
	  %if &catall=n %then %do;
	    %mergeCont(in=_tab12 _ov2,out=_fin1 (drop=&catvar),by=&catvar);
	  %end;
	  %else %if &catall=y %then %do;
	    %mergeCont(in=_tab12 _ov3,out=_fin1 (drop=&catvar),by=&catvar);
	  %end;
	%end;
	/*CATSORT OPTION*/
    %if &catsort=catformat %then %do;
	  %set(in=_fin1 (drop=count),out=_fin2);
    %end;
    %else %if &catsort=totfreq %then %do;
	  %procSortDescCount(in=_fin1,out=_fin2a);
	  %set(in=_fin2a (where=(label~="Other")) _fin2a (where=(label="Other")),out=_fin2);
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
  %deleteWork(delete=_dset _header _setcall: x0y1: x0y2: x1y1: x1y2: x2y1: x2y2: _tab1-_tab15 _fin: _ov: _tot);
%end;
%mend;


*****************************END OF MACRO*********************************;
