capture log close

cd "C:\Users\Kincaid Youman\Documents\School\STATAProjects\ECON 4440\PROJECT"
log using Appendix.II.B.log, replace


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

///Outliers (Figure III)
ssc install mahapick
mahascore prob_better gini, gen(mahadist) refmeans compute_invcovarmat
qchi mahadist, df(2) ///
			title("Mahalanobis' Distance Quantile-Quantile Plot") ///
			ytitle("Mahalanobis' Distance")
graph export Outliers.png, replace
extremes mahadist czname stateabbrv
gen extreme = 0
replace extreme = 1 if mahadist > 20
tabstat extreme, stats(sum)
tab prob_better if extreme == 1, sum(gini)


///Info on P(B) and Gini (Tables I & II)
*formatting of tables done in excel
foreach var of varlist prob_better gini {
sum `var'
tabstat `var'_weighted, stats(sum)
tabstat `var', by(regionNums) stats(mean)
tabstat `var'_weighted_region, by(regionNums) stats(sum)
tabstat `var', by(intersects_msa) stats(mean)
tabstat `var'_weighted_urban, by(intersects_msa) stats(sum)
}


foreach var of varlist prob_better_p1 prob_better_p2 prob_better_p3 ///
				prob_better_p4 prob_better_p5 {
gen `var'_weighted = `var'*pop_share
tabstat `var', stats(mean)
tabstat `var'_weighted, stats(sum)
}

extremes prob_better czname stateabbrv
extremes gini czname stateabbrv

tabstat gini, stats(p10 p25 p50 p75 p90)


			
///Base Regressions (Table III)
*I cluster standard error by state for all regressions
scatter prob_better gini

reg prob_better gini, cluster(stateabbrv)
est store linear
predict prob_better_hat_linear
reg prob_better gini gini2, cluster(stateabbrv)
est store quadratic
reg prob_better gini gini2 if extreme == 0, cluster(stateabbrv)
est store quadratic_nooutliers
predict prob_better_hat
reg prob_better gini gini2 gini3, cluster(stateabbrv)
predict prob_better_hat_withoutliers
est store cubic
reg prob_better gini gini2 gini3 if extreme == 0, cluster(stateabbrv)
est store cubic_nooutliers
reg prob_better gini gini2 gini3 gini4, cluster(stateabbrv)
est store quartic

*outliers do not alter linear model much:
reg prob_better gini if extreme == 0, cluster(stateabbrv)

esttab linear quadratic cubic quadratic_nooutliers cubic_nooutliers using ///
				"Basic.csv",se r2 mtitle replace

///Base Graph (Figure IV)
sort gini
twoway (scatter prob_better gini if extreme == 0) ///
				(scatter prob_better gini if extreme == 1, color("lavender")) ///
				(line prob_better_hat_linear gini) ///
				(line prob_better_hat_withoutliers gini) ///
				(line prob_better_hat gini if extreme ==0, color("cranberry")), ///
				legend(label(1 "Observed") label(2 "Observed Outliers") ///
				label(3 "Linear") label(4 "Inc. Outliers") ///
				label(5 "Exc. Outliers")) xtitle("Gini Coefficient") ///
				ytitle("P(B)") title("P(B) vs. Gini Coefficent Across CZs") ///
				saving("Basic", replace)
graph export Basic.png, replace	
sort cz

*quadratic exc. outliers minimized at 0.497, what percentile is this at?
gen decreasing = 0
replace decreasing = 1 if gini < 0.497
tabstat decreasing, stats(sum)
di 646 / 729




///Urban Graph (Figure VI)
reg prob_better gini i.intersects_msa c.gini#i.intersects_msa, cluster(stateabbrv)
predict prob_better_hat_urban
reg prob_better gini gini2 i.intersects_msa c.gini#i.intersects_msa ///
				c.gini2#i.intersects_msa, cluster(stateabbrv)
sort gini
twoway (scatter prob_better gini, by(intersects_msa, note("") /// 
				title("P(B) vs. Gini Coefficent for Urban and Nonurban Areas"))) ///
				(line prob_better_hat_urban gini,connect(ascending)), ///
				legend(label(1 "Observed") label(2 "Fitted Values")) ///
				xtitle("Gini Coefficient by CZ") ///
				ytitle("P(B)") ///
				saving("UrbanGraph", replace)
