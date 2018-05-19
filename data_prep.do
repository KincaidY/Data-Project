///Prepping Data
use onlinedata5.dta, replace
keep n_ige_rank_8082 cz s_rank_8082
rename cz czone
joinby czone using workfile9014wwd.dta
keep cz t2 reg_midatl reg_encen reg_wncen reg_satl reg_escen reg_wscen ///
			reg_mount reg_pacif n_ige_rank_8082 s_rank_8082
drop if t2 == 0
rename czone cz
save regions.dta, replace

use onlinedata8.dta, replace

keep cz czname stateabbrv pop2000 intersects_msa gini cs_race_bla /// 
			incgrowth0010

joinby cz using betterlifeCONDITIONAL.dta
*inserting Census division values for HI and AK
joinby cz using regions.dta, unmatched(master)
gen reg_notcontig = 0
destring(pop2000), replace ignore(",")
replace reg_notcontig = 1 if stateabbrv == "HI" | stateabbrv == "AK"

replace reg_midatl = 0 if reg_notcontig == 1
replace reg_encen = 0 if reg_notcontig == 1
replace reg_wncen = 0 if reg_notcontig == 1
replace reg_satl = 0 if reg_notcontig == 1
replace reg_escen = 0 if reg_notcontig == 1
replace reg_wscen = 0 if reg_notcontig == 1
replace reg_mount = 0 if reg_notcontig == 1
replace reg_pacif = 0 if reg_notcontig == 1
drop _merge

gen gini2 = gini^2
gen gini3 = gini^3
gen gini4 = gini^4


label define urbanlab 0 "Nonurban" 1 "Urban" 
label values intersects_msa urbanlab

*creating dummies for larger census regions
gen region = ""
replace region = "Northeast" if (reg_midatl == 1) | (reg_midatl == 0 ///
		& reg_encen == 0 & reg_wncen == 0 & reg_satl == 0 & reg_escen == 0 ///
		& reg_wscen == 0 & reg_mount == 0 & reg_pacif == 0 & reg_notcontig == 0)
replace region = "Midwest" if reg_encen == 1 | reg_wncen ==1
replace region = "South" if reg_satl == 1 | reg_escen == 1 | reg_wscen ==1
replace region = "West" if reg_mount == 1 | reg_pacif ==1 | reg_notcontig == 1
encode region, gen(regionNums)

save workfile.dta, replace

*weighted averages
egen total_pop2000 = total(pop2000)
gen pop_share = pop2000/total_pop2000

bysort regionNums: egen total_pop2000_region = total(pop2000)
gen pop_share_region = pop2000 / total_pop2000_region

bysort intersects_msa: egen total_pop2000_urban = total(pop2000)
gen pop_share_urban= pop2000 / total_pop2000_urban

gen prob_better_weighted = prob_better * pop_share 
gen prob_better_weighted_region = prob_better * pop_share_region
gen prob_better_weighted_urban = prob_better * pop_share_urban

gen gini_weighted = gini * pop_share 
gen gini_weighted_region = gini * pop_share_region
gen gini_weighted_urban = gini * pop_share_urban


save workfile.dta, replace
