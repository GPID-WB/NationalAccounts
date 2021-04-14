
********************
*** INTRODUCTION ***
********************
// This .do-file creates a series of real GDP, GNI, and HFCE per capita in 2017 PPPs, 2011 PPPs, 2010 USD and constant LCU
// It does so by combining series from the WDI, WEO, and the Maddison database
// Created by: Daniel Gerszon Mahler, Marta Schoch and Samuel Kofi Tetteh Baah.
// Last update: April 2021.

*****************
*** DIRECTORY ***
*****************
// Daniel
if (lower("`c(username)'") == "wb514665") {
	cd "C:\Users\WB514665\OneDrive - WBG\PovcalNet\GitHub\NationalAccounts"
}

else if (lower("`c(username)'") == "wb537472") {    //Enter your UPI.
	cd "C:\Users\wb537472\OneDrive - WBG\Documents\Git\NationalAccounts"   //Enter the path of your directory.
}
************************
*** PREPARE WDI DATA ***
************************

set checksum off

/*
// WDI does not have HFCE per capita in 2017 PPP and LCU, so the two series are in total. Will divide will pop later
wbopendata, ///
indicator(NY.GDP.MKTP.PP.KD; NY.GDP.MKTP.KD;      NY.GDP.MKTP.KN; /// GDP         (2017 PPP, 2010 USD, LCU)
		  NY.GDP.PCAP.PP.KD; NY.GDP.PCAP.KD;      NY.GDP.PCAP.KN; /// GDP/capita  (2017 PPP, 2010 USD, LCU)
          NY.GNP.MKTP.PP.KD; NY.GNP.MKTP.KD;      NY.GNP.MKTP.KN; /// GNI         (2017 PPP, 2010 USD, LCU)
		  NY.GNP.PCAP.PP.KD; NY.GNP.PCAP.KD;      NY.GNP.PCAP.KN; /// GNI/capita  (2017 PPP, 2010 USD, LCU)
          NE.CON.PRVT.PP.KD; NE.CON.PRVT.KD;      NE.CON.PRVT.KN; /// HFCE        (2017 PPP, 2010 USD, LCU)
		                     NE.CON.PRVT.PC.KD                  ; /// HFCE/capita (          2010 USD     )
		  NY.GDP.MKTP.KD.ZG; NY.GDP.PCAP.KD.ZG;	  NY.GDP.DEFL.ZS; /// GDP  growth and GDP/capita growth and GDP deflator
          NY.GNP.MKTP.KD.ZG; NY.GNP.PCAP.KD.ZG                  ; /// GNI  growth and GDP/capita growth
		  NE.CON.PRVT.KD.ZG; NE.CON.PRVT.PC.KD.ZG               ;  /// HFCE growth and GDP/capita growth
		  NY.GDP.PCAP.CN) long clear							/// GDP current LCU								 
		  
// WDI does not have HFCE/capita in 2017 PPP and LCU, so the two series are total. Will divide with pop later.
rename ny_gdp_mktp_pp_kd    gdp_ppp2017_wdi_npc
rename ny_gdp_mktp_kd       gdp_usd2010_wdi_npc
rename ny_gdp_mktp_kn       gdp_lcu_wdi_npc
rename ny_gdp_pcap_pp_kd    gdp_ppp2017_wdi
rename ny_gdp_pcap_kd       gdp_usd2010_wdi
rename ny_gdp_pcap_kn       gdp_lcu_wdi
rename ny_gdp_mktp_kd_zg    gdp_gro_wdi_npc
rename ny_gdp_pcap_kd_zg    gdp_gro_wdi
rename ny_gnp_mktp_pp_kd    gni_ppp2017_wdi_npc
rename ny_gnp_mktp_kd       gni_usd2010_wdi_npc
rename ny_gnp_mktp_kn       gni_lcu_wdi_npc
rename ny_gnp_pcap_pp_kd    gni_ppp2017_wdi
rename ny_gnp_pcap_kd       gni_usd2010_wdi
rename ny_gnp_pcap_kn       gni_lcu_wdi
rename ny_gnp_mktp_kd_zg    gni_gro_wdi_npc
rename ny_gnp_pcap_kd_zg    gni_gro_wdi
rename ne_con_prvt_pp_kd    hfce_ppp2017_wdi_npc
rename ne_con_prvt_kd       hfce_usd2010_wdi_npc
rename ne_con_prvt_kn       hfce_lcu_wdi_npc
rename ne_con_prvt_pc_kd    hfce_usd2010_wdi
rename ne_con_prvt_kd_zg    hfce_gro_wdi_npc
rename ne_con_prvt_pc_kd_zg hfce_gro_wdi
rename ny_gdp_defl_zs 		gdp_def_wdi 
rename ny_gdp_pcap_cn		gdplcucurr

replace gdplcucurr = 10*gdplcucurr if countrycode=="MRT"   //Currency conversion
replace gdplcucurr = 3.5781293062201*gdplcucurr if countrycode=="PSE"   //Currency conversion
 
rename countrycode       code
keep   code year gdp* gni* hfce* 
order code year gdp* gni* hfce* 
save "InputData/WDI_2021_03.dta", replace
*/