graph export Urban.png, replace
sort cz


///Region Graph (Figure V)
reg prob_better gini i.regionNums c.gini#i.regionNums, cluster(stateabbrv)
predict prob_better_hat_region
reg prob_better gini gini2 i.regionNums c.gini#i.regionNums ///
				c.gini2#i.regionNums if gini < 0.68, cluster(stateabbrv)
predict prob_better_hat_regionquad
sort gini
twoway (scatter prob_better gini, by(region, note("") ///
				title("P(B) vs. Gini Coefficent by Region"))) ///
				(line prob_better_hat_region gini) ///
				(line prob_better_hat_regionquad gini if gini < 0.68 & ///
				(regionNums == 1 | regionNums == 3)), ///
				legend(label(1 "Observed") label(2 "Linear") ///
				label(3 "Quadratic")) xtitle("Gini Coefficient by CZ") ///
				ytitle("P(B)") ///
				saving("RegionsGraph", replace)
graph export Regions.png, replace
sort cz

tab region
*quantifying coefficient in midwest
tabstat gini if regionNums == 1, stats(p10 p25 p75 p90)
di (.38058-.3127)*(-0.928)
di (.41065-.29141)*(-0.928)
*checking quadratic significance
reg prob_better gini gini2 if regionNums == 1 & gini < 0.68, cluster(stateabbrv)
reg prob_better gini gini2 if regionNums == 2 & gini < 0.68, cluster(stateabbrv)
reg prob_better gini gini2 if regionNums == 3 & gini < 0.68, cluster(stateabbrv)
reg prob_better gini gini2 if regionNums == 4 & gini < 0.68, cluster(stateabbrv)



///Geographic Table (Table IV)
reg prob_better gini, cluster(stateabbrv)
est store basic
reg prob_better gini if intersects_msa == 1, cluster(stateabbrv)
est store urban
reg prob_better gini i.regionNums c.gini#i.regionNums,cluster(stateabbrv)
est store region
reg prob_better gini if intersects_msa == 0,cluster(stateabbrv)
est store nonurban
reg prob_better gini gini2 if intersects_msa == 0, cluster(stateabbrv)
est store nonurban_quadratic

esttab basic region urban nonurban nonurban_quadratic using "Geographic.csv", ///
					se r2 mtitle replace

*checking if changes much with outliers
*here, outliers were identified visually as they are much more obvious than
*for the US as a whole
reg prob_better gini if gini < 0.7, cluster(stateabbrv)
est store basic
reg prob_better gini if intersects_msa == 1 & gini < 0.7, cluster(stateabbrv)
est store urban
reg prob_better gini i.regionNums c.gini#i.regionNums if gini < 0.68, ///
					cluster(stateabbrv)
est store region
reg prob_better gini if intersects_msa == 0 & gini < 0.7,cluster(stateabbrv)
est store nonurban
reg prob_better gini gini2 if intersects_msa == 0 & gini < 0.7, ///
					cluster(stateabbrv)
est store nonurban_quadratic

esttab basic region urban nonurban nonurban_quadratic ///
					using "GeographicNoOutliers.csv",se r2 mtitle replace

///Urban and Nonurban Summary Scatter (FIGURE VII)

sort gini
twoway (scatter prob_better gini if intersects_msa == 1, ///
				color("navy") msymbol("+")) ///
				(scatter prob_better gini if intersects_msa == 0, ///
				color("cranberry") msymbol("X")) ///
				(line prob_better_hat gini if extreme == 0, color("black")), ///
				legend(label(1 "Urban") label(2 "Nonurban") ///
				label(3 "Exc. Outliers")) ///
				title("P(B) vs. Gini Coefficient With Urban/Nonurban Scatter") ///
				ytitle("P(B)") xtitle("Gini Coefficient by CZ") ///
				saving("", replace)
graph export Regions.png, replace
sort cz

///Creating Maps (Figures I & II)
*code in this section is modified from Chetty et al. (2014a)
ssc install spmap
ssc install shp2dta
ssc install mif2dta
run usmaptile_v064.ado

