
use "$work_data/distribute-national-income-output.dta", clear

// -----------------------------------------------------------------------------------------------------------------
// Recompute pre-tax and post-tax averages when there is full DINA data
// -----------------------------------------------------------------------------------------------------------------

* Keep only g-percentiles
split p, parse("p")
destring p2 p3, replace force
gen diff = round((p3 - p2)*1000,1)
keep if inlist(diff, 1, 10, 100, 1000)
drop if diff==1000 & p2>=99
drop if diff==100 & p2>=99.9
drop if diff==10 & p2>=99.99
drop diff p1 p3 p
rename p2 p
replace p=round(p*1000,1)
sort iso year p widcode

* Recompute pre-tax income
preserve
	keep if substr(widcode,1,6)=="aptinc"
	bys iso year: egen num=nvals(p)
	keep if num==127
	drop num

	gen pop=0.01 if inrange(p,0,98000)
	replace pop=0.001 if inrange(p,99000,99800)
	replace pop=0.0001 if inrange(p,99900,99980)
	replace pop=0.00001 if p>99980
	gen prod=pop*value
	bys iso year: egen tot=sum(prod)
	replace value=tot

	keep iso year widcode value
	duplicates drop
	gen p="pall"
	gen new=1
	tempfile ptinc
	save "`ptinc'"
restore

* Recompute post-tax income when existing
qui count if substr(widcode,1,6)=="adiinc"
if r(N)>0{
preserve
	keep if substr(widcode,1,6)=="adiinc"
	bys iso year: egen num=nvals(p)
	keep if num==127
	drop num

	gen pop=0.01 if inrange(p,0,98000)
	replace pop=0.001 if inrange(p,99000,99800)
	replace pop=0.0001 if inrange(p,99900,99980)
	replace pop=0.00001 if p>99980
	gen prod=pop*value
	bys iso year: egen tot=sum(prod)
	replace value=tot

	keep iso year widcode value
	duplicates drop
	gen p="pall"
	gen new=1
	tempfile diinc
	save "`diinc'"
restore
}

// Replace these values in data
use "$work_data/distribute-national-income-output.dta", clear
append using "`ptinc'"
cap append using "`diinc'"
duplicates tag iso year p widcode, gen(dup)
drop if dup & new!=1
drop new dup


// -----------------------------------------------------------------------------------------------------------------
// Calibrate now pre-tax national income series and post-tax income series on national income
// -----------------------------------------------------------------------------------------------------------------

* Create coefficients for pre-tax and post-tax income
keep if inlist(substr(widcode, 1, 6), "anninc", "aptinc", "adiinc")
keep if p=="pall" | p=="p0p100"
replace p = "pall"

generate sixlet = substr(widcode, 1, 6)
generate pop = substr(widcode, 7, .)

*duplicates tag iso year sixlet value, gen(dup)
*ta iso if dup==1 & sixlet=="aptinc"

replace pop = "992i" if (pop == "992j")
keep if pop == "992i"

duplicates drop iso year sixlet pop, force

drop widcode currency

reshape wide value, i(iso year pop) j(sixlet) string

generate coefptinc = valueanninc/valueaptinc
generate coefdiinc = valueanninc/valueadiinc
drop if missing(coefptinc) & missing(coefdiinc)

keep iso year coef*
tempfile coef
save "`coef'"

* Calibrate series
use "$work_data/distribute-national-income-output.dta", clear
merge n:1 iso year using "`coef'", nogenerate

*tab widcode if substr(widcode,2,5)=="ptinc"
replace value = value*coefptinc if inlist(substr(widcode,1,6),"aptinc","optinc","tptinc","mptinc") ///
	& inlist(substr(widcode,-1,1),"j","i") & !mi(coefptinc)

*tab widcode if substr(widcode,2,5)=="diinc"
replace value = value*coefdiinc if inlist(substr(widcode,1,6),"adiinc","odiinc","tdiinc","mdiinc") ///
	& inlist(substr(widcode,-1,1),"j","i") & !mi(coefdiinc)

drop coef*

label data "Generated by calibrate-dina.do"
save "$work_data/calibrate-dina-output.dta", replace
