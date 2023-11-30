/*
Bereite Datensätze für deskriptive Statistiken und Schätzung vor
*/


cd $data_path

/// **** Datenvorbereitung DHS1993
* Vereinheitliche männliche und weibliche Beobachtungen in DHS1993
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_IPUMS_1993_CombinedRecode", clear

* Verwende komplexes Survey-Design an -> (vgl. Croft et al. 2018: 1.35)
rename perweight weight005wgt
gen stratum = v023
svyset v021 [pw=weight005wgt], strata(stratum)
label variable stratum "stratum - weight"

* Markiere alle Besucher 
gen visitorv104v135 = 0
replace visitorv104v135 = 1 if v104 == 96 | v104 == 97 | v104 == 98 | v135 == 2 // Markiere, wenn v104: Besucher (96), Inkonsistente Antwort (97), Keine Angabe (98) UND v135: Besucher (2)

* Erstelle Subgroupdrop = Nicht berücksichtigte Beobachtungen bestehend aus Besuchern und älteren Männern: 1 == berücksichtigt
gen subgroupdrop = 1
replace subgroupdrop = 0 if visitorv104v135 == 1

save ${data_path}\workdata\DHS_Stata_UseFiles\DHS_IPUMS_1993_CombinedRecode, replace
/// *** Datapreparation DHS 2014
* Create sample weights in DHS_2014_CombinedRecode - preparation for ELF comparison
use ${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_CombinedRecode, clear

gen weight005wgt = v005 / 1000000 // Anpassung Gewichtung -> (vgl. Croft et al. 2018: 1.32)
label variable weight005wgt "Gewichte (Adjustiert)"

* Verwende komplexes Survey-Design an -> (vgl. Croft et al. 2018: 1.35)
gen stratum = v023
svyset v021 [pw=weight005wgt], strata(stratum)
label variable stratum "stratum - weight"

* Erstelle Dummies für Besucher im Haushalt und Besucher im Ort (Nur für Hälfte der Befragten vorhanden) 
gen visitorv104v135 = 0
replace visitorv104v135 = 1 if v104 == 96 | v104 == 97 | v104 == 98 | v135 == 2 // Kodierung siehe oben

* Erstelle Subgruppen - die ausgeschlossen werden bei Analyse
gen subgroupdrop = 1
replace subgroupdrop = 0 if visitorv104v135 == 1

save ${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_CombinedRecode, replace


* Verarbeite Variablen des IPUMS -> Verwendung cropland, popdensity_2015
replace cropland = . if cropland == -998
replace popdensity_2010 = . if popdensity_2010 == -998
drop popdensity popdensity_2020 popdensity_2015 popdensity_2005 popdensity_2000

* Erstelle abhängige Variablen

* 1. Binäre schulische Bildung
gen v149_bin = 1
replace v149_bin = 0 if v149 == 0 | v149 == 1 //0, wenn Person keine Bildung oder unvollständige Bildung hat, 1 wenn mindestens Primärbildung
label define V149_bin 0 "Keine/unvollständige Bildung" 1 "Vollständige Bildung"
label values v149_bin V149_bin
label variable v149_bin "Bildungsabschluss (binaer)"

* 2. Erstelle schulische Variablen 
rename PrimarySchoolsBooksTotalTotal schoolbookstotal
gen schooltoiletspublic = PrimaryPupilToiletsPublicMale + PrimaryPupilToiletsPublicFemale
gen schooltoiletsprivate = PrimaryPupilToiletsPrivateMale + PrimaryPupilToiletsPrivateFemale
gen schooltoiletstotal = schooltoiletsprivate + schooltoiletspublic
rename PrimaryTeachPupilRatioTotal teachpupiltotal
rename GERTotal ger
rename NERTotal ner

replace schoolbookstotal = schoolbookstotal / 1000

label variable schoolbookstotal "Schulbuecher (Gesamt)" // in Tsd.
label variable schooltoiletstotal "Schultoiletten (Gesamt)"
label variable teachpupiltotal "Schueler/Lehrer Verhaeltnis (Gesamt)"
label variable ger "Bruttoeinschreibungsrate 'GER'"
label variable ner "Nettoeinschreibungsrate 'NER'"

* 3. Recode v155 - Alphabetisierung
replace v155 = . if v155 == 3 | v155 == 4 //Missings für Personen, die keine passende Karte hatten (8) oder blind sind (77)

gen v155_bin = 1 if v155 != .
replace v155_bin = 0 if v155 == 0 & v155 != .
label variable v155_bin "Alphabetisierung (binaer)" //0 = kann nicht, 1 = kann lesen/teilweise lesen
label define V155_bin 0 "Kann nicht/nur teilweise lesen" 1 "Kann lesen"

* Erstelle unabhängige Variablen
* 1. FPE-Variable
gen exptofpe = 0

forvalues i = 1989/1996 {
	quietly replace exptofpe = `i'- 1989 + 1 if v010 == `i' // Siehe Beschreibung in Arbeit
}
replace exptofpe = 8 if v010 >= 1997 // Alle über Geburtsjahr inklusive 1997 werden mit 8 Jahren Primärbildung angegeben
label variable exptofpe "FPE-Politik"

* 2. Individuum gehört Familie an, welche Ackerland besitzt -> Rekodierung der Anzahl an Hektar
replace hv245 = 0 if hv245 == . & hv244 != . // Rekodiere, wenn Frage nicht beantwortet wurde
replace hv245 = . if hv245 == 998 // Missing, wenn Antwort unbekannt

* 3. Gender variables
replace hv104 = 0 if hv104 == 2 //Rekodiere, dass Geschlecht binär 0 und 1  
label define HV104 0 "female" 1 "male", replace
label values hv104 HV104

* 4. Label v133
label variable v133 "Gesamtanzahl Schuljahre"

* 5. Anteil höherer Abschluss + Anzahl Sekundärschulen -> Proxy für Pull-Faktoren - Nachfrage nach Bildung
gen v149_sekundaer = 0
replace v149_sekundaer = 1 if v149 > 3 // Vollständige Sekundärschule = >=4

gen v149_sekundaer_perc = .
levelsof sregion, local(sregionlist)
quietly svy, subpop(subgroupdrop): mean v149_sekundaer, over(sregion) // Anteil an Sekundärschülern in Region und übertrage auf alle Individuen der Region
foreach i of local sregionlist {
	quietly replace v149_sekundaer_perc = _b[c.v149_sekundaer@`i'.sregion] if sregion == `i'
}
label variable v149_sekundaer_perc "Anteil von Sekundärschülern o.h."

rename SecondarySchoolsTotal sekundaerschulen 
label variable sekundaerschulen "Anzahl Sekundärschulen"


* 6. Urbanisationsrate v025 in DHS 
replace v025 = 0 if v025 == 2 // Recode zu binär 1-0 Variable
label define V025 0 "rural" 1 "urban", replace
label values v025 V025

gen urbanrt = . 
levelsof sregion, local(sregionlist) // Erstelle Variable der Urbanisierungsrate
svy, subpop(subgroupdrop): mean v025, over(sregion) // Anteil an urbanen Bevölkerung und übertrage auf alle Individuen in der Region
foreach i of local sregionlist {
	quietly replace urbanrt = _b[c.v025@`i'.sregion] if sregion == `i'
}
label variable urbanrt "Anteil urbaner Bevölkerung"


* 7. Dummy-Variable Urbanisationsrate
gen urbanrate_bin = 0
replace urbanrate_bin = 1 if urbanrt > 0.5
label variable urbanrate_bin "Anteil urbaner Bevölkerung > 0.5 (binaer)"

* 8. Gesamtbevölkerung durch 1000 teilen zur besseren Lesbarkeit
replace btotl_2014 = btotl_2014 / 1000

* 9. Kodierung von Hektar Agrarland
replace hv245 = . if hv245 == 998
replace hv245 = 95 if hv245 == 950

save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_EstimationRecode", replace
* Ergebnis: DHS_2014_EstimationRecode in DHS_Stata_UseFiles
* Weiter: ELF berechnen und auf Individuen mergen

/// *** Create ELF-Variable auf County-Ebene ***
	
* Ethnische Anteile berechnen auf County-Ebene

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_EstimationRecode", clear

tempvar subgroupdropv131 
gen `subgroupdropv131' = 1
replace `subgroupdropv131'= 0 if subgroupdrop == 0 | v131 == . // Verwende nur Individuen, die v131 Wert haben
tempvar subgroupdropslnative // Alternative Variable slnative
gen `subgroupdropslnative' = 1
replace `subgroupdropslnative' = 0 if subgroupdrop == 0 | slnative == .

gen v131_perc = .	
gen slnative_perc = . 
gen v131_kik = . // Anteil an Kikuyu in der Region

levelsof sregion, local(sregionlist)
levelsof v131, local(ethnics)
levelsof slnative, local(nativels)

****** BERECHNUNG BRAUCHT LANGE *******
	
quietly svy, subpop(`subgroupdropv131'): proportion v131, over(sregion) // Erstelle in jedem County für jede ethnische Gruppe den Anteil der jeweiligen Gruppe im County
foreach j of local ethnics {
	foreach t of local sregionlist {
		quietly replace v131_perc = _b[`j'.v131@`t'.sregion] if v131 == `j' & sregion == `t' 
		quietly replace v131_kik = _b[4.v131@`t'.sregion] if sregion == `t' 
	}
}
	
****** BERECHNUNG BRAUCHT LANGE *******
	
quietly svy, subpop(`subgroupdropslnative'): proportion slnative, over(sregion) // Das gleiche für die Sekundärvariable
foreach j of local nativels {
	foreach t of local sregionlist {
		quietly replace slnative_perc = _b[`j'.slnative@`t'.sregion] if slnative == `j' & sregion == `t'
	}
}
	
local ELFvariables2014 "v131 slnative"
foreach i of local ELFvariables2014 {	
	bysort sregion: egen `i'_max_region = max(`i'_perc) // Erstelle Variable mit größtem Anteil an Gruppe der Region
	* ELF berechnen auf County-Ebene

	gen sregion`i'first = .
	bysort sregion `i': replace sregion`i'first = 1 if _n == 1 & `i' != . // Markiere ersten Eintrag jeder ethnischen Gruppe 

	bysort sregion: egen elfcounty_inv_`i' = sum(`i'_perc^2) if sregion`i'first == 1 //Berechne Inverse des ELF beruhend auf jeder Ethnie 
	generate elfcounty_`i' = 1-elfcounty_inv_`i' if sregion`i'first == 1 // Berechne ELF 

	bysort sregion: replace elfcounty_`i' = elfcounty_`i'[1] // Kopiere ELF der ersten Beobachtung auf das ganze County
	bysort sregion: replace elfcounty_inv_`i' = elfcounty_inv_`i'[1]

	egen elfcountymedian_`i' = median(elfcounty_`i') // Berechne Medianwert und binäre Identifikation aller ELF-Werte
	gen elfabovemedian_`i' = 1 
	replace elfabovemedian_`i' = 0 if elfcounty_`i' < elfcountymedian_`i'
	label variable elfabovemedian_`i' "ELFcounty - über Median `i'"
	label variable elfcountymedian_`i' "ELFcounty - Median `i'"
	label variable elfcounty_`i' "ELF County `i'"
	
	save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_`i'EstimationRecode", replace
}		

cor elfcounty_slnative elfcounty_v131
display "Korrelation ELF-Variablen: " r(C)[1,2]

local ELFvariables2014 "v131 slnative"
/// *** Behalte nur Variablen, die wichtig für weitere Analyse sind
foreach i of local ELFvariables2014 {
	use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_`i'EstimationRecode", clear
	
	keep sregion scounty geo_ke1989_2014 v101 ///
	elfcountymedian_`i' elfabovemedian_`i' elfcounty_`i' ///
	v130 v131 slnative v131_* `i'_max_region subgroupdrop weight005wgt v021 v023 stratum ///
	v149 v149_bin v133 v155 v155_bin v106 ///
	v104 v012 v013 v025 exptofpe v190 hv244 hv245 urbanrt popdensity_2010 btotl_2014 v149_sekundaer_perc sekundaerschulen cropland ///
	schoolbookstotal schooltoiletstotal teachpupiltotal ger ner ///

	save ${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_`i'EstimationRecode, replace
}

