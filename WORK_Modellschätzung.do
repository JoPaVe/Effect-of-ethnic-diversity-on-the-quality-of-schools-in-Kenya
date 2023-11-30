/*
Schätze Regressionen (1) und (2)
*/

cd $data_path

/// **** Grundmodell - Schätzung + Graphische Darstellung ****
* Benötigtes Package: Outreg2
ssc install outreg2

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear

* Anpassen Label
label variable urbanrt "Urbanisierungsrate"	
label variable hv244 "Besitz Agrarland"	
label variable sekundaerschulen "Sekundaerschulen"
label variable elfcounty_v131 "ELF (Ethnie)"

	
local baselinecontrols urbanrt hv244 sekundaerschulen i.v013 i.v131 i.v130 // Definiere Baseline Kontrollvariablen

quietly svy, subpop(subgroupdrop): reg v133 elfcounty_v131
estimates store reg1
quietly svy, subpop(subgroupdrop): reg v133 elfcounty_v131  `baselinecontrols'
estimates store reg2
quietly svy, subpop(subgroupdrop): ologit v106 elfcounty_v131
estimates store reg3
quietly svy, subpop(subgroupdrop): ologit v106 elfcounty_v131  `baselinecontrols'
estimates store reg4
quietly svy, subpop(subgroupdrop): logit v155_bin elfcounty_v131
estimates store reg5
quietly svy, subpop(subgroupdrop): logit v155_bin elfcounty_v131 `baselinecontrols'
estimates store reg6
quietly lincom elfcounty_v131 - 0, or //Angabe von Odds Ratio
display r(estimate)
quietly svy, subpop(subgroupdrop): logit v149_bin elfcounty_v131
estimates store reg7
quietly svy, subpop(subgroupdrop): logit v149_bin elfcounty_v131 `baselinecontrols'
estimates store reg8	
	
outreg2 [reg1] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) replace ctitle(Schuljahre) keep(elfcounty_v131) nocons  word label
outreg2 [reg2] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) append keep(elfcounty_v131 urbanrt hv244 sekundaerschulen v012) nocons  word label addtext(Indikatorvariablen, X)
outreg2 [reg3] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) append ctitle(Bildungsstufe) keep(elfcounty_v131) nocons  word label 
outreg2 [reg4] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) append keep(elfcounty_v131 urbanrt hv244 sekundaerschulen v012) nocons  word label addtext(Indikatorvariablen, X) 
outreg2 [reg5] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) append ctitle(Alphabetisierung) keep(elfcounty_v131) nocons title(Regressionsergebnisse: Individuelle Schulausgangsvariablen auf ethnischer Diversität) word label 
outreg2 [reg6] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) append keep(elfcounty_v131 urbanrt hv244 sekundaerschulen v012) nocons  word label addtext(Indikatorvariablen, X)
outreg2 [reg7] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) append ctitle(Bildungsabschluss) keep(elfcounty_v131) nocons title(Regressionsergebnisse: Individuelle Schulausgangsvariablen auf ethnischer Diversität) word label 
outreg2 [reg8] using "${data_path}\output_regressions\Tabelle5.doc", dec(2) append keep(elfcounty_v131 urbanrt hv244 sekundaerschulen v012) nocons word label addtext(Indikatorvariablen, X)

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
local baselinecontrols urbanrt hv244 sekundaerschulen i.v013 i.v131 i.v130

svy, subpop(subgroupdrop): reg v133 c.elfcounty_v131##i.exptofpe `baselinecontrols' // Schätze Modell 2
margins exptofpe, dydx(elfcounty_v131) vce(unconditional) subpop(subgroupdrop) //Margins für veränderte FPE-Exposition
marginsplot, ytitle("Punktschätzung") xtitle("FPE-Exposition") scheme(s1manual) yline(-1 1, lstyle(grid)) yline(0) title("")
graph export "${data_path}\output_graphs\Abbildung2.png", replace
		
	

/// **** Robustheit - Schätzung ****
* Robustheitsanalysen - Unterschiedliche Schätzungen mit slnative / controls

*1. Schätzung mit slnative 

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_slnativeEstimationRecode", clear
local baselinecontrols urbanrt hv244 sekundaerschulen i.v013 i.v131 i.v130