*********************
*** LOAD WDI DATA ***
*********************

use "InputData/WDI_2021_03.dta", clear
tempfile wdi
save    `wdi'

************************
*** PREPARE WEO DATA ***
************************
import excel using "InputData/WEO_2021_04.xlsx", clear firstrow case(lower)
// Only keeping variables on real GDP (no HFCE or GNI data)
keep if inlist(weosubjectcode,"NGDPRPC","NGDPRPPPPC","NGDP_R")
replace weosubjectcode="_lcu_weo"     if weosubjectcode=="NGDPRPC"
replace weosubjectcode="_ppp2017_weo" if weosubjectcode=="NGDPRPPPPC"
replace weosubjectcode="_lcu_weo_npc" if weosubjectcode=="NGDP_R"
// Renaming variable names after year
foreach var of varlist * {
	// Only perform changes for variables whose label start with 19 or 20 
	if inlist(substr("`: var label `var''",1,2),"19","20") {
		rename `var' gdp`: var label `var''
	}
}
// Only keeping relevant variables 
rename iso code
keep code weosubjectcode gdp*
// Fix countrycode discrepancies
replace code="PSE" if code=="WBG"
replace code="XKX" if code=="UVK"
// Reshape long by year
reshape long gdp, i(code weosubjectcode) j(year)
drop if inlist(gdp,"n/a","--")
destring gdp, replace
// Reshape wide by gdp variables
reshape wide gdp, i(code year) j(weosubjectcode) string
// Change pc variable from in billions:
replace gdp_lcu_weo_npc = gdp_lcu_weo_npc*10^9
tempfile weo
save    `weo'

*****************************
*** PREPARE MADDISON DATA ***
*****************************
// Load data from website
use "https://www.rug.nl/ggdc/historicaldevelopment/maddison/data/mpd2020.dta", clear
// Keep relevant variables
rename countrycode code
rename gdppc gdp_ppp2011_mdp
keep code year gdp_ppp2011_mdp
tempfile mdp
save    `mdp'

*******************************
*** PREPARE POPULATION DATA ***
*******************************
pcn master, load(population)
keep if coveragetype=="National"
rename countrycode code
keep code year population
replace population=population*10^6
tempfile pop
save    `pop'

********************************
*** PREPARE PPP DATA FOR HFCE***
********************************
datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v05_M) filename(pppdata_allvintages.dta)
keep if CoverageType=="National"
replace ppp_2011_v2_v1 = ppp_2011_v1_v1 if missing(ppp_2011_v2_v1)
keep code ppp_2011_v2_v1 ppp_2017_v1_v1
rename ppp_2011_v2_v1 ppp_cons2011
rename ppp_2017_v1_v1 ppp_cons2017

replace ppp_cons2011 = ppp_cons2011/72.22666667 if code=="LBR"  //Incorporate market exchange rate for Liberia
replace ppp_cons2017 = ppp_cons2017/112.7066667 if code=="LBR"  //Incorporate market exchange rate for Liberia

tempfile ppp_cons
save    `ppp_cons'

