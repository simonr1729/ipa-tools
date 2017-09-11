*Simon Robertson 4th April 2017
program scstats
	version 14.2

	#d ;
	syntax, SCdata(str) OUTput(str) id(varname)
		/* comparison variables */
		surveylength(varname) filtervars(varlist)
		/* enumerator */
		ENUMerator(varname)
	;
	#d cr
	
	*save main dataset
	tempfile main_whole
	qui save `main_whole', replace
	*reduce and save main dataset
	tempfile main
	keep `id' `enumerator' `surveylength' `filtervars'
	qui save `main', replace

	*open spotcheck data and remove duplicates
	tempfile spotcheck
	qui insheet using "`scdata'", comma clear n case
	qui duplicates drop `id', force
	qui save `spotcheck', replace

	*merge datasets together
	use `main', clear
	qui merge 1:1 `id' using `spotcheck'

	*error if there are spotcheck id's without surveys.
	qui count if _merge == 2 
	if `r(N)' > 0 {
		di as err "id's in spotcheck with no survey:"
		list `id' if _merge == 2
		ex 198
	}

	gen spotchecked = _merge == 3
	drop _merge

	****generate stats****	

	*generate matrix of survey totals and spotcheck totals for each enumerator
	sort `enumerator'
	preserve
		gen num = 1
		collapse (sum) num spotchecked, by(`enumerator')
		qui keep if num > 5
		mkmat num spotchecked, matrix(D) rownames(`enumerator')
	restore

	*generate matrix of mean differences and p-values.
	cap matrix drop A 
	cap matrix drop B
	qui levelsof `enumerator', local(levels)
	local dim_j = 1
	foreach enum of local levels {
		qui count if `enumerator' == `enum'
		if `r(N)' > 5 	{
			local dim_i = 1
			foreach var of var `surveylength' `filtervars' {
				global var_`dim_i' = "`var'"
				qui reg `var' spotchecked if `enumerator' == `enum'
				local tot `e(N)'
				local pweight = round((2 * ttail(e(df_r), abs(_b[spotcheck]/_se[spotcheck]))), 0.001)
				mat b = e(b)
				local dif = round(_b[spotchecked], 0.01)
				if `dim_i' == 1 {
					matrix A = [`dif', `pweight'] 	
					matrix colnames A = "Difference" "Probability"
				}
				else {
					matrix C = [`dif', `pweight']
					matrix colnames C = "Difference" "Probability"
					matrix A = A,C
				}
				local dim_i = `dim_i'+1
			}
			if `dim_j' == 1 {
				matrix B = A 
			}
			else {
				matrix B = B\A
			}	
		local dim_j = `dim_j'+1
		}
	}
	matrix B = D,B
	*matrix list B

	****exporting to excel****
	qui putexcel set "`output'", replace

	*place the matrix of results
	qui putexcel A2=matrix(B), names

	*format cells and add column titles
	forvalues i = 1/`dim_i' {
		local num1 =  2*`i' 
		local num2 =  2*`i'+1 
		qui numtocol `num1'
		local col1 `r(col)'
		qui numtocol `num2'
		if `i'!= 1 qui putexcel `col1'1:`r(col)'1, merge hcenter font(Calibri, 11 bold)
		qui putexcel `col1'2:`r(col)'2, border("bottom", "medium", "black")
		local dim_j_plus = `dim_j'+1
		qui putexcel `r(col)'1:`r(col)'`dim_j_plus', border("right", "thin", "black")
		mata: b=xl()
		mata: b.load_book("`output'")
		mata: b.set_column_width(`num1', `num2', 10)
		local t= `i'-1
		qui putexcel `col1'1 = "${var_`t'}"
	}

	qui putexcel A1:A2, merge hcenter font(Calibri, 11 bold) txtwrap
	qui putexcel A1 = "Enumerator ID"
	qui putexcel B1:B2, merge hcenter font(Calibri, 11 bold) txtwrap
	qui putexcel B1 = "Total Surveys"
	qui putexcel C1:C2, merge hcenter font(Calibri, 11 bold) txtwrap
	qui putexcel C1 = "Total Spotchecks"
	qui putexcel A1:A`dim_j_plus', border("right", "thin", "black")
	qui putexcel A2:C2, border("bottom", "medium", "black")


	mata: b=xl()
	mata: b.load_book("`output'")
	mata: b.set_column_width(1, 1, 12)
	mata: b.set_column_width(2, 3, 10)


	*colour the cells using thresholds
	forvalues i = 1/`dim_i' {
		forvalues j = 1/`dim_j' {
			local i_2 = 2*`i'+2
			local p = B[`j', `i_2']
			local num1 = `i_2'+1
			local num2 = `j'+2
			qui numtocol `num1'
			if `p' < 0.05 & `p'!=. qui putexcel `r(col)'`num2':`r(col)'`num2', fpattern(solid , orange) 
			if `p' < 0.01 & `p'!=. qui putexcel `r(col)'`num2':`r(col)'`num2', fpattern(solid , red) 
		}
	}

	*restore main dataset.
	use `main_whole', clear

end

*************************************************************************

/*This program takes an integer as input and saves as local `r(col)' the excel 
alphabetic column name with that integer coordinate. i.e. 1 -> A, 2-> B, 27 -> AA. 
Works up to 26^2.
It also displays the column name.*/

program define numtocol, rclass
args num

	local x=mod(`num',26)
	if `x'==0 local x = 26
	local y=floor(`num'/26)
	if `y' == `num'/26 & `y'!=0 local y = `y'-1
	local 0 
	forvalues i = 1/26 {
		local `i' = char(64+`i')
	}
	di "``y''``x''"
	return local col = "``y''``x''"
end