quietly svy, subpop(subgroupdrop): reg v133 elfcounty_slnative `baselinecontrols'
estimates store reg1_1
quietly svy, subpop(subgroupdrop): ologit v106 elfcounty_slnative  `baselinecontrols'
estimates store reg1_2
svy, subpop(subgroupdrop): logit v155_bin elfcounty_slnative `baselinecontrols'
estimates store reg1_3
quietly svy, subpop(subgroupdrop): logit v149_bin elfcounty_slnative `baselinecontrols' 
estimates store reg1_4
outreg2 [reg1_1 reg1_2 reg1_3 reg1_4] using "${data_path}\output_regressions\Tabelle6", replace keep(elfcounty_slnative) label nocons noobs nor2 excel ctitle(ELF (Muttersprache))

* 2. Verschiedene Variablen der Kontrollvariablen ersetzen
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_slnativeEstimationRecode", clear
local control_1 "popdensity_2010 hv244 sekundaerschulen i.v013 i.v131 i.v130"
local labelcontrol_1 "Bevoelkerungsdichte"	 
local control_2 "urbanrt hv245 sekundaerschulen i.v013 i.v131 i.v130"
local labelcontrol_2 "Hektar Agrarland"	
local control_3 "urbanrt cropland sekundaerschulen i.v013 i.v131 i.v130"
local labelcontrol_3 "Anteil Agrarland"	
local control_4 "urbanrt hv244 v149_sekundaer_perc i.v013 i.v131 i.v130"
local labelcontrol_4 "Sekundaerschueler"	
local control_5 "urbanrt hv244 sekundaerschulen i.v013 i.v131 i.v130 v190"
local labelcontrol_5 "Wealth Index"	


