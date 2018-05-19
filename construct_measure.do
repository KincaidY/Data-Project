capture log close
cd "C:\Users\Kincaid Youman\Documents\School\STATAProjects\ECON 4440\PROJECT"
log using "Appendix II.A.log", replace
use onlinedata6.dta, replace

gen prob_better_p1 = prob_p1_k2 + prob_p1_k3 + prob_p1_k4 + prob_p1_k5
gen prob_better_p2 = prob_p2_k3 + prob_p2_k4 + prob_p2_k5
gen prob_better_p3 = prob_p3_k4 + prob_p3_k5
gen prob_better_p4 = prob_p4_k5
gen prob_better_p5 = 0

gen prob_better_and_p1 = frac_par_1 * prob_better_p1
gen prob_better_and_p2 = frac_par_2 * prob_better_p2
gen prob_better_and_p3 = frac_par_3 * prob_better_p3
gen prob_better_and_p4 = frac_par_4 * prob_better_p4
gen prob_better_and_p5 = frac_par_5 * prob_better_p5

gen prob_better_and_p5C = prob_better_and_p1 + prob_better_and_p2 ///
				+ prob_better_and_p3 + prob_better_and_p4


gen prob_better = prob_better_and_p5C/(frac_par_1 + frac_par_2 + ///
				frac_par_3 + frac_par_4)

				
save betterlifeCONDITIONAL.dta, replace

log close
