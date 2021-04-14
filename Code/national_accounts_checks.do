
use "OutputData/NationalAccounts_06Apr2021.dta", clear 

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

preserve 
	use "OutputData/NationalAccounts_30Mar2021.dta", clear 

	foreach var of varlist gdp* gni* hfce*{
	rename `var' `var'_
	}

	keep code year gdp* 

	tempfile mar30 
	save `mar30' 
restore 

merge 1:1 code year using `mar30', nogen
sort code year 
gen gdp_def_own = 100*gdplcucurr/gdplcucons


egen gdp_def2017_1_ = mean(gdpdef) if year==2017,by(code)
egen gdp_def2017_1 = mean(gdp_def2017_1_),by(code)
drop gdp_def2017_1_ 
replace gdp_def2017_1 = gdp_def_own/gdp_def2017_1  //GDP deflator with base year 2017.

egen gdp_def2011_1_ = mean(gdp_def_wdi) if year==2011,by(code)
egen gdp_def2011_1 = mean(gdp_def2011_1_),by(code)
drop gdp_def2011_1_ 
replace gdp_def2011_1 = gdp_def_wdi/gdp_def2011_1  //GDP deflator with base year 2011.

gen gdp_ppp2017_wdi_ = (gdplcucurr/gdp_def2017_1)*(1/ppp_gdp2017)
replace gdp_ppp2017_wdi = gdp_ppp2017_wdi_ if missing(gdp_ppp2017_wdi) & !missing(gdp_ppp2017_wdi_)
drop gdp_ppp2017_wdi_ 

gen gdp_ppp2011_wdi = (gdplcucurr/gdp_def2011_1)*(1/ppp_gdp2011)
drop gdp_def2011_1 gdp_def2017_1 gdplcucurr

count if !missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))
order code year gdp_lcu_ gdp_lcu gdplcucons gdplcucurr gdpdef gdp_usd2010_ gdp_usd2010 gdpusd2010 gdp_ppp2017_ gdp_ppp2017 gdpppp2017 gdp_ppp2017_wdi_ ppp_gdp2017 gdp_ppp2011_ gdp_ppp2011 ppp_gdp2011

br code year gdp_lcu gdplcucons gdplcucurr gdpdef gdp_usd2010 gdpusd2010 gdp_ppp2017 gdpppp2017 ppp_gdp2017 gdp_ppp2011 ppp_gdp2011 if !missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))

br code year gdp_lcu gdplcucons gdplcucurr gdpdef gdp_usd2010 gdpusd2010 gdp_ppp2017 gdpppp2017 ppp_gdp2017 gdp_ppp2011 ppp_gdp2011 if (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) | code=="SOM"

br code year gdp_lcu_ gdp_lcu gdplcucons gdplcucurr gdpdef gdp_usd2010_ gdp_usd2010 gdpusd2010 gdp_ppp2017_ gdp_ppp2017 gdpppp2017 ppp_gdp2017 gdp_ppp2011_ gdp_ppp2011 ppp_gdp2011 if (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010))) | code=="AND"

br code year gdp_lcu_ gdp_lcu gdplcucons gdplcucurr gdpdef gdp_usd2010_ gdp_usd2010 gdpusd2010 gdp_ppp2017_ gdp_ppp2017 gdpppp2017 gdp_ppp2017_wdi_ ppp_gdp2017 gdp_ppp2011_ gdp_ppp2011 ppp_gdp2011 if (!missing(gdp_lcu) & (missing(gdp_ppp2017) | missing(gdp_ppp2011) | missing(gdp_usd2010)))



sum gdp_ppp2011_ gdp_ppp2011
gen d_gdp_ppp2011 = gdp_ppp2011_ - gdp_ppp2011
count if d_gdp_ppp2011!=0 & !missing(d_gdp_ppp2011)
br code year gdp_ppp2011_ gdp_ppp2011 d_gdp_ppp2011 if d_gdp_ppp2011!=0 & !missing(d_gdp_ppp2011)