forvalues i=1/5 {
	use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
	
	quietly svy, subpop(subgroupdrop): reg v133 elfcounty_v131 `control_`i''
	estimates store reg2_1_`i'
	quietly svy, subpop(subgroupdrop): ologit v106 elfcounty_v131  `control_`i''
	estimates store reg2_2_`i'
	quietly svy, subpop(subgroupdrop): logit v155_bin elfcounty_v131 `control_`i''
	estimates store reg2_3_`i'
	quietly svy, subpop(subgroupdrop): logit v149_bin elfcounty_v131 `control_`i''
	estimates store reg2_4_`i'	
	

	outreg2 [reg2_1_`i' reg2_2_`i' reg2_3_`i' reg2_4_`i'] using "${data_path}\output_regressions\Tabelle6", append keep(elfcounty_v131) label nocons noobs nor2 excel ctitle(`labelcontrol_`i'')
	
}

* 4.1 Drop Regionen Küste und Ostkenia und Zentralkenia

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
local baselinecontrols urbanrt hv244 sekundaerschulen i.v013 i.v131 i.v130

tempvar subgroupdropregion
gen `subgroupdropregion' = 1
replace `subgroupdropregion' = 0 if v101 == 1 | subgroupdrop == 0 // Exkludiere Küste == 1

quietly svy, subpop(`subgroupdropregion'): reg v133 elfcounty_v131 `baselinecontrols'
estimates store reg3_1
quietly svy, subpop(`subgroupdropregion'): ologit v106 elfcounty_v131  `baselinecontrols'
estimates store reg3_2
quietly svy, subpop(`subgroupdropregion'): logit v155_bin elfcounty_v131 `baselinecontrols'
estimates store reg3_3
quietly svy, subpop(`subgroupdropregion'): logit v149_bin elfcounty_v131 `baselinecontrols' 
estimates store reg3_4

outreg2 [reg3_1 reg3_2 reg3_3 reg3_4] using "${data_path}\output_regressions\Tabelle6", append keep(elfcounty_v131) label nocons noobs nor2 excel ctitle(Ohne Kueste)

tempvar subgroupdropregion
gen `subgroupdropregion' = 1
replace `subgroupdropregion' = 0 if v101 == 3 | subgroupdrop == 0 // Exkludiere Ostkenia == 3

quietly svy, subpop(`subgroupdropregion'): reg v133 elfcounty_v131 `baselinecontrols'
estimates store reg3_5
quietly svy, subpop(`subgroupdropregion'): ologit v106 elfcounty_v131  `baselinecontrols'
estimates store reg3_6
quietly svy, subpop(`subgroupdropregion'): logit v155_bin elfcounty_v131 `baselinecontrols'
estimates store reg3_7
quietly svy, subpop(`subgroupdropregion'): logit v149_bin elfcounty_v131 `baselinecontrols' 
estimates store reg3_8

outreg2 [reg3_5 reg3_6 reg3_7 reg3_8] using "${data_path}\output_regressions\Tabelle6", append keep(elfcounty_v131) label nocons noobs nor2 excel ctitle(Ohne Ostkenia)

tempvar subgroupdropregion
gen `subgroupdropregion' = 1
replace `subgroupdropregion' = 0 if v101 == 4 | subgroupdrop == 0 // Exkludiere Zentralkenia == 4

quietly svy, subpop(`subgroupdropregion'): reg v133 elfcounty_v131 `baselinecontrols'
estimates store reg3_5
quietly svy, subpop(`subgroupdropregion'): ologit v106 elfcounty_v131  `baselinecontrols'
estimates store reg3_6
quietly svy, subpop(`subgroupdropregion'): logit v155_bin elfcounty_v131 `baselinecontrols'
estimates store reg3_7
quietly svy, subpop(`subgroupdropregion'): logit v149_bin elfcounty_v131 `baselinecontrols' 
estimates store reg3_8

outreg2 [reg3_5 reg3_6 reg3_7 reg3_8] using "${data_path}\output_regressions\Tabelle6", append keep(elfcounty_v131) label nocons noobs nor2 excel ctitle(Ohne Zentralkenia)



* 4.2 Drop Counties Marsabit und Tana River

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
local baselinecontrols urbanrt hv244 sekundaerschulen i.v013 i.v131 i.v130

tempvar subgroupdropcounty
gen `subgroupdropcounty' = 1
replace `subgroupdropcounty' = 0 if sregion == 401 | subgroupdrop == 0 // Exkludiere marsabit == 401

quietly svy, subpop(`subgroupdropcounty'): reg v133 elfcounty_v131 `baselinecontrols'
estimates store reg3_9
quietly svy, subpop(`subgroupdropcounty'): ologit v106 elfcounty_v131  `baselinecontrols'
estimates store reg3_10
quietly svy, subpop(`subgroupdropcounty'): logit v155_bin elfcounty_v131 `baselinecontrols'
estimates store reg3_11
quietly svy, subpop(`subgroupdropcounty'): logit v149_bin elfcounty_v131 `baselinecontrols' 
estimates store reg3_12

outreg2 [reg3_9 reg3_10 reg3_11 reg3_12] using "${data_path}\output_regressions\Tabelle6", append keep(elfcounty_v131) label nocons noobs nor2 excel ctitle(Ohne Marsabit)

tempvar subgroupdropcounty
gen `subgroupdropcounty' = 1
replace `subgroupdropcounty' = 0 if sregion == 304 | subgroupdrop == 0 // Exkludiere Tana River == 304

quietly svy, subpop(`subgroupdropcounty'): reg v133 elfcounty_v131 `baselinecontrols'
estimates store reg3_13
quietly svy, subpop(`subgroupdropcounty'): ologit v106 elfcounty_v131  `baselinecontrols'
estimates store reg3_14
quietly svy, subpop(`subgroupdropcounty'): logit v155_bin elfcounty_v131 `baselinecontrols'
estimates store reg3_15
quietly svy, subpop(`subgroupdropcounty'): logit v149_bin elfcounty_v131 `baselinecontrols' 
estimates store reg3_16

outreg2 [reg3_13 reg3_14 reg3_15 reg3_16] using "${data_path}\output_regressions\Tabelle6", append keep(elfcounty_v131) label nocons noobs nor2 excel ctitle(Ohne Tana River)



* 5 Berechne Schätzung mit Schulausstattung

* Aggregierte Analysen: Schulausstattung
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131CountyEstimationRecode", clear
local baselinecontrols urbanrt btotl_2014

quietly reg schoolbookstotal elfcounty_v131 `baselinecontrols', vce(robust)
outreg2 using "${data_path}\output_regressions\Tabelle6", append ctitle(Schulbuecher) excel
quietly reg teachpupiltotal elfcounty_v131 `baselinecontrols', vce(robust)
outreg2 using "${data_path}\output_regressions\Tabelle6", append ctitle(Lehrer-Schueler-Ratio) excel
quietly reg schooltoiletstotal elfcounty_v131 `baselinecontrols', vce(robust)
outreg2 using "${data_path}\output_regressions\Tabelle6", append ctitle(Schultoiletten) excel
