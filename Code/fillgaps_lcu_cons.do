


wbopendata, indicator(NY.GDP.PCAP.KN;NY.GDP.PCAP.CN;NY.GDP.PCAP.KD;NY.GDP.DEFL.ZS;NY.GDP.PCAP.PP.KD) clear long

rename ny_gdp_pcap_kn 		gdplcucons 
rename ny_gdp_pcap_cn 		gdplcucurr 
rename ny_gdp_pcap_kd 		gdpusd2010 
rename ny_gdp_defl_zs 		gdpdef
rename ny_gdp_pcap_pp_kd 	gdpppp2017

keep countryname countrycode year gdp*

//Incorporate currency conversions 
replace gdplcucurr = 10*gdplcucurr if countrycode=="MRT"
replace gdplcucurr = 3.5781293062201*gdplcucurr if countrycode=="PSE"

sum gdplcucons gdplcucurr gdpusd2010 

br countryname countrycode year gdp* if gdplcucons==gdplcucurr & !missing(gdplcucurr)


//Get PPP data 

preserve 
	******************************
	import excel "InputData/Data_Extract_From_ICP_2017_full_sample.xlsx", sheet("Data") firstrow clear   
	keep if SeriesName=="1000000:GROSS DOMESTIC PRODUCT" 
	keep if ClassificationName=="PPPs (US$ = 1)" 

	drop YR2012-YR2016 ClassificationCode SeriesName ClassificationName SeriesCode CountryName
	rename CountryCode countrycode
	rename YR2011 ppp_gdp2011
	rename YR2017 ppp_gdp2017
	replace countrycode = "XKX" if countrycode=="KSV"

	*Adjustments for Liberia: WDI PPP is in USD, ICP PPP is in local currency units (Liberian dollars). I use the PPPs from the ICP, not WDI.

	//Since GDP per capita from WDI is being used, convert ICP PPP to WDI PPP for consistency. Divide ICP PPP by Liberia official market exchange rate.

	 /*
	Year -->																					2011			2017
	WDI	Liberia	LBR	Official exchange rate (LCU per US$, period average)	PA.NUS.FCRF		72.22666667		112.7066667
	WDI	Liberia	LBR	PPP conversion factor, GDP (LCU per international $)	PA.NUS.PPP		0.545838708		0.460993551
	ICP	Liberia	LBR	Official exchange rate (LCU per US$, period average)	PA.NUS.FCRF		72.22666667		112.7066667
	ICP	Liberia	LBR	PPP conversion factor, GDP (LCU per international $)	PA.NUS.PPP		39.42411041		51.95704651
	*/

	replace ppp_gdp2011 = ppp_gdp2011/72.22666667 if countrycode=="LBR"  //Incorporate market exchange rate for Liberia
	replace ppp_gdp2017 = ppp_gdp2017/112.7066667 if countrycode=="LBR"  //Incorporate market exchange rate for Liberia

	lab var ppp_gdp2011	"Revised 2011 PPP, GDP (US$ = 1)"
	lab var ppp_gdp2017	"2017 PPP, GDP (US$ = 1)"

	duplicates drop
	sort countrycode
	*rename countrycode code
	drop if ppp_gdp2011==. & ppp_gdp2017==.

	tempfile ppp_gdp
	save    `ppp_gdp'
restore 

merge m:1 countrycode using `ppp_gdp'

gen gdpdef_own = 100*gdplcucurr/gdplcucons 
sum gdpdef gdpdef_own

gen gdpdef_diff = gdpdef/gdpdef_own


br countrycode year gdpdef gdpdef_own gdpdef_diff

br countrycode year gdp* if (!missing(gdplcucons) | !missing(gdplcucurr)) & missing(gdpppp2017)

egen gdpdef2017_ = mean(gdpdef) if year==2017,by(countrycode)
egen gdpdef2017 = mean(gdpdef2017_),by(countrycode)
drop gdpdef2017_ 

gen gdpdef2017_1 = gdpdef/gdpdef2017
replace gdpdef2017_1 = gdpdef_own/gdpdef2017 if missing(gdpdef) & !missing(gdpdef_own)

egen gdpdef2011_ = mean(gdpdef) if year==2011,by(countrycode)
egen gdpdef2011 = mean(gdpdef2011_),by(countrycode)
drop gdpdef2011_ 

gen gdpdef2011_1 = gdpdef/gdpdef2011
replace gdpdef2011_1 = gdpdef_own/gdpdef2011 if missing(gdpdef) & !missing(gdpdef_own)

gen gdpppp2017_ = (gdplcucurr/gdpdef2017)*(1/ppp_gdp2017)
replace gdpppp2017 = gdpppp2017_ if missing(gdpppp2017)

//Compute GDP series in 2011 revised PPP. 
gen gdpppp2011 = gdpppp2017 * (ppp_gdp2017/ppp_gdp2011) * (gdpdef2017/gdpdef2011)

gen gdpppp2011_ = (gdplcucurr/gdpdef2011)*(1/ppp_gdp2011)
replace gdpppp2011 = gdpppp2011_ if missing(gdpppp2011)

drop gdpppp2017_ gdpppp2011_
br countrycode year gdp* 

br countrycode year gdp* if missing(gdpppp2017) & !missing(gdpppp2017_) & countrycode=="SDN"
tab countryname if missing(gdpppp2017) & !missing(gdpppp2017_) 
br countrycode year gdp* if countrycode=="SDN"
br countrycode year gdp* if countrycode=="SOM"

replace gdpppp2017 = gdpppp2017_ if missing(gdpppp2017)

gen x = gdpppp2017/gdpppp2017_

gsort -x
br countrycode gdp* x



bysort 



br countrycode year gdp* x if !(missing(gdpppp2017) & !missing(gdpppp2017_))

br gdpppp2017 gdpppp2017_ x if 
