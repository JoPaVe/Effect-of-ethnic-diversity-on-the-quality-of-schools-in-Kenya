/*
Füge alle Datensätze zusammen
Verwendete Datensätze: 
2014: 
KEIR72FL - Women Recode 
DHS_IPUMS_2014_WomenRecode - IPUMS Export -> Ziel: Verwendung von Kontrollvariablen + Variable geo_ke1989_2014 als einheitliche geographische Einheit
1993:
KEIR33FL - Women Recode
DHS_IPUMS_1993_WomenRecode - IPUMS Export -> Ziel: Verwendung von Kontrollvariablen + Variable geo_ke1989_2014 als einheitliche geographische Einheit
*/

cd $data_path
/// *** Erstelle Datensatz für 2014 ***

* Women Recode 2014
use "${data_path}\raw_data\DHS2014\KEIR72DT\KEIR72FL", clear
keep caseid v001 v002 v003 v004 v005 v009 v010 v011 v012 v013 v021 /// 
v023 v024 v025 v101 v103 v104 v106 v130 v131 v133 v135 v149 v190 v191 v201 ///
v501 v701 v702 v715 v729 v714 v719 v155 scounty sregion slnative /// 

save "${data_path}\workdata\Temporary_Files\DHS_2014_WomenRecode", replace

/// *** Merge von IPUMS DHS und Original DHS ***

* Women Recode 2014
use "${data_path}\raw_data\DHS2014\DHS_IPUMS_2014_WomenRecode", clear

keep clusterno hhnum lineno caseid geo_ke1989_2014 popdensity* cropland
/*
drop sample samplestr country year idhspid idhshid dhsid idhspsu ///
idhsstrata psu strata domain perweight dvweight urban geo_ke2014 ///
age age5year resident religion ethnicityke marstat cheb currwork ///
whoworkfor wealthq wealths lit2 educlvl yrschl edyrtotal yrschl ///
edyrtotal edachiever husedlvl husedyr husedyrs husedachiever pastureland ///
*/

rename (clusterno hhnum lineno) (v001 v002 v003)  //Bereite Merge von IPUMS und DHS Daten vor: v001 v002 v003 = unique identifier
sort v001 v002 v003

tempfile WomenAppendFile //Save Tempfile für den Merge
save `WomenAppendFile'

use "${data_path}\workdata\Temporary_Files\DHS_2014_WomenRecode", clear
sort v001 v002 v003

merge 1:1 v001 v002 v003 using `WomenAppendFile'
drop if _merge != 3
drop _merge
save ${data_path}\workdata\Temporary_Files\DHS_2014_WomenRecode_merged, replace // Speicher Merged File ab: 31,079 Matches merged

* Ergebnis: DHS_2014_WomanRecode_merged - Datensätze von Frauen (Gesamt: IPUMS und OriginalDHS)
* Weiter: Füge alle bestehenden Informationen zusammen / Kontrollvariablen etc.
use ${data_path}\workdata\Temporary_Files\DHS_2014_WomenRecode_merged, clear
tempfile DHSCombinedFile
save `DHSCombinedFile'

* Füge aggregierte Schulinformationen hinzu - Vorhanden auf County-Ebene
import excel "${data_path}\raw_data\SchoolOutcome", clear firstrow

save "${data_path}\workdata\Temporary_Files\SchoolOutcome_2014_County", replace

merge 1:m sregion using `DHSCombinedFile'
drop if _merge != 3
drop _merge

save `DHSCombinedFile', replace

* Füge aggregierte Bevölkerungsinformationen hinzu - Vorhanden auf County-Ebene
import excel "${data_path}\raw_data\PopulationEstimates_Kenya_DHS_Adjusted", clear firstrow

merge 1:m sregion using `DHSCombinedFile'
label variable btotl_2014 "Total Population 2014 in County"
drop if _merge != 3
drop _merge

sort v001 v002 v003 // Sortierung als Vorbereitung für nächsten Schritt: Merge mit Haushaltsdatensatz
save `DHSCombinedFile', replace

* Füge Informationen den Individuen hinzu, die auf Haushaltsebene erfasst wurden - Vorhanden auf Individualebene

use "${data_path}\raw_data\DHS2014\KEPR72DT\KEPR72FL", clear
keep hv001 hv002 hvidx hv244 hv245 hv005 hv027 hv104 hv121 hv125 // Behalte Variablen von Haushaltsbefragung - Können Individuen zugeordnet werden
rename (hv001 hv002 hvidx) (v001 v002 v003)
sort v001 v002 v003

merge 1:1 v001 v002 v003 using `DHSCombinedFile'
drop if _merge != 3
drop _merge

label values sregion SHREGION

save ${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_CombinedRecode, replace

* Ergebnis: DHS_2014_CombinedRecode ind DHS_Stata_UseFiles - Kompletter Datensatz zur weiteren Vorbereitung


/// *** Erstelle historischen Datensatz 1993 ***
* Prepariere IPUMS Export - Merge mit DHS Datensatz -> Verwendung Originaldaten von DHS, aber geographische Einheit von IPUMS
use "${data_path}\raw_data\DHS1993\DHS_IPUMS_1993_WomenRecode", clear
rename clusterno v001
rename hhnum v002
rename lineno v003
sort v001 v002 v003

tempfile WomenFile_IPUMS
save `WomenFile_IPUMS'

use "${data_path}\raw_data\DHS1993\KEIR33DT\KEIR33FL", clear
sort v001 v002 v003

merge 1:1 v001 v002 v003 using `WomenFile_IPUMS'
drop _merge
save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_IPUMS_1993_WomenRecode", replace

keep perweight geo_ke1989_2014 v131 v001 v002 v003 v005 v021 v023 v012 v104 v135 // Behalte Variablen, die für Analyse notwendig sind

save "${data_path}\workdata\DHS_Stata_UseFiles\DHS_IPUMS_1993_CombinedRecode", replace

* Ergebnis: DHS_IPUMS_1993_CombinedRecode ind DHS_Stata_UseFiles - Kompletter historischer Datensatz zur weiteren Vorbereitung