*******************************
*** PREPARE PPP DATA FOR GDP***
*******************************
import excel "InputData/Data_Extract_From_ICP_2017_full_sample.xlsx", sheet("Data") firstrow clear   
keep if SeriesName=="1000000:GROSS DOMESTIC PRODUCT" 
keep if ClassificationName=="PPPs (US$ = 1)" 

drop YR2012-YR2016 ClassificationCode SeriesName ClassificationName SeriesCode CountryName
rename CountryCode countrycode
rename YR2011 ppp_gdp2011
rename YR2017 ppp_gdp2017
replace countrycode = "XKX" if countrycode=="KSV"

replace ppp_gdp2011 = ppp_gdp2011/72.22666667 if countrycode=="LBR"  //Incorporate market exchange rate for Liberia
replace ppp_gdp2017 = ppp_gdp2017/112.7066667 if countrycode=="LBR"  //Incorporate market exchange rate for Liberia

lab var ppp_gdp2011	"Revised 2011 PPP, GDP (US$ = 1)"
lab var ppp_gdp2017	"2017 PPP, GDP (US$ = 1)"

duplicates drop
sort countrycode
rename countrycode code
drop if ppp_gdp2011==. & ppp_gdp2017==.

tempfile ppp_gdp
save    `ppp_gdp'



************************
*** PREPARE CPI DATA ***
************************
datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v05_M) filename(Yearly_CPI_Final.dta)
keep if inlist(year,2011,2017)
keep code year yearly_cpi
rename yearly_cpi cpi
reshape wide cpi, i(code) j(year)
tempfile cpi
save    `cpi'

*********************************
*** PREPARE GDP DEFLATOR DATA ***
*********************************
wbopendata, indicator(NY.GDP.DEFL.ZS;NY.GDP.DEFL.ZS.AD;NY.GDP.PCAP.CN;NY.GDP.PCAP.KN) clear long
rename ny_gdp_defl_zs 		gdp_def1       	//This variable has more observations.
rename ny_gdp_defl_zs_ad 	gdp_def2   		//This variable has fewer observations.
rename ny_gdp_pcap_cn 		gdppc_curr_lcu
rename ny_gdp_pcap_kn		gdppc_cons_lcu 

gen gdp_def_own = 100*gdppc_curr_lcu/gdppc_cons_lcu //Compute own GDP deflator and compare with what's already in WDI below.

sum gdp_def*
drop gdp_def2
rename gdp_def1 gdp_def
rename countrycode code
keep if inlist(year,2011,2017)
keep code year gdp_def gdp_def_own
*scatter gdp_def gdp_def_own   //Compare GDP deflator (own) with GDP deflator (WDI)

reshape wide gdp_def gdp_def_own, i(code) j(year)

gen x2011 = gdp_def2011/gdp_def_own2011
gen x2017 = gdp_def2017/gdp_def_own2017
*sort x2017
*br 
*sort x2011
*br
//Own GDP deflator 2017 for SDN differs slightly (relative difference=1.026717).
//Own GDP deflator 2011 for SDN differs slightly (relative difference=1.005251).
//I use GDP deflators from WDI going forward.

drop if gdp_def2011==. & gdp_def2017==. & gdp_def_own2011==.  & gdp_def_own2017==.
drop x*

tempfile gdp_def
save    `gdp_def'

*********************************
*** PREPARE COUNTRY LIST DATA ***
*********************************
pcn master, load(countrylist)
keep countrycode
rename countrycode code
tempfile iso
save    `iso'

