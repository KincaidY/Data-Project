# Data-Project

Mobility and Inequality.docx is the final product

construct_measure.do is the calculation of the main measure in the paper, and uses data from:
  http://www.equality-of-http://www.equality-of-opportunity.org/data/descriptive/table6/onlinedata6.dta

data_prep.do creates the data file workfile.dta using:\n
  \thttp://www.equality-of-opportunity.org/data/descriptive/table5/onlinedata5.dta
  \thttp://www.equality-of-opportunity.org/data/descriptive/table8/onlinedata8.dta
  and workfile9014wwd.dta from:
  http://ddorn.net/data/ADH-MarriageMarket-FileArchive.zip
  
main_analysis.do is the core data analysis file, which runs using workfile.dta

tableV_pvalues.xlsx calculates p-values for Table V

usmaptile_v064.ado defines a command necessary for the maps I create, and is provided by Chetty et al. (2014a) (see Mobility and Inequality.docx for full references)


see http://www.equality-of-opportunity.org/ for related data, papers, and code
