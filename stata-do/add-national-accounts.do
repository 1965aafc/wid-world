use "$work_data/national-accounts.dta", clear

generate p = "pall"

tempfile natacc
save "`natacc'"

use "$work_data/add-price-index-output.dta", clear

generate newobs = 0
append using "`natacc'"
replace newobs = 1 if (newobs >= .)

// Make a list of countries with duplicates to remove them from the metadata
duplicates tag iso widcode p year, generate(duplicate)
preserve
keep if duplicate
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
tempfile duplicates_iso
save "`duplicates_iso'"
restore
drop if duplicate & !newobs
drop duplicate newobs

label data "Generated by add-national-accounts.do"
save "$work_data/add-national-accounts-output.dta", replace

keep if inlist(widcode, "mnninc999i", "mgdpro999i", "mconfc999i", "mnnfin999i")
reshape wide value, i(iso p year) j(widcode) string

generate delta = abs((valuemgdpro999i - valuemconfc999i + valuemnnfin999i - valuemnninc999i)/valuemnninc999i)
assert delta < 1e-6 if !missing(delta)

// Correct the metadata file
use "$work_data/na-metadata.dta", clear

merge n:1 iso sixlet using "`duplicates_iso'", nogenerate keep(master using)

label data "Generated by add-national-accounts.do"
save "$work_data/na-metadata-no-duplicates.dta", replace
