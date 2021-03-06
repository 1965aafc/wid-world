import excel "$country_codes/country-codes.xlsx", clear firstrow

keep if shortname != ""
rename code iso

// Countries only
preserve
drop if inrange(iso, "QB", "QZ") | iso == "WO" | iso == "XM"
label data "Generated by import-country-codes.do"
save "$work_data/import-country-codes-output.dta", replace
restore

// Regions
preserve
keep if inrange(iso, "QB", "QZ") | inlist(iso,"XA","XF","XL","XM","XN","XR") | iso == "WO"
keep iso titlename shortname
label data "Generated by import-country-codes.do"
save "$work_data/import-region-codes-output.dta", replace
restore
