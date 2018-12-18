
*Program to test rules-based linking in SAS for the MI data
* extracts corresponding to 2015 and 2017 (birth years 1985 and 1986 only)
*
*Rule 1: Exact match on birth year, street number, zip, gender
         Levenshtein fuzzy match on lname, fname, mname, street
*Rule 2: Exact match on birth year, zip, gender
         Levenshtein fuzzy match on lname fname
*Rule 3: Exact match on birth year, street number, zip, gender
*        Levenshtein fuzzy match on fname, street
*Rule 4: Exact match on Birth year, gender
*        Levenshtein fuzzy match on fname, mname, lname;
options macrogen nomprint;

libname base "/accounts/cpl/data";
libname here ".";
***START OF MACRO TO RUN THE FULL RULES-BASED MERGE;
%macro fullrun (filename=, outfile=);
 title "Rules-based merge for <&filename.>";
* Start timer - very beginning;
  %let _timer_start = %sysfunc(datetime());

*Read in CSVs;
 proc import datafile="2015_&filename..csv"
      out=samp2015
	  dbms=csv
	  replace;
   getnames=yes;
   run;
 proc import datafile="2017_&filename..csv"
      out=samp2017
	  dbms=csv
	  replace;
   getnames=yes;
   run;
/*
* This converts to current version of SAS (with some possible delay).
* By using a generic name for the data set created, we ensure that 
* we need to change only these lines to use a different sized sample;
data samp2015;
 set base.a2015_n&N.;
 run;
*proc contents;
data samp2017;
 set base.a2017_n&N.;
 run;
*proc contents;
*/
 
*Rename variables;
data samp2015;
 set samp2015;
 rename byear=byear_15
        city = city_15
        countycode=countycode_15
        fname=fname_15
        gender =gender_15
        housenum =housenum_15
        housesuff =housesuff_15
        lname=lname_15
        mname =mname_15
        predirection =predirection_15
        regdate =regdate_15
        state =state_15
        street =street_15
        streetnum =streetnum_15
        streettype =streettype_15
        suffix =suffix_15
        truematch =truematch_15
        voterid =voterid_15
        zip =zip_15
        ;
 run;
data samp2017;
 set samp2017;
 rename byear=byear_17
        city = city_17
        countycode=countycode_17
        fname=fname_17
        gender =gender_17
        housenum =housenum_17
        housesuff =housesuff_17
        lname=lname_17
        mname =mname_17
        predirection =predirection_17
        regdate =regdate_17
        state =state_17
        street =street_17
        streetnum =streetnum_17
        streettype =streettype_17
        suffix =suffix_17
        truematch =truematch_17
        voterid =voterid_17
        zip =zip_17
        ;
 run;

* Start timer - end of pre-processing;
  %let _timer_preprocess = %sysfunc(datetime());

*Make a dataset of possible pairs;
data joined;
 set samp2015;
 do i=1 to NN;
   set samp2017 point=i nobs=NN;
   quit=0;
   *Make exact match scores;
    match_byear=(byear_15=byear_17);
    match_streetnum=(streetnum_15=streetnum_17);
    match_zip=(zip_15=zip_17);
    match_gender=(gender_15=gender_17);
   *Make preliminary rules, and keep only those that pass at least 1;
    type1=1;
    if match_byear=0 | match_streetnum=0 | match_zip=0 | match_gender=0 then type1=0;
    type2=1;
    if match_byear=0 | match_zip=0 | match_gender=0 then type2=0;
    type3=type1;
    type4=1;
    if match_byear=0 | match_gender=0 then type4=0;
    *If we already fail all the conditions, drop this pair;
     if type1=0 & type2=0 & type3=0 & type4=0 then quit=1;
     else do;
      *Now do fuzzy match scores on fname, lname, mname, street, only for those that we still have;
      *Use Levenshtein edit distance divided by length of longest string;
       lmatch_fname=complev(fname_15, fname_17, 8, "L")/max(length(fname_15), length(fname_17));
      *All four rules require match on fname;
       if lmatch_fname>0.25 then quit=2;
       else do;
         lmatch_lname=complev(lname_15, lname_17, 8, "L")/max(length(lname_15), length(lname_17));
         lmatch_mname=complev(mname_15, mname_17, 8, "L")/max(length(mname_15), length(mname_17));
         lmatch_street=complev(street_15, street_17, 8, "L")/max(length(street_15), length(street_17));
         if type1=1 & (lmatch_lname>0.25 | lmatch_fname>0.25 | lmatch_mname>0.25 | lmatch_street>0.25) then type1=0;
         if type2=1 & (lmatch_lname>0.25 | lmatch_fname>0.25) then type2=0;
         if type3=1 & (lmatch_fname>0.25 | lmatch_street>0.25) then type3=0;
         if type4=1 & (lmatch_lname>0.25 | lmatch_fname>0.25 | lmatch_mname>0.25) then type4=0;
         *Check the conditions again, and drop the pair if we fail all of them;
          if type1=0 & type2=0 & type3=0 & type4=0 then quit=3;
       end;
     end;
   *We have a match of some type. Assign the best score;
    score=5-max(4*type1, 3*type2, 2*type3, 1*type4);
    if quit=0 & score<5 then output;
    keep score voterid_15 voterid_17;
 end;
