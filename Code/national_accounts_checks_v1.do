
use "OutputData/NationalAccounts_30Mar2021.dta", clear 

preserve 
	wbopendata, indicator(NY.GDP.PCAP.KN;NY.GDP.PCAP.CN;NY.GDP.PCAP.KD;NY.GDP.DEFL.ZS;NY.GDP.PCAP.PP.KD) clear long

	rename ny_gdp_pcap_kn 		gdplcucons 
	rename ny_gdp_pcap_cn 		gdplcucurr 
	rename ny_gdp_pcap_kd 		gdpusd2010 
	rename ny_gdp_defl_zs 		gdpdef
	rename ny_gdp_pcap_pp_kd 	gdpppp2017

	keep countryname countrycode year gdp*
	rename countrycode code

	//Incorporate currency conversions 
	replace gdplcucurr = 10*gdplcucurr if code=="MRT"
	replace gdplcucurr = 3.5781293062201*gdplcucurr if code=="PSE"

	tempfile wdi
	save `wdi'
restore 

//Get PPP data 
preserve 
	******************************
	import excel "InputData/Data_Extract_From_ICP_2017_full_sample.xlsx", sheet("Data") firstrow clear   
	keep if SeriesName=="1000000:GROSS DOMESTIC PRODUCT" 
	keep if ClassificationName=="PPPs (US$ = 1)" 

	drop YR2012-YR2016 ClassificationCode SeriesName ClassificationName SeriesCode CountryName
	rename CountryCode code
	rename YR2011 ppp_gdp2011
	rename YR2017 ppp_gdp2017
	replace code = "XKX" if code=="KSV"


	replace ppp_gdp2011 = ppp_gdp2011/72.22666667 if code=="LBR"  //Incorporate market exchange rate for Liberia
	replace ppp_gdp2017 = ppp_gdp2017/112.7066667 if code=="LBR"  //Incorporate market exchange rate for Liberia

	lab var ppp_gdp2011	"Revised 2011 PPP, GDP (US$ = 1)"
	lab var ppp_gdp2017	"2017 PPP, GDP (US$ = 1)"

	duplicates drop
	sort code
	*rename code code
	drop if ppp_gdp2011==. & ppp_gdp2017==.

	tempfile ppp_gdp
	save    `ppp_gdp'
restore 

merge 1:1 code year using `wdi', nogen
merge m:1 code using `ppp_gdp', nogen
sort code year
keep if year>=1967

//Try to use GDP (constant LCU) to fill gaps.

preserve 
count if !missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))
br code year gdp_lcu gdp_ppp2017 gdp_ppp2011 gdp_usd2010 gdpdef gdplcucurr if  (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) 

br code year gdp_lcu gdp_ppp2017 gdp_ppp2011 gdp_usd2010 gdpdef gdplcucurr if  (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) | code=="CHI"

gen gdpdef_own = 100*gdplcucurr/gdp_lcu
gen pi_base_ = gdpdef if gdplcucurr==gdp_lcu
egen pi_base = mean(pi_base_),by(code)
drop pi_base_

egen gdp_def2011_ = mean(gdpdef) if year==2011,by(code)
egen gdp_def2011 = mean(gdp_def2011_),by(code)
drop gdp_def2011_ 

egen gdp_def2017_ = mean(gdpdef) if year==2017,by(code)
egen gdp_def2017 = mean(gdp_def2017_),by(code)
drop gdp_def2017_ 

gen pi_cf_2011 = gdp_def2011/pi_base
gen pi_cf_2017 = gdp_def2017/pi_base

gen gdp_2011ppp_lcu = gdp_lcu * pi_cf_2011 * (1/ppp_gdp2011)
gen gdp_2017ppp_lcu = gdp_lcu * pi_cf_2017 * (1/ppp_gdp2017)

gen d_gdp_2011ppp = gdp_2011ppp/gdp_2011ppp_lcu
gen d_gdp_2017ppp = gdp_2017ppp/gdp_2017ppp_lcu

br code year gdp_lcu gdp_ppp2017 gdp_ppp2011 gdp_usd2010 gdpdef gdplcucurr if  (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) & !missing(gdp_2011ppp_lcu) & missing(gdp_2011ppp)

br code year gdp_lcu gdp_ppp2017 gdp_ppp2011 gdp_usd2010 gdpdef gdplcucurr if  (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) & !missing(gdp_2017ppp_lcu) & missing(gdp_2017ppp)

restore 


count if !missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))
order code year gdp_lcu gdplcucons gdplcucurr gdpdef gdp_usd2010 gdpusd2010 gdp_ppp2017 gdpppp2017 ppp_gdp2017 gdp_ppp2011 ppp_gdp2011

br code year gdp_lcu gdplcucons gdplcucurr gdp_ppp2017 gdp_ppp2011 gdp_usd2010 ppp_gdp2017 ppp_gdp2011 gdpdef if (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) | code=="SOM"  //missing data from 1991.

br code year gdp_lcu gdplcucons gdplcucurr gdp_ppp2017 gdp_ppp2011 gdp_usd2010 ppp_gdp2017 ppp_gdp2011 gdpdef if (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) | code=="SOM"