usmaptile prob_better, shapefolder("C:\Users\Kincaid Youman\Documents\School\STATAProjects\ECON 4440\PROJECT\Replicate\replicate") /// 
				geo(cz) equ rev legdecimals(1) ndfcolor(gs14)
graph export "MapP(B).png", replace
usmaptile gini, shapefolder("C:\Users\Kincaid Youman\Documents\School\STATAProjects\ECON 4440\PROJECT\Replicate\replicate") /// 
				geo(cz) equ rev legdecimals(1) ndfcolor(gs14)
graph export MapGini.png, replace



///Recreating Chetty et al. (2014a) Online Appendix Table VII (Table V)
*code in this section is modified from Chetty et al. (2014a)
*p-values are found in excel in Appendix III
*formatting of table done in excel
joinby cz using analysis.dta

* Matrix to hold output
matrix def beta = J(1, 5, .)
matrix def se = J(1, 5, .)
mat rownames beta = ///
  gini
mat rownames se = ///
  gini


local row = 1
foreach var of varlist gini{
  local col = 1
  reg prob_better `var'
  su prob_better if e(sample)
  gen eb1 = (prob_better-r(mean))/r(sd) if e(sample)
  su `var' if e(sample)
  gen v1 = (`var'-r(mean))/r(sd) if e(sample)
  reg eb1 v1, cluster(stateabbrv)
  matrix def beta[`row', `col'] = round(_b[v1], .001)
  matrix def se[`row', `col'] = round(_se[v1], .001)
  corr prob_better `var'
  drop eb1 v1
  local col = 2
  reg prob_better `var'
  su prob_better if e(sample)
  gen eb2 = (prob_better-r(mean))/r(sd) if e(sample)
  su `var' if e(sample)
  gen v2 = (`var'-r(mean))/r(sd) if e(sample)
  areg eb2 v2, cluster(stateabbrv) absorb(stateabbrv)
  matrix def beta[`row', `col'] = round(_b[v2], .001)
  matrix def se[`row', `col'] = round(_se[v2], .001)
  drop eb2 v2
  local col = 3
  reg prob_better `var' [w=pop2000]
  su prob_better if e(sample) [w=pop2000]
  gen eb3 = (prob_better-r(mean))/r(sd) if e(sample)
  su `var' if e(sample) [w=pop2000]
  gen v3 = (`var'-r(mean))/r(sd) if e(sample)
  reg eb3 v3 [w=pop2000], cluster(stateabbrv)
  matrix def beta[`row', `col'] = round(_b[v3], .001)
  matrix def se[`row', `col'] = round(_se[v3], .001)
  corr prob_better `var' [w=pop2000]
  drop eb3 v3
  local col = 4
  reg prob_better `var' if intersects_msa
  su prob_better if intersects_msa & e(sample)
  gen eb4 = (prob_better-r(mean))/r(sd) if intersects_msa & e(sample)
  su `var' if intersects_msa & e(sample)
  gen v4 = (`var'-r(mean))/r(sd) if e(sample)
  reg eb4 v4 if intersects_msa, cluster(stateabbrv)
  matrix def beta[`row', `col'] = round(_b[v4], .001)
  matrix def se[`row', `col'] = round(_se[v4], .001)
  corr prob_better `var' if intersects_msa
  drop eb4 v4
  local col = 5
  * First residualize on race and income growth and then normalize
  * Residualize prob_better
  reg prob_better `var'
  gen sample = (e(sample))
  reg prob_better cs_race_bla incgrowth0010 if sample
  predict prob_better_r if sample, res
  * Residualize RHS
  reg `var' cs_race_bla incgrowth0010 if sample
  predict `var'_r if sample, res
  * Normalize
  reg prob_better_r `var'_r
  su prob_better_r if e(sample)
  gen eb5 = (prob_better_r-r(mean))/r(sd) if e(sample)
  su `var'_r if e(sample)
  gen v5 = (`var'_r-r(mean))/r(sd) if e(sample)
  * Get correlation
  reg eb5 v5 if sample, cluster(stateabbrv)
  matrix def beta[`row', `col'] = round(_b[v5], .001)
  matrix def se[`row', `col'] = round(_se[v5], .001)
  drop prob_better_r eb5 v5 sample
}


* Print betas
mat list beta
* Print SEs
mat list se

log close
