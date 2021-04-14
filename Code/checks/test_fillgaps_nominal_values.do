***Check if current LCU values could be used to fill gaps.
 
//GDP 
wbopendata, indicator(NY.GDP.PCAP.PP.KD; NY.GDP.PCAP.KD;NY.GDP.PCAP.KN;NY.GDP.PCAP.CN;NY.GDP.DEFL.ZS) clear long
keep countrycode year ny_gdp_pcap_pp_kd ny_gdp_pcap_kd ny_gdp_pcap_kn ny_gdp_pcap_cn ny_gdp_defl_zs
rename ny_gdp_pcap_pp_kd 	gdp2017ppp 		//GDP per capita, constant 2017 PPP 
rename ny_gdp_pcap_kd		gdp2010usd		//GDP per capita, constant 2010 USD 
rename ny_gdp_pcap_kn		gdpconslcu		//GDP per capita, constant LCU
rename ny_gdp_pcap_cn		gdpcurrlcu		//GDP per capita, current LCU
rename ny_gdp_defl_zs		gdp_def  		//GDP deflator

keep if year>=1967 & year<=2021

sum 
count if gdpconslcu==. & gdpcurrlcu!=.
sum gdpconslcu gdpcurrlcu gdp_def if gdpconslcu==. & gdpcurrlcu!=.
br gdpconslcu gdpcurrlcu gdp_def if gdpconslcu==. & gdpcurrlcu!=.   //No GDP deflator to convert current LCU into constant LCU values.

//GNI
wbopendata, indicator(NY.GNP.PCAP.PP.KD;NY.GNP.PCAP.KD;NY.GNP.PCAP.KN;NY.GNP.PCAP.CN;NY.GDP.DEFL.ZS) clear long  
keep countrycod year ny_gnp_pcap_pp_kd ny_gnp_pcap_kd ny_gnp_pcap_kn ny_gnp_pcap_cn ny_gdp_defl_zs
rename ny_gnp_pcap_pp_kd	gni2017ppp 		//GNI per capita, constant 2017 PPP 
rename ny_gnp_pcap_kd		gni2010usd		//GNI per capita, constant 2010 USD 
rename ny_gnp_pcap_kn		gniconslcu		//GNI per capita, constant LCU
rename ny_gnp_pcap_cn		gnicurrlcu		//GNI per capita, current LCU
rename ny_gdp_defl_zs		gdp_def  		//GDP deflator

keep if year>=1966 & year<=2021

sum 
count if gniconslcu==. & gnicurrlcu!=.
sum gniconslcu gnicurrlcu gdp_def if gniconslcu==. & gnicurrlcu!=.
br countrycode year gniconslcu gnicurrlcu gdp_def  if gniconslcu==. & gnicurrlcu!=.   

*Can I use GDP deflator to deflate GNI? I am not sure that will work (see below).
gen def = 100*gnicurrlcu/gniconslcu
sum gdp_def def if gdp_def!=. & def!=.

sort countrycode year 
bysort countrycode: gen g_gdp_def = gdp_def[_n]/gdp_def[_n-1]
bysort countrycode: gen g_def = def[_n]/def[_n-1]

sum gdp_def def g_def g_gdp_def if gdp_def!=. & def!=.
br countrycode year gdp_def def g_def g_gdp_def if gdp_def!=. & def!=.  //Levels and growth rates are not the same.

*--->Do you know what series is used to deflate GNI per capita?


//HFCE
wbopendata, indicator(NE.CON.PRVT.PP.KD;NE.CON.PRVT.KD;NE.CON.PRVT.KN;NE.CON.PRVT.CN;SP.POP.TOTL;FP.CPI.TOTL) clear long
keep countrycode year ne_con_prvt_pp_kd ne_con_prvt_kd ne_con_prvt_kn ne_con_prvt_cn sp_pop_totl fp_cpi_totl 
rename ne_con_prvt_pp_kd	hfce2017ppp  	//HFCE, constant 2017 PPP
rename ne_con_prvt_kd		hfce2010usd		//HFCE, constant 2010 USD
rename ne_con_prvt_kn		hfceconslcu		//HFCE, constant LCU
rename ne_con_prvt_cn		hfcecurrlcu		//HFCE, current LCU 
rename sp_pop_totl			pop				//Population 
rename fp_cpi_totl			cpi				//CPI


replace hfce2017ppp = hfce2017ppp/pop 		//HFCE per capita, constant 2017 PPP
replace hfce2010usd = hfce2010usd/pop 		//HFCE per capita, constant 2010 USD
replace hfceconslcu = hfceconslcu/pop 		//HFCE per capita, constant LCU
replace hfcecurrlcu = hfcecurrlcu/pop		//HFCE per capita, current LCU 

keep if year>=1966 & year<=2021
sum 
sum hfceconslcu hfcecurrlcu cpi if hfceconslcu==. & hfcecurrlcu!=.

br countrycode year hfceconslcu hfcecurrlcu cpi if hfceconslcu==. & hfcecurrlcu!=.

*Can I use CPI to deflate HFCE per capita? I am not sure that will work (see below).
gen hfce_pi = 100*hfcecurrlcu/hfceconslcu
sum hfce_pi cpi if hfce_pi!=. & cpi!=.

sort countrycode year 
bysort countrycode: gen g_hfce_pi = hfce_pi[_n]/hfce_pi[_n-1]
bysort countrycode: gen g_cpi = cpi[_n]/cpi[_n-1]

sum hfce_pi cpi g_hfce_pi g_cpi if g_hfce_pi!=. & g_cpi!=.
br countrycode year hfce_pi cpi g_hfce_pi g_cpi if g_hfce_pi!=. & g_cpi!=.  //Levels and growth rates are not the same.

*--->Do you know what series is used to deflate HFCE per capita?



