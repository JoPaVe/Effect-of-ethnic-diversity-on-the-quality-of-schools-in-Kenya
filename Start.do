version 17
set more off //, perm
capture log close

// **** BESCHREIBUNG Ordnerstruktur *** //
* 1. do_files: Alle verwendeten Do-Files + Projekt BachelorThesis, geschrieben in Stata Version 17
* 2. output_graphs: Alle deskriptiven Tabellen und Abbildungen 
* 3. output_regressions: Alle Tabellen der geschätzten Regressionen
* 4. raw_data: Rohdaten, die in der Arbeit verwendet werden, u.a.:
*				- Shapefiles für Kenia
*				- DHS-Daten für alle Jahre
*				- DHS-IPUMS Supplementierungsdaten
*				- Verwendete PDF-Dokumente / Excel-Dokumente über Schulvariablen
* 5. workdata: Zwischengespeicherte Datensätze
*				- DHS_Stata_UseFiles: Verwendete Datensätze für Deskriptive Statistiken und Schätzungen
*				- Temporary_Files: Kontrolldatensätze, die weiter verarbeitet wurden


*******************************************************************************
/// **** PFAD ANGEBEN, in welchem Ordner liegt - Inklusive Ordnernamen **** ///
/// **** WICHTIG: Es das kein Leerzeichen im Datenpfad vorhanden sein. **** ///
*******************************************************************************
global data_path "C:\STATA_WD\Bachelor-Arbeit\Bachelorarbeit_JonasVerch_Daten"



// do WORK_DHScombining
cd $data_path

do "${data_path}\do_files\WORK_Datenzusammenfassung.do"
do "${data_path}\do_files\WORK_Datenvorbereitung.do"
do "${data_path}\do_files\WORK_DeskriptiveStatistiken.do"
do "${data_path}\do_files\WORK_Modellschätzung.do"

