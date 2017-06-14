
%macro totrow(dset=,trtvar=,trtall=,library=library,tout=,debug=n);
/*dset= 	input dataset;
  trtvar=	treatment variable, leave blank if do not want to include summaries
	 		by treatment variable (useful for open DMEC reports etc.)
  trtall=	y or n, depending on whether you want to output frequencies
			for all levels of the treatment variable, even if there is no
			data for that level (useful if frequency table is out of a subset
			of participants, and therefore there wont necessarily be data for
			both/all treatments/levels of the treatment variable)
  library=	library [DEFAULT] or anyother name given to the format library
  tout=		output dataset
  debug=    y or n, n is [DEFAULT], option to debug if necessary*/

/*CREATES COUNT AND PERCENTAGE FOR ALL DATA IN DATASET*/
proc sql noprint;
  select count(*) into :ntot
    from &dset;
quit;
data _mtot1 (drop=i);
  length tot $15;
  do i=1;
    tot=cat(cats(put(&ntot,4.))," (100%)");
    label="Total";
    output;
  end;
  label tot="Total";
run;

/*IF TREATMENT IS LEFT BLANK THEN D0 NOT WANT TREATMENT BY ARM, ONLY TOTAL*/
%if &trtvar= %then %do;
  data &tout;
    set _mtot1;
  run;
  /*DELETES ALL INTERMEDIATE DATASETS FOR THIS SECTION*/
  proc datasets lib=work nolist;
	delete _mtot:;
  run;
  quit;
  %goto exit;
%end;
/*IF TREATMENT IS NOT LEFT BLANK TREATMENT VARIABLE HAS BEEN SPECIFIED, TO BE SUMMARISED*/
%else %if &trtvar~= %then %do;
  data _mtotsetcall;
    set &dset;
	/*TREATMENT VARIABLE SETTINGS*/
	/*TIL=LENGTH OF TRTVAR FORMAT (I.E. IF FORMAT IS TRT12. THEN CIL WILL EQUAL 12)*/
    til=vformatw(&trtvar);
    /*LT=LENGTH OF NUMBER STRING (I.E. LENGTH OF 12 WOULD BE 2 AS TWO DIGITS, SO CAN BE
    REMOVED FROM END OF FORMAT NAME FOR LABELLING PURPOSED)*/
    lt=length(cats(til));
	/*CTL=LENGTH OF TRTVAR FORMAT (I.E. IF FORMAT IS TRT12., TFL=6)*/
    ctl=length(vformat(&trtvar));
	/*MACRO VARIABLE CREATION*/
    call symput("trtf", substr(vformat(&trtvar),1,ctl-(lt+1)));
  run;
  /*CREATE TOTAL COLUMN PERCENTAGES USING PROC SQL*/
  proc sql;
    create table _mtottrt1 as
    select &dset..&trtvar, count(*) as count,
           calculated count/subtotal as percent format=percent7.1
    from &dset,
      (select &trtvar, count(*) as subtotal from _dset
      group by &trtvar) as _dset2
      where &dset..&trtvar=_dset2.&trtvar
      group by &dset..&trtvar;
  quit;
  /*PUTS COUNTS AND PERCENTAGES INTO ONE VARIABLE*/
  data _mtottrt2 (keep=&trtvar freq);
	set _mtottrt1;
	length freq $15.;
	freq=cat(cats(put(count,4.))," (",cats(put(percent,percent7.1)),")");
  run;
  /*IF ONLY WANT TREATMENT VARIABLES THAT ARE IN THE DATA*/
  %if &trtall=n %then %do;
	/*KEEPS WIDE FORMAT OF TOTALS BY TREATMENT ONLY*/
	proc transpose data=_mtottrt2 out=_mtottrtn1 (drop=_name_);
	  var freq;
	  id &trtvar;
	  idlabel &trtvar;
	run;
	/*MERGES TOTAL ROW AND OVERALL COLUMN*/
	data &tout;
	  merge _mtottrtn1 _mtot1;
	  label="Total";
	  label tot="Total";
	run;
	%goto exit;
  %end;
  /*IF WANT ALL TREATMENTS IN FORMAT*/
  %else %if &trtall=y %then %do;
	/*ISOLATES TRTVAR FORMAT LIBRARY*/
	proc format library=&library cntlout=_mtottrty1 (keep=fmtname start label);
	  select &trtf;
	run;
	/*ISOLATES NUMBERS IN TRTVAR FORMAT*/
	data _mtottrty2 (keep=&trtvar);
	  set _mtottrty1;
	  &trtvar=start*1;
	  lab=lowcase(label);
	  if lab~="missing";
	run;
	/*MERGES WITH SUMMARY TABLE*/
	data _mtottrty3;
	  merge _mtottrt2 _mtottrty2;
	  by &trtvar;
	run;
    /*CREATES ZEROS FOR CELLS THAT ARE BLANK*/
    /*TRANSPOSES TO DISTINGUISH BLANK CELLS*/
	proc transpose data=_mtottrty3 out=_mtottrty4 prefix=&trtvar;
	  var &trtvar freq;
	  id &trtvar;
	run;
	proc transpose data=_mtottrty4 out=_mtottrty5;
	  var &trtvar:;
	run;
    /*ADDS ZEROS TO CELLS WHERE BLANK*/
	data _mtottrty6 (drop=count len trtlen);
	  set _mtottrty5;
	  count=0;
	  trtlen=length(&trtvar);
	  len=length(_name_);
	  if &trtvar="" then &trtvar=substr(_name_,trtlen+1,len);
	  if freq="" then freq=cat(cats(put(count,4.))," (0.0%)");
	  &trtvar=tranwrd(&trtvar,"_"," ");
	run;
    /*TRANSPOSES TO TABLE LAYOUT*/
	proc transpose data=_mtottrty6 out=_mtottrty7;
	  var freq;
	  id &trtvar;
	  idlabel &trtvar;
	run;
    /*MERGED WITH TOTAL COLUMN*/
	data &tout (drop=_name_);
	  merge _mtottrty7 _mtot1;
	  label="Total";
	  label tot="Total";
	run;
	%goto exit;
  %end;
%end;
%exit:
/*DEBUG YES OR NO, DELETES INTERMEDIATE DATASETS IF YES*/
%if &debug=n %then %do;
  proc datasets lib=work nolist;
    delete _mtot: _mtottrt: _mtotsetcall;
  run;
  quit;
%end;
%mend;

*****************************END OF MACRO*********************************;
