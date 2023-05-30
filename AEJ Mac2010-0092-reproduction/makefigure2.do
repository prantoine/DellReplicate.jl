clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close
cd "/Users/pantoine/code/school_code/m2/comp_econ/term_project/dell-replicate/AEJ Mac2010-0092-reproduction"

 global rfe = 1 /*1 for region*year, 2 for year only*/

 global maineffectsonly = 0 /*1 to drop all interactions*/

	use climate_panel, clear
	  
	* restrict to 2003
	keep if year <= 2003
		
	encode parent, g(parent_num)
		
	encode fips60_06, g(cc_num)
	sort country_code year
	tsset cc_num year
	
	g lngdpwdi = ln(gdpLCU)
	g lgdppwt=ln(rgdpl)
	
	*calculate GDP growth (WDI)
	gen temp1 = l.lngdpwdi
	gen g=lngdpwdi-temp1
	replace g = g * 100 
	drop temp1
	summarize g

	*calculate GDP growth (PWT)
	gen temp1 = l.lgdppwt
	gen gpwt=lgdppwt-temp1
	replace gpwt = gpwt * 100 
	drop temp1
	summarize gpwt
		
	g lnag = ln(gdpWDIGDPAGR) 
	g lnind = ln(gdpWDIGDPIND) 
		g lninvest = ln(rgdpl*ki/100)
	
	foreach X in ag ind gdpwdi invest {
		g g`X' = (ln`X' - l.ln`X')*100
	}


		
	* Drop if less than 20 yrs of GDP data
	g tempnonmis = 1 if g != .
	replace tempnonmis = 0 if g == .
	bys fips60_06: egen tempsumnonmis = sum(tempnonmis)
	drop if tempsumnonmis  < 20
		
	* Make sure all subcomponents are non-missing in a given year
	g misdum = 0
	for any ag ind : replace misdum = 1 if gX == .
	for any ag ind : replace gX = . if misdum == 1

	
	preserve
	keep if lnrgdpl_t0 < . 
	bys fips60_06: keep if _n == 1 
	xtile initgdpbin = ln(lnrgdpl_t0), nq(2)
	keep fips60_06 initgdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	//mmerge fips60_06 using `tempxtile', type(n:1)
	merge m:1 fips60_06 using `tempxtile'
	//drop merge for next ones (added by Pol)
	drop _merge
	tab initgdpbin, g(initxtilegdp)
	
	
	preserve
	keep if wtem50 < . 
	bys fips60_06: keep if _n == 1 
	xtile initwtem50bin = wtem50 , nq(2)
	keep fips60_06 initwtem50bin
	save `tempxtile',replace
	restore
	
	//mmerge fips60_06 using `tempxtile', type(n:1)
	merge m:1 fips60_06 using `tempxtile'
	//drop merge for next ones (added by Pol)
	drop _merge
	tab initwtem50bin, g(initxtilewtem)
	
	preserve
	keep if year == 1995
	sort fips60_06 year
	//redundant: omitted in julia !
	by fips60_06: keep if _n == 1
	
	g temp = gdpSHAREAG 
	*replace temp = ag_share0 if temp == .
	xtile initagshare1995 = ln(temp), nq(2)
	replace initagshare1995 = . if gdpSHAREAG == .
	keep fips60_06 initagshare1995 
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab initagshare1995 , g(initxtileagshare)
	
	
	tsset
	
	
	
	foreach Y in wtem wpre  {
		gen `Y'Xlnrgdpl_t0 =`Y'*lnrgdpl_t0 
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xlnrgdpl_t0 "`Y'.*inital GDP pc"
		for var initxtile*: label var `Y'_X "`Y'* X"
	}

	capture {
		for var wtem* wpre*: g fdX = X - l.X \ label var fdX "Change in X"
		for var wtem* wpre*: g L1X = l1.X 
		for var wtem* wpre*: g L2X = l2.X 
		for var wtem* wpre*: g L3X = l3.X 
		for var wtem* wpre*: g L4X = l4.X 
		for var wtem* wpre*: g L5X = l5.X 
		for var wtem* wpre*: g L6X = l6.X 
		for var wtem* wpre*: g L7X = l7.X 
		for var wtem* wpre*: g L8X = l8.X 
		for var wtem* wpre*: g L9X = l9.X 
		for var wtem* wpre*: g L10X = l10.X
		 
	}
	
		tab year, gen (yr)
	local numyears = r(r) - 1
	
	
	if $rfe == 1 {
		foreach X of num 1/`numyears' {
				foreach Y in MENA SSAF LAC WEOFF EECA SEAS {
					quietly gen RY`X'X`Y'=yr`X'*_`Y'
					quietly tab RY`X'X`Y'
				}
				quietly gen RYPX`X'=yr`X'*initxtilegdp1
			}
	}
	else if $rfe == 2 {
		foreach X of num 1/`numyears' {
				quietly gen RY`X'=yr`X'
				
			}
	}


	* create mean temperatures for different time periods
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp50sX = mean(X) if year >= 1951 & year <= 1960 \ bys fips60_06: egen mean50sX = mean(temp50sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp60sX = mean(X) if year >= 1961 & year <= 1970 \ bys fips60_06: egen mean60sX = mean(temp60sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp70sX = mean(X) if year >= 1971 & year <= 1980 \ bys fips60_06:  egen mean70sX = mean(temp70sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp80sX = mean(X) if year >= 1981 & year <= 1990 \ bys fips60_06:  egen mean80sX = mean(temp80sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp90sX = mean(X) if year >= 1991 & year <= 2000 \ bys fips60_06:  egen mean90sX = mean(temp90sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp00sX = mean(X) if year >= 1994 & year <= 2003 \ bys fips60_06: egen mean00sX = mean(temp00sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp84sX = mean(X) if year >= 1984 & year <= 1993 \ bys fips60_06: egen mean84sX = mean(temp84sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp64sX = mean(X) if year >= 1964 & year <= 1973 \ bys fips60_06: egen mean64sX = mean(temp64sX)
	
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp7085X = mean(X) if year >= 1970 & year <= 1985 \ bys fips60_06: egen mean7085X = mean(temp7085X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp8600X = mean(X) if year >= 1986 & year <= 2000 \ bys fips60_06: egen mean8600X = mean(temp8600X)	
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp7086X = mean(X) if year >= 1970 & year <= 1986 \ bys fips60_06: egen mean7086X = mean(temp7086X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp8703X = mean(X) if year >= 1987 & year <= 2003 \ bys fips60_06: egen mean8703X = mean(temp8703X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp7087X = mean(X) if year >= 1970 & year <= 1987 \ bys fips60_06: egen mean7087X = mean(temp7087X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp8803X = mean(X) if year >= 1988 & year <= 2003 \ bys fips60_06: egen mean8803X = mean(temp8803X)

	
	for var wtem wpre g gpwt gag gind ginvest : g change0050sX = mean00sX - mean50sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0060sX = mean00sX - mean60sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0070sX = mean00sX - mean70sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0080sX = mean00sX - mean80sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0090sX = mean00sX - mean90sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g change9050sX = mean90sX - mean50sX 
	for var wtem wpre g gpwt gag gind ginvest : g change9060sX = mean90sX - mean60sX 
	for var wtem wpre g gpwt gag gind ginvest : g change9070sX = mean90sX - mean70sX 
	for var wtem wpre g gpwt gag gind ginvest : g change9080sX = mean90sX - mean80sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g change8450sX = mean84sX - mean50sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8460sX = mean84sX - mean60sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8470sX = mean84sX - mean70sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8480sX = mean84sX - mean80sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8490sX = mean84sX - mean90sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g change0064sX = mean00sX - mean64sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g changeS1X = mean8600X - mean7085X 
	for var wtem wpre g gpwt gag gind ginvest : g changeS2X = mean8703X - mean7086X 	
	for var wtem wpre g gpwt gag gind ginvest : g changeS3X = mean8803X - mean7087X 	
	
	for var change*: g Xxtilegdp1 = X * initxtilegdp1
	
	for var change*wtem: label var X "Change in tem"
	for var change*wpre: label var X "Change in pre"
	for var change*wtemxtilegdp1: label var X "Change in tem * poor"
	for var change*wprextilegdp1: label var X "Change in pre * poor"
	
	keep if year==2003
	save temp, replace
	
	************
	* Comparing 1986-2000 to 1970-1985 (SPLIT 1)
	************
	
	* Column 1: no Region fixed effect 
	
	use temp, clear
	keep if initxtilegdp1==1
		
	regress changeS1g changeS1wtem, robust
	predict xb
	predict se, stdp
	g cplus=xb+1.96*se
	g cminus=xb-1.96*se
	
	twoway (scatter changeS1g changeS1wtem if initxtilegdp1==1, msymbol(o) msize(small) mcolor(gs0) mlabel(country_code) /*mlabv(pos)*/ mlabsize(small)) (connected xb changeS1wtem, sort msymbol(none) clcolor(black) clpat(solid) clwidth(thin)) (connected cplus changeS1wtem, sort msymbol(none) clcolor(gs7) clpat(solid) clwidth(thin)) (connected cminus changeS1wtem, sort msymbol(none) clcolor(gs7) clpat(solid) clwidth(thin)), legend(off) ytitle("Change in growth") xtitle("Change in temperature") title("A. Poor countries", size(large)) graphregion(color(white)) ylab(-10(5)10, nogrid) ysc(r(-10 10)) xlab(-0.5(.5)1) xsc(r(-0.5 1)) yline(0, lpattern(shortdash) lc(gs7)) saving(Fig2a.gph,replace)
	graph export Fig2a.eps, replace
	
	use temp, clear
	keep if initxtilegdp1==0
		
	regress changeS1g changeS1wtem, robust
	predict xb
	predict se, stdp
	g cplus=xb+1.96*se
	g cminus=xb-1.96*se
	
	twoway (scatter changeS1g changeS1wtem if initxtilegdp1==0, msymbol(o) msize(small) mcolor(gs0) mlabel(country_code) /*mlabv(pos)*/ mlabsize(small)) (connected xb changeS1wtem, sort msymbol(none) clcolor(black) clpat(solid) clwidth(thin)) (connected cplus changeS1wtem, sort msymbol(none) clcolor(gs7) clpat(solid) clwidth(thin)) (connected cminus changeS1wtem, sort msymbol(none) clcolor(gs7) clpat(solid) clwidth(thin)), legend(off) ytitle("Change in growth") xtitle("Change in temperature") title("B. Rich countries", size(large)) graphregion(color(white)) ylab(-10(5)10, nogrid) ysc(r(-10 10)) xlab(-0.5(.5)1) xsc(r(-0.5 1)) yline(0, lpattern(shortdash) lc(gs7)) saving(Fig2b.gph,replace)
	graph export Fig2b.eps, replace
	
	
gr combine Fig2a.gph Fig2b.gph, rows(2) xsize(7) ysize(10) iscale(*.75)
graph export Fig2.eps, replace
	