*************************
*** MERGE ALL SOURCES ***
*************************
use 					  `wdi', clear
merge 1:1 code year using `weo', nogen
merge 1:1 code year using `mdp', nogen
merge 1:1 code year using `pop', nogen
merge m:1 code      using `ppp_cons', nogen
merge m:1 code      using `ppp_gdp', nogen
merge m:1 code      using `cpi', nogen
merge m:1 code      using `gdp_def', nogen

// Only keep 218 countries in WB universe
merge m:1 code      using `iso', nogen keep(2 3) /// _merge==1 are countries not among the 218
// Only keeping data from 1967 (first survey in PovcalNet) to the present year
local currentyear = substr("$S_DATE",-4,.)
keep if inrange(year,1967,`currentyear')

save "InputData/InputData_merged", replace 

use "InputData/InputData_merged", clear 

*********************************************
*** FILL OUT GAPS IN PER CAPITA VARIABLES ***
*********************************************
// Create/fill per capita data where missing
foreach var of varlist *ppp2017*_npc *usd2010*_npc *lcu*_npc {
	cap gen `=substr("`var'", 1, length("`var'")-4)' = `var'/population
	replace  `=substr("`var'", 1, length("`var'")-4)' = `var'/population if missing(`=substr("`var'", 1, length("`var'")-4)' )
	drop `var'
}
// Create/fill per capita growth where missing
foreach var of varlist *gro*npc {
	cap gen `=substr("`var'", 1, length("`var'")-4)' = ((`var'/100+1)*population[_n-1]/population-1)*100
	replace `=substr("`var'", 1, length("`var'")-4)' = ((`var'/100+1)*population[_n-1]/population-1)*100 if missing(`=substr("`var'", 1, length("`var'")-4)')
	drop `var'
}
drop population

*****************************************************
*** FILL OUT GAPS IN GDP WITH CONSTANT LCU VALUES ***
*****************************************************
count if missing(gdp_ppp2017_wdi) & !missing(gdp_lcu_wdi) & !missing(gdp_def2017) & !missing(ppp_gdp2017)
*br code year gdp_ppp2017_wdi gdp_lcu_wdi gdp_def2017 ppp_gdp2017 if missing(gdp_ppp2017_wdi) & !missing(gdp_lcu_wdi) & !missing(gdp_def2017) & !missing(ppp_gdp2017)

//Important to note: Base year for GDP deflator varies by country. First, determine the base years used, and move to the 2017 ICP reference years.  
gen gdpdef_base_ = gdp_def_wdi if gdplcucurr==gdp_lcu_wdi
egen gdpdef_base = mean(gdpdef_base_),by(code)
drop gdpdef_base_

gen gdpdef_cf_2017 = gdp_def2017/gdpdef_base   //Compute conversion factor for GDP deflator for 2017.

gen gdp_2017ppp_own = gdp_lcu_wdi * gdpdef_cf_2017 * (1/ppp_gdp2017)
gen d_gdp_2017ppp = gdp_ppp2017_wdi/gdp_2017ppp_own  //Check difference between own GDP and series in WDI for non-missing observations in WDI. 

sum d_gdp_2017ppp, d //Not a perfect match (mean = 1.000003, min = .9739763, max = 1.037369)

gsort -d_gdp_2017ppp
br code year d_gdp_2017ppp gdp_ppp2017_wdi gdp_2017ppp_own gdp_lcu_wdi gdp_def2017 ppp_gdp2017 if !missing(d_gdp_2017ppp)

br code year d_gdp_2017ppp gdp_ppp2017_wdi gdp_2017ppp_own ppp_gdp2017 if missing(gdp_ppp2017_wdi) & !missing(gdp_2017ppp_own)

sum gdp_ppp2017_wdi gdp_2017ppp_own
replace gdp_ppp2017_wdi = gdp_2017ppp_own if missing(gdp_ppp2017_wdi) & !missing(gdp_2017ppp_own)

drop gdp_2017ppp_own d_gdp_2017ppp gdpdef_base gdplcucurr gdpdef_cf_2017 gni_gro 

***********************************************
*** CREATE MISSING 2011 AND 2017 PPP SERIES ***
***********************************************
//GDP (using PPPs for GDP)
foreach type in gdp {  //I am removing gni from here because we agreed we cannot use GDP deflator for GNI per capita. Will be included later, and be derived from ratios between other currencies.
	foreach source in wdi weo mdp {
		cap gen `type'_ppp2017_`source' = `type'_ppp2011_`source'*ppp_gdp2011/ppp_gdp2017*gdp_def2017/gdp_def2011
		cap gen `type'_ppp2011_`source' = `type'_ppp2017_`source'*ppp_gdp2017/ppp_gdp2011*gdp_def2011/gdp_def2017
	}
}

//HFCE (using PPPs for private consumption)
foreach type in hfce {
	foreach source in wdi weo mdp {
		cap gen `type'_ppp2017_`source' = `type'_ppp2011_`source'*ppp_cons2011/ppp_cons2017*cpi2017/cpi2011
		cap gen `type'_ppp2011_`source' = `type'_ppp2017_`source'*ppp_cons2017/ppp_cons2011*cpi2011/cpi2017
	}
}

drop cpi2011 cpi2017 gdp_def2011 gdp_def2017 gdp_def_own2011 gdp_def_own2017 ppp_cons2011 ppp_cons2017 ppp_gdp2011 ppp_gdp2017 gdp_def_wdi 


**********************************
*** CREATE COMPLETE WDI SERIES ***
**********************************
foreach type in gdp  {  //-do-
	// Chain backwards and forwards
	foreach varprimary of varlist `type'_ppp2017_wdi `type'_ppp2011_wdi `type'_usd2010_wdi `type'_lcu_wdi {
		foreach varsecondary of varlist `type'_ppp2017_wdi `type'_ppp2011_wdi `type'_usd2010_wdi `type'_lcu_wdi {
			// Chain forwards other variable
			bysort code (year): replace `varprimary' = `varsecondary'/`varsecondary'[_n-1]*`varprimary'[_n-1] if missing(`varprimary')
			// Chain backwards with other variable
			gsort  code -year
			bysort code       : replace `varprimary' = `varsecondary'/`varsecondary'[_n-1]*`varprimary'[_n-1] if missing(`varprimary')
		}
		// Chain forwards with growth rate
		bysort code (year): replace `varprimary' = `varprimary'[_n-1]*(1+`type'_gro_wdi/100) if missing(`varprimary')
		// Chain backwards with growth rate
		gsort  code -year
		bysort code       : replace `varprimary' = `varprimary'[_n-1]/(1+`type'_gro_wdi[_n-1]/100) if missing(`varprimary')
	}
	drop `type'_gro_wdi
}


foreach type in hfce {
	// Chain backwards and forwards
	foreach varprimary of varlist `type'_ppp2017_wdi `type'_ppp2011_wdi `type'_usd2010_wdi `type'_lcu_wdi {
		foreach varsecondary of varlist `type'_ppp2017_wdi `type'_ppp2011_wdi `type'_usd2010_wdi `type'_lcu_wdi {
			// Chain forwards other variable
			bysort code (year): replace `varprimary' = `varsecondary'/`varsecondary'[_n-1]*`varprimary'[_n-1] if missing(`varprimary')
			// Chain backwards with other variable
			gsort  code -year
			bysort code       : replace `varprimary' = `varsecondary'/`varsecondary'[_n-1]*`varprimary'[_n-1] if missing(`varprimary')
		}
		// Chain forwards with growth rate
		bysort code (year): replace `varprimary' = `varprimary'[_n-1]*(1+`type'_gro_wdi/100) if missing(`varprimary')
		// Chain backwards with growth rate
		gsort  code -year
		bysort code       : replace `varprimary' = `varprimary'[_n-1]/(1+`type'_gro_wdi[_n-1]/100) if missing(`varprimary')
	}
	drop `type'_gro_wdi
}


// For some countries we know GDP in 2010 USD, GDP in 2017 PPP, and GNI in 2010 USD but not GNI in 2017 PPP. Below I leverage the fact that the ratio between GDP in 2010 USD and 2017 PPP should be the same as the ratio between GNI in 2010 USD and 2017 PPP to back out the element that's missing. And so on across currencies and across income measures.

gen gni_ppp2011_wdi = . //I am now introducing GNI in 2011 PPP, so that it can be derived from the ratios in other currencies.

foreach typ1 in gdp gni hfce {
	foreach typ2 in gdp gni hfce {
		foreach cur1 in ppp2017 ppp2011 usd2010 lcu {
			foreach cur2 in ppp2017 usd2010 lcu {
			replace `typ1'_`cur1'_wdi = `typ1'_`cur2'_wdi*(`typ2'_`cur1'_wdi/`typ2'_`cur2'_wdi) if missing(`typ1'_`cur1'_wdi)
		
			}
		}
	}
}

