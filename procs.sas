

/*creates header*/
%macro header(out=,lab=);
data &out;
  length label $255.;
  label="^S={font_weight=bold}&lab";
run;
%mend header;

/*create dataset with format for specified variable*/
%macro procFormat(library=,var=,cntlout=);
proc format library=&library cntlout=&cntlout (keep=fmtname start label);
  select &var;
run;
%mend;

/*isolate the format and the variable*/
%macro isolateFormat(in=,out=,var=);
data &out (keep=&catvar);
  set &in;
  &catvar=input(cats(start),4.);
  lab=lowcase(label);
  if lab~="missing";
run;
%mend;

/*isolate the format and the variable for both cat and trt*/
%macro isolateFormatBoth(in=,out=,fmtname=,label=,level=);
data &out (keep=&fmtname &label &level);
  set &in;
  &fmtname=fmtname;
  &label=label;
  &level=start*1;
  lab=lowcase(label);
  if lab~="missing";
run;
%mend;

/*proc sql distinct*/
%macro procSqlDistinct(in=,out=,var=);
proc sql;
  create table &out as 
    select distinct &var
    from &in
  group by &var
  order by &var;
quit;
%mend procSqlDistinct;

/*sort by descending count*/
%macro procSortDescCount(in=,out=);
proc sort data=&in out=&out (drop=count);
  by descending count;
run;
%mend procSortDescCount;

/*sort by variables*/
%macro procSortVar(in=,out=,var=);
proc sort data=&in out=&out;
  by &var;
run;
%mend procSortVar;

/*sets datasets together*/
%macro set(in=,out=);
data &out;
  set &in;
run;
%mend set;

/*merges datasets together*/
%macro merge(in=,out=,by=);
data &out;
  merge &in;
  by &by;
run;
%mend;

/*merges and calculates combinations*/
%macro mergeCom(in=,out=,set=);
data &out;
  set &in;
  do i=1 to n;
    set &set point=i nobs=n;
    output;
  end;
run;
%mend mergeCom;

/*merge and adds lengths to categorical variable*/
%macro mergeCont(in=,out=,by=);
data &out;
  merge &in;
  by &by;
  if &cont=1 then label=putn(&catvar,&cflen);
  else if &cont=0 then label=put(&catvar,&catf..);
run;
%mend mergeCont;

/*delete work datasets*/
%macro deleteWork(delete=);
proc datasets lib=work nolist;
  delete &delete;
run; 
quit;
%mend deleteWork;
