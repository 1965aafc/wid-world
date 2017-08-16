
import excel "$wid_dir/Country-Updates/Spain/2017/Spain_WID.world.xlsx", clear

// Drop personal and non-profit sector
drop AD-BO

// Clean
renvars, map(strtoname(@[3]))
drop if _n<4
destring _all, replace
rename WID_code year
dropmiss, force

// Change units
foreach var of varlist m*{
replace `var'=`var'*1000000000
}
foreach var of varlist n*{
replace `var'=`var'*1000
}

// Reshape
ds year, not
renvars `r(varlist)', pref(value)
reshape long value, i(year) j(widcode) string
drop if mi(value)
gen iso="ES"
generate currency = "EUR" if inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
gen p="pall"

drop if widcode=="inyixx999i"

levelsof widcode, local(levels)

tempfile spain
save "`spain'"

// Create metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = `"[URL][URL_LINK][/URL_LINK]"' ///
	+ `"[URL_TEXT]Artola Blanco M.; Bauluz L.E. and Martinez-Toledano C. (2017). "' ///
	+ `"Wealth in Spain, 1900 - 2014: A country of two lands[/URL_TEXT][/URL]; "'
generate method = ""
tempfile meta
save "`meta'"

// Add data to WID
use "$work_data/add-russian-data-output.dta", clear
append using "`spain'"

label data "Generated by add-spanish-data.do"
save "$work_data/add-spanish-data-output.dta", replace

// Add metadata
use "$work_data/add-russian-data-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-spanish-data.do"
save "$work_data/add-spanish-data-metadata.dta", replace