*************************************
*** FOR GDP CHAIN ON WEO/MADDISON ***
*************************************
cap drop nonmissing
foreach source in weo mdp {
	foreach type1  in ppp2017 ppp2011 usd2010 lcu {
		cap confirm var gdp_`type1'_`source'
		if !_rc {
		// If all data for a country is missing so far, use the looping-variable as the baseline
			cap confirm var gdp_`type1'_wdi 
			if !_rc {
				bysort code: egen nonmissing = count(gdp_`type1'_wdi)
				bysort code: replace gdp_`type1'_wdi = gdp_`type1'_`source' if nonmissing==0
				drop nonmissing
			}
			// Chain forwards and backwards
			foreach type2 in ppp2017 ppp2011 usd2010 lcu  {
				// Forwards
				bysort code (year): replace gdp_`type2'_wdi = gdp_`type1'_`source'/ gdp_`type1'_`source'[_n-1]*gdp_`type2'_wdi[_n-1] if missing(gdp_`type2'_wdi)
				// Backwards
				gsort code -year
				bysort code: replace gdp_`type2'_wdi = gdp_`type1'_`source'/gdp_`type1'_`source'[_n-1]*gdp_`type2'_wdi[_n-1] if missing(gdp_`type2'_wdi)
				sort code year
			}
		}
	}
}
drop *weo *mdp

******************************
*** LABELLING AND FINALIZE ***
******************************
// Remove WDI from variable names
foreach var of varlist hfce* gni* gdp* {
rename `var' `=substr("`var'", 1, length("`var'")-4)'
}
// Label variables
foreach type in gdp gni hfce {
local TYPE = upper(`"`type'"')
foreach curr in ppp2017 ppp2011 usd2010 lcu {
lab var `type'_`curr' "`TYPE' per capita in `curr'"
}
}

*******************************
*** CREATE GROWTH VARIABLES ***
*******************************
foreach type in gdp gni hfce {
bysort code (year): gen     `type'_growth = `type'_lcu/`type'_lcu[_n-1]-1
foreach cur in usd2010 ppp2011 ppp2017 {
bysort code (year): replace `type'_growth = `type'_`cur'/`type'_`cur'[_n-1]-1 if missing(`type'_growth)
}
local TYPE = upper(`"`type'"')
lab var `type'_growth "Growth in `TYPE' per capita"
}

****************
*** FINALIZE ***
****************
order code year gdp* gni* hfce*
format gdp* gni* hfce* %6.0f
format *growth %4.3f
compress

save "OutputData/NationalAccounts.dta", replace
