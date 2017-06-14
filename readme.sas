
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