* Ergebnis: DHS_2014_`i'EstimationRecode für v131 lnative
* Weiter: Merge Data für Jahresvergleich
/// *** Erstelle ELF in 1993 and 2914 auf regionalem level ***

* Create ELF for 2014 and 1993

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_CombinedRecode", clear

tempvar subgroupdropv131 
gen `subgroupdropv131' = 1
replace `subgroupdropv131' = 0 if subgroupdrop == 0 | v131 == . //Exkludiere, wenn v131 == . - gleiche wie oben 
gen v131_perc = .

levelsof v131, local(ethnics)
	
quietly svy, subpop(`subgroupdropv131'): proportion v131, over(geo_ke1989_2014) //Gleiche Berechnung der ELF wie oben - nun Aggregierung auf Regionsebene (1-8)
foreach j of local ethnics {
	forvalues t = 1/8 {
		replace v131_perc = _b[`j'.v131@`t'.geo_ke1989_2014] if v131 == `j' & geo_ke1989_2014 == `t'
	}
}

save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_CombinedRecode", replace

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_IPUMS_1993_CombinedRecode", clear // Berechnung ELF für 1993: Ethnien kodiert von 1-11, Regionen von 1-7
tempvar subgroupdropv131 
gen `subgroupdropv131' = 1
replace `subgroupdropv131' = 0 if subgroupdrop == 0 | v131 == .

gen v131_perc = .

quietly svy, subpop(`subgroupdropv131'): proportion v131, over(geo_ke1989_2014)
forvalues j = 1/11 {
	forvalues t = 1/7 {
		replace v131_perc = _b[`j'.v131@`t'.geo_ke1989_2014] if v131 == `j' & geo_ke1989_2014 == `t'
	}
}
save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_IPUMS_1993_CombinedRecode", replace


	
local ELFyears "2014 IPUMS_1993" //Loop über 2014 and IPUM_1993 für ELF-Berechnung in Regionen
foreach i of local ELFyears {
	
	use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_`i'_CombinedRecode", clear
	
	bysort geo_ke1989_2014: egen v131_`i'_max_region = max(v131_perc) // Variable mit größter ethnischer Gruppe der Region
	
	gen geov131first = .
	bysort geo_ke1989_2014 v131: replace geov131first = 1 if _n == 1 & v131 != .

	bysort geo_ke1989_2014: egen elfregion`i'_inv = sum(v131_perc^2) if geov131first == 1
	generate elfregion`i' = 1-elfregion`i'_inv if geov131first == 1

	bysort geo_ke1989_2014: replace elfregion`i' = elfregion`i'[1]
	bysort geo_ke1989_2014: replace elfregion`i'_inv = elfregion`i'_inv[1]
	keep elfregion`i' elfregion`i'_inv geo_ke1989_2014 v131_`i'_max_region
	drop if geo_ke1989_2014 == 8 // Lösche Observation Nord-Osten, da 1993 nicht vorhanden 
	duplicates drop
	label variable elfregion`i'_inv "Region ELF - inverse"
	label variable elfregion`i' "Region ELF"
	label variable v131_`i'_max_region "Groesste Ethnie in Region"
	label variable geo_ke1989_2014 "Regionen Kenia"
	
	save "${data_path}\workdata\Temporary_Files\DHS_`i'_ELFregion", replace
	
}

* Ergebnis: DHS_2014_ELFregion und DHS_IPUMS_1993_ELFregion in Temporary_Files
* Weiter: Merge DHS_2014_ELFregion und DHS_IPUMS_1993_ELFregion - Für spätere Analyse wird gemeinsamer Datensatz benötigt

use "${data_path}\workdata\Temporary_Files\DHS_IPUMS_1993_ELFregion"
merge 1:1 geo_ke1989_2014 using "${data_path}\workdata\Temporary_Files\DHS_2014_ELFregion"
drop _merge
* Anpassen der Lapels
label define Regionen 1 "Nairobi" 2 "Zentralkenia" 3 "Küste" 4 "Ostkenia" 5 "Nyanza" 6 "Rift Valley" 7 "Westkenia"
label drop GEO_KE1989_2014
label values geo_ke1989_2014 Regionen

* Veränder Datensatz zu Long-Format
drop elfregion2014_inv elfregionIPUMS_1993_inv
rename v131_2014_max_region v131_max2014
rename v131_IPUMS_1993_max_region v131_maxIPUMS_1993
reshape long elfregion v131_max, i(geo_ke1989_2014) j(elfregionyear, string)
replace elfregionyear = "1993" if elfregionyear == "IPUMS_1993"
label variable elfregionyear "Jahr"
label variable elfregion "ELF Region"

save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_1993_2014_RegionRecode", replace


* Ergebnis: DHS_1993_2014_RegionRecode für Vergleich
* Weiter: Aggregation einzelner Werte auf County-Ebene 

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
	
collapse teachpupiltotal elfcounty_v131 schoolbookstotal schooltoiletstotal urbanrt btotl_2014, by(sregion)
	
egen elfcountymedian_v131 = median(elfcounty_v131) //Gleiche Medianberechnung wie oben
gen elfabovemedian_v131 = 1
replace elfabovemedian_v131 = 0 if elfcounty_v131 < elfcountymedian_v131
label variable elfabovemedian_v131 "ELFcounty - über Median"
label variable elfcountymedian_v131 "ELFcounty - Median"
label variable elfcounty_v131 "ELF County"
	
save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131CountyEstimationRecode", replace