run; 
* Start timer - end of initial join;
  %let _timer_join1 = %sysfunc(datetime());

*If idA has any score=1, then drop any score=2,3,4s;
proc sort data=joined;
  by voterid_15 score;
  run;
data trim1A (drop=lowscore);
  set joined;
  by voterid_15;
  retain lowscore;
  if first.voterid_15 then lowscore=score;
  if lowscore=1 then do;
    if score=lowscore;
  end;
  run;
*Now if idB has any score=1, then drop any score=2,3,4s;
proc sort data=trim1A;
  by voterid_17 score;
  run;
data trim1 (drop=lowscore);
  set trim1A;
  by voterid_17;
  retain lowscore;
  if first.voterid_17 then lowscore=score;
  if lowscore=1 then do;
    if score=lowscore;
  end;
  run;
*Now repeat for score=2: If idA has any score=2, drop any score=3,4s;
proc sort data=trim1;
  by voterid_15 score;
  run;
data trim2A (drop=lowscore);
  set trim1;
  by voterid_15;
  retain lowscore;
  if first.voterid_15 then lowscore=score;
  if lowscore=2 then do;
    if score=lowscore;
  end;
  run;
*Now if idB has any score=2, then drop any score=3,4s;
proc sort data=trim2A;
  by voterid_17 score;
  run;
data trim2 (drop=lowscore);
  set trim2A;
  by voterid_17;
  retain lowscore;
  if first.voterid_17 then lowscore=score;
  if lowscore=2 then do;
    if score=lowscore;
  end;
  run;
*Now repeat for score=3: If idA has any score=3, drop any score=4s;
proc sort data=trim2;
  by voterid_15 score;
  run;
data trim3A (drop=lowscore);
  set trim2;
  by voterid_15;
  retain lowscore;
  if first.voterid_15 then lowscore=score;
  if lowscore=3 then do;
    if score=lowscore;
  end;
  run;
*Now if idB has any score=3, then drop any score=4s;
proc sort data=trim3A;
  by voterid_17 score;
  run;
data &outfile. (drop=lowscore);
  set trim3A;
  by voterid_17;
  retain lowscore;
  if first.voterid_17 then lowscore=score;
  if lowscore=3 then do;
    if score=lowscore;
  end;
  run;
* Start timer - End of join;
  %let _timer_join = %sysfunc(datetime());
      
*Output timing;
 data timers_&filename.;
   filename="&filename.";
   dur_pre   = &_timer_preprocess - &_timer_start;
   dur_join  = &_timer_join1 - &_timer_preprocess;
   dur_clean = &_timer_join - &_timer_join1;
   dur_tot   = &_timer_join - &_timer_start;
  put 30*'-' / 
      'FILENAME = &filename.' / 
      ' DURATIONS:' /
      '   PREPROCESSING: ' dur_pre   time13.2 /
      '   JOINING:       ' dur_join  time13.2 / 
      '   CLEANING JOIN: ' dur_clean time13.2 / 
      '   TOTAL:         ' dur_tot   time13.2 /
      30*'-';
run;   
proc print data=timers_&filename.;   
proc freq data=&outfile.;
 tables score;
 run;
proc export data=&outfile. 
            outfile="&outfile..csv"
            dbms=csv
            replace;
 run;
%mend fullrun;
**END OF MACRO TO RUN THE FULL RULES-BASED MERGE;
%fullrun(filename=byear_10pct, outfile=rules2_MI_10pct);
%fullrun(filename=byear, outfile=rules2_MI_full);

data timers;
 set timers_byear timers_byear_10pct;
 run;
proc print;
run;
 
   



