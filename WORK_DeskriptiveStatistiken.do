/// *** Erstelle descriptive Statistiken *** Reihenfolge in Erscheinen der Arbeit

*** 3.1 Datensatz
* Anzahl Individuen
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
quietly summarize subgroupdrop
display "Gesamtanzahl Individuen: " r(N)
quietly summarize subgroupdrop if subgroupdrop == 1
display "Gesamtanzahl Subgruppe: " r(N)

count if v104 == 96
display "Gesamtanzahl an Besuchern im Ort: " r(N)


*Vergleich Others im Datensatz
*Gesamt
quietly svy, subpop(subgroupdrop): prop v131

*In Counties
quietly svy, subpop(subgroupdrop): prop v131, over(sregion)

levelsof sregion, matrow(regions)
matrix othersprop = J(47,2,0) //Speichere Daten von Others in Matrix zum Vergleich
forvalues i = 1/47 {
	local currentregion = regions[`i',1]
	matrix othersprop[`i',1] = _b[96.v131@`currentregion'.sregion]
	matrix othersprop[`i',2] = `currentregion'
}
* matrix list othersprop


*** 3.2 Unabhängige Variablen
* Statistiken für County ELF
use ${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_CombinedRecode, clear
table v131 if subgroupdrop == 1, missing // Anzahl Missing Values

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_slnativeEstimationRecode", clear
* Anteil Others in Muttersprache
quietly svy, subpop(subgroupdrop): proportion slnative

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
quietly summarize elfcounty_v131
gsort elfcounty_v131
display "Min Sregion: "  sregion[1] ", ELF: " elfcounty_v131[1]
gsort -elfcounty_v131
display "Max Sregion: "  sregion[1] ", ELF: " elfcounty_v131[1]
display "Mean ELF: " r(mean)

* Berechnung ELF in Kenia - Gleiche Berechnung wie im Fall der Regionen und Counties
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear

levelsof v131, local(ethnics)
gen v131_perc_ken = .

quietly svy, subpop(subgroupdrop): proportion v131 //Anteil von Ethnie in Kenia und Verteilung auf alle Individuen der Ethnie
foreach i of local ethnics {
	replace v131_perc_ken = _b[`i'.v131] if v131 == `i'
}

gen v131first = .
bysort v131: replace v131first = 1 if _n == 1 & v131 != . //Markiere erste Observation jeder Ethnie außer Missings

egen elf_inv = sum(v131_perc_ken^2) if v131first == 1
generate elf = 1-elf_inv if v131first == 1

replace elf = elf[1] // Berechne ELF basierend auf erster Erscheinung
replace elf_inv = elf_inv[1]

display "ELF-Kenia: " elf[1]

* Verwendete Packages
ssc install spmap
ssc install shp2dta

* Generiere Datensatz auf Grundlage des Shapefiles
cd "${data_path}\raw_data\Shapefiles\shps"
shp2dta using sdr_subnational_boundaries2, database(kenyacounties_boundaries2) coordinates(kenyacounties_coord2) genid(kenyacountiesid) gencentroids(cen) replace  //Erstelle countyids und Datensatz
use kenyacounties_boundaries2, clear
rename REGCODE scounty
keep DHSREGEN kenyacountiesid scounty x_cen y_cen
gen Reglabel = ""
replace Reglabel = DHSREGEN if DHSREGEN == "Mombasa" | DHSREGEN == "Mandera" //Markiere höchste und niedrigste ELF-Wert
gen Grouplabel = 0
replace Grouplabel = 1 if DHSREGEN == "Mandera" //Markiere County, in welcher Label rechts von Centroid stehen soll
save "${data_path}\workdata\Temporary_Files\kenyacounties_boundaries2", replace


* Füge Datensätze von Shapefiles und ELF-Daten zusammen
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
collapse elfcounty_v131 scounty, by(sregion) //Wandel Daten auf County-Level um

merge 1:1 scounty using "${data_path}\workdata\Temporary_Files\kenyacounties_boundaries2"
drop _merge

//Create ELF-map
spmap elfcounty_v131 using "${data_path}\raw_data\Shapefiles\shps\kenyacounties_coord2", id(kenyacountiesid) ///
label(xcoord(x_cen) ycoord(y_cen) label(Reglabel) position(3 0) by(Grouplabel)) ///
fcolor(Oranges)  clmethod(custom) clbreaks(0 0.2 0.4 0.6 0.8 1) legtitle("ELF") //Erstelle Karte
graph export "${data_path}\output_graphs\Abbildung1.png", replace 


*** 3.3 Exogenität der ethnischen Diversität

* Vergleich 1993 und 1989
use "${data_path}\raw_data\DHS1993\KEIR33DT\KEIR33FL", clear
quietly count
display "Anzahl Beobachtungen 1993: " `r(N)'

use "${data_path}\raw_data\DHS1989\KEIR03DT\KEIR03FL", clear
quietly count
display "Anzahl Beobachtungen 1989: " `r(N)'

*Benötigtes package: asdoc
ssc install asdoc
* Vergleich ELF von 1989 und 2014 - Tabelle1
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_1993_2014_RegionRecode", clear
local regions "1 2 3 4 5 6 7"
local years "2014 1993 Differenz"
local vars "elfregion v131_max "

reshape wide //Wide-Format für Vergleich benötigt
quietly cor elfregion1993 elfregion2014
display "Korrelation: " r(C)[2,1]

gen elfregionDifferenz = abs(elfregion1993 - elfregion2014) //Berechnung absoluter Differenzen
gen v131_maxDifferenz = abs(v131_max1993 - v131_max2014)
reshape long

* Erstellung Tabelle1 Reihe für Reihe
asdoc, row(\i, \i, ELF, \i, \i, Groesste ethnische Gruppe, \i) replace save(${data_path}\output_graphs\Tabelle1.doc) fhc(\b) fhr(\b)
asdoc, row(\i, 2014, 1993, Differenz, 2014, 1993, Differenz)
asdoc, row(Regionen, \i, \i, \i, \i, \i, \i) 
* Zunächst werden alle benötigten Daten erstellt, akkumuliert und letztendlich der Tabelle hinzugefügt: help asdoc -> 16. Creating tables row by row
foreach i of local regions {
	local regionlabel: label Regionen `i'
	foreach j of local vars {
		foreach t of local years {
			quietly summarize `j' if geo_ke1989_2014 == `i' & elfregionyear == "`t'"
			asdoc, accum(`r(mean)')
		}
	}
	asdoc, row(`regionlabel', $accum )
} 



* Vergleich Miguel und Gugerty (2005) aus Busia mit Daten aus 2014 - Tabelle2
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear

label define V131 6 "Luyha" 7 "Luo" 16 "Teso", replace
label values v131 V131
local busiaethnics "6 7 16"

* Erstelle Tabelle2 Reihe für Reihe - Gleiches Package und Vorgehen wie oben: asdoc
asdoc, row(\i, Anteil 2014, \i, Anteil 1996, \i, Differenz) replace save(${data_path}\output_graphs\Tabelle2.doc) fhc(\b) fhr(\b)
asdoc, row(Ethnie, \i, \i, \i, \i, \i)
quietly svy, subpop(subgroupdrop): proportion v131, over(sregion)
* Speichere Werte nur für County 804: Busia und für Ethnien 6 (Luhya), 16 (Teso) und 7 (Luo)
local ethnic = _b[6.v131@804.sregion]
local difference = abs(`ethnic' - 0.67)
asdoc, accum(Luhya, `ethnic',\i, 0.67, \i, `difference') 
asdoc, row($accum)

local ethnic = _b[16.v131@804.sregion]
local difference = abs(`ethnic' - 0.26)
asdoc, accum(Teso, `ethnic', \i, 0.26, \i, `difference') 
asdoc, row($accum)
	
local ethnic = _b[7.v131@804.sregion]
local difference = abs(`ethnic' - 0.05)
asdoc, accum(Luo, `ethnic', \i, 0.05, \i, `difference') 
asdoc, row($accum)

*** 3.4 Zielvariablen
* Verteilung Alphabetisierung
table v155, missing //Anzahl fehlende Werte in Alphabetisierung

* Vergleich Zielvariablen - Tabelle3

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear

local abhaengigevarsDHS "v133 v106 v155_bin v149_bin"

label variable v133 "Schuljahre"
label variable v106 "Bildungsstufe"
label variable v155_bin "Alphabetisierung"
label variable v149_bin "Bildungsabschluss"
quietly svy, subpop(subgroupdrop) over(elfabovemedian): mean v133
* Erstelle Tabelle3
asdoc, row(\i, \i, ELF unter Median,\i, \i, \i, ELF ueber Median, \i, \i) replace save(${data_path}\output_graphs\Tabelle3.doc) fhc(\b) fhr(\b)
asdoc, row(\i, N, Mittelwert, SA, \i, N, Mittelwert, SA, P-Wert)
asdoc, row(Variable,\i,\i,\i,\i,\i,\i,\i)
asdoc, row(a:,\i,\i,\i,\i,\i,\i,\i,\i)
foreach i of local abhaengigevarsDHS {
	local variablelabel: variable label `i'
	quietly svy, subpop(subgroupdrop): mean `i', over(elfabovemedian)
	local nuvar = e(_N)[1,1]
	local meanvar = r(table)[1,1]
	quietly estat sd //Postestimation command für Standardabweichung
	local sdvar = r(sd)[1,1]

	asdoc, accum(`nuvar', `meanvar', `sdvar', \i)
	quietly svy, subpop(subgroupdrop): mean `i', over(elfabovemedian)
	local nuvar = e(_N)[1,2]
	local meanvar = r(table)[1,2]
	quietly estat sd
	local sdvar = r(sd)[1,2]	
	asdoc, accum(`nuvar', `meanvar', `sdvar')
	quietly test _b[c.`i'@0bn.elfabovemedian] = _b[c.`i'@1.elfabovemedian] // Zweiseitiger Ttest zwischen Mittelwerten, Verwendung Wald-Test, da nur dieser mit svy funktioniert
	asdoc, accum(`r(p)')
	asdoc, row(`variablelabel', $accum)
} 
asdoc, row(\i,\i,\i,\i,\i,\i,\i,\i, \i)

use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131CountyEstimationRecode", clear //Füge Schulqualitätsdaten der Tabelle3 hinzu 
local abhaengigevarsschool "schoolbookstotal schooltoiletstotal teachpupiltotal"

label var schoolbookstotal "Schulbuecher"
label var schooltoiletstotal "Schultoiletten"
label var teachpupiltotal "Schueler/Lehrer"

format schoolbookstotal %8.0f

* Erstelle b von Tabelle3
asdoc, row(b:, \i, \i, \i, \i, \i, \i, \i, \i) append save(${data_path}\output_graphs\Tabelle3.doc)

foreach i of local abhaengigevarsschool {
	local variablelabel: variable label `i'
	quietly summarize `i' if elfabovemedian == 0 //Kein svy mehr benötigt in Schätzung
	asdoc, accum(`r(N)', `r(mean)', `r(sd)', \i)
	quietly summarize `i' if elfabovemedian == 1
	asdoc, accum(`r(N)', `r(mean)', `r(sd)')
	quietly ttest `i', by(elfabovemedian) //Verwendung ttest
	asdoc, accum(`r(p)')
	asdoc, row(`variablelabel', $accum )
}



*** 3.5 Kontrollvariablen
* Anteil der ethnischen Gruppen
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
quietly svy, subpop(subgroupdrop): prop v131

* Tabelle 4
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear

local controls "urbanrt popdensity_2010 hv244 hv245 cropland sekundaerschulen v149_sekundaer_perc v012 v190" 
local ethnics "2 4 6"  // Größte ethnische Gruppen: Kalenjin(2), Kikuyu(4), Luhya(6)
* Verwendete Kontrollvariablen: - Verändere Labels  

label variable v190 "Wealth Index"
label variable cropland "Anteil Agrarland"
label variable v149_sekundaer_perc "Sekundaerschueler"
label variable popdensity_2010 "Bevoelkerungsdichte"
label variable v012 "Alter"
label variable sekundaerschulen "Sekundaerschulen"
label variable hv244 "Besitz Agrarland"
label variable hv245 "Hektar Agrarland"

label variable urbanrt "Urbanisierungsrate"

asdoc, row(\i,  Mittelwert, SA, Mittel Kalenjin, Mittel Kikuya, Mittel Luhya) replace save(${data_path}\output_graphs\Tabelle4.doc) dec(3) fhc(\b)
asdoc, row( Variable, \i, \i, \i, \i, \i)
foreach i of local controls {
	local variablelabel: variable label `i'
	quietly svy, subpop(subgroupdrop): mean `i'
	local meanvar = r(table)[1,1]
	quietly estat sd
	local sdvar = r(sd)[1,1]
	asdoc, accum(`meanvar', `sdvar')
	
	quietly svy, subpop(subgroupdrop): mean `i', over(v131)
	foreach j of local ethnics {
		local subgroupethnic = _b[c.`i'@`j'.v131] 
		asdoc, accum(`subgroupethnic')
	}

	asdoc, row(`variablelabel', $accum )
} 

*** 3.6 Statistisches Modell
*Angabe von GER und NER
use "${data_path}\workdata\DHS_Stata_UseFiles\DHS_2014_v131EstimationRecode", clear
destring ger ner, replace
collapse ger ner, by(sregion)
quietly mean ger
local germean = r(table)[1,1]
quietly mean ner
local nermean = r(table)[1,1]
display "GER Durchschnitt: " `germean' ", NER-Durchschnitt: " `nermean'