br code year gdp_lcu gdplcucons gdplcucurr gdp_ppp2017 gdp_ppp2011 gdp_usd2010 gdpdef ppp_gdp2017 ppp_gdp2011 if (!missing(gdplcucurr) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010)))

br code year gdp_lcu gdplcucons gdplcucurr gdp_ppp2017 gdp_ppp2011 gdp_usd2010 gdpdef ppp_gdp2017 ppp_gdp2011 if (!missing(gdplcucurr) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) | code=="ERI"

egen gdp_def2017_1_ = mean(gdpdef) if year==2017,by(code)
egen gdp_def2017_1 = mean(gdp_def2017_1_),by(code)
drop gdp_def2017_1_ 
replace gdp_def2017_1 = gdpdef/gdp_def2017_1  //GDP deflator with base year 2017.

gen gdp_ppp2017_wdi_ = (gdplcucurr/gdp_def2017_1)*(1/ppp_gdp2017)
br gdp_ppp2017 gdp_ppp2017_wdi_ if missing(gdp_ppp2017) & !missing(gdp_ppp2017_wdi_)

replace gdp_ppp2017 = gdp_ppp2017_wdi_ if missing(gdp_ppp2017) & !missing(gdp_ppp2017_wdi_)
drop gdp_ppp2017_wdi_ 

egen gdp_def2011_1_ = mean(gdpdef) if year==2011,by(code)
egen gdp_def2011_1 = mean(gdp_def2011_1_),by(code)
drop gdp_def2011_1_ 
replace gdp_def2011_1 = gdpdef/gdp_def2011_1  //GDP deflator with base year 2011.

gen gdp_ppp2011_wdi = (gdplcucurr/gdp_def2011_1)*(1/ppp_gdp2011)
gen d_gdp_ppp2011 = gdp_ppp2011/gdp_ppp2011_wdi
br code year gdp_ppp2011 gdp_ppp2011_wdi d_gdp_ppp2011 if (missing(gdp_ppp2011) & !missing(gdp_ppp2011_wdi)) | inlist(code,"SDN","ERI","YEM")

br code year gdp_ppp2011 gdp_ppp2011_wdi d_gdp_ppp2011 if !((missing(gdp_ppp2011) & !missing(gdp_ppp2011_wdi)) | inlist(code,"SDN","ERI","YEM","GHA"))

sum d_gdp_ppp2011 if !((missing(gdp_ppp2011) & !missing(gdp_ppp2011_wdi)) | inlist(code,"SDN","ERI","YEM"))

count if missing(gdp_ppp2011) & !missing(gdp_ppp2011_wdi)
replace gdp_ppp2011 = gdp_ppp2011_wdi if missing(gdp_ppp2011) & !missing(gdp_ppp2011_wdi)


gsort -d_gdp_ppp2011
br code year d_gdp_ppp2011 gdp_ppp2011 gdp_ppp2011_wdi


drop gdp_def2011_1 gdp_def2017_1 gdplcucurr



//Check which observations got added. 
use "OutputData/NationalAccounts_30Mar2021.dta", clear

foreach var of varlist gdp* gni* hfce*{
rename `var' `var'_
}

merge 1:1 code year using "OutputData/NationalAccounts_06Apr2021.dta", nogen


sum gdp_ppp2017_ gdp_ppp2017 
br code year gdp_ppp2017_ gdp_ppp2017 if missing(gdp_ppp2017_) & !missing(gdp_ppp2017)
br code year gdp_ppp2017_ gdp_ppp2017 if !missing(gdp_ppp2017_) & missing(gdp_ppp2017)
gen d_gdp_ppp2017 = gdp_ppp2017/gdp_ppp2017_
gsort -d_gdp_ppp2017
br code year gdp_ppp2017_ gdp_ppp2017 d_gdp_ppp2017 


sum gdp_ppp2011_ gdp_ppp2011 
br code year gdp_ppp2011_ gdp_ppp2011 if missing(gdp_ppp2011_) & !missing(gdp_ppp2011)
count if missing(gdp_ppp2011_) & !missing(gdp_ppp2011)
br code year gdp_ppp2011_ gdp_ppp2011 if missing(gdp_ppp2011_) & !missing(gdp_ppp2011)

sum gdp_usd2010_ gdp_usd2010 
br code year gdp_usd2010_ gdp_usd2010 if missing(gdp_usd2010_) & !missing(gdp_usd2010)
count if missing(gdp_usd2010_) & !missing(gdp_usd2010)
br code year gdp_usd2010_ gdp_usd2010 if !missing(gdp_usd2010_) & missing(gdp_usd2010)

sum gni_ppp2011_ gni_ppp2011 
br code year gni_ppp2011_ gni_ppp2011 if missing(gni_ppp2011_) & !missing(gni_ppp2011)
count if missing(gni_ppp2011_) & !missing(gni_ppp2011)
br code year gni_ppp2011_ gni_ppp2011 if !missing(gni_ppp2011_) & missing(gni_ppp2011)

sum gni_ppp2017_ gni_ppp2017 
br code year gni_ppp2017_ gni_ppp2017 if missing(gni_ppp2017_) & !missing(gni_ppp2017)
count if missing(gni_ppp2017_) & !missing(gni_ppp2017)
br code year gni_ppp2017_ gni_ppp2017 if !missing(gni_ppp2017_) & missing(gni_ppp2017)