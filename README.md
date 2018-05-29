# **scstats**

scstats is a simple way of using spotcheck data determine how similar the data collection of enumerators is when they are being observed to when they are not being observed. In particular the command compares the mean values of any set of numerical variables and calculates the p-value of a 2-sided t-test with null hypothesis that the true means are the same. i.e. you testing to see whether there is an spotcheck effect.

## **Syntax:**
scstats, scdata(filepath) output(filepath) id(varname) enumerator(varname) surveylength(varname) filtervars(varlist) 
## **where:**
scdata() takes the file path of a csv file contain (among its variables) a list of all id’s that have been spotchecked. It will run an error if this list contains id’s not in the main data.
Output() takes the suggested file path and name of the output excel file that scstats produces.
Id() takes the survey unique identifier. This must be the same in the main dataset and the spotcheck csv file.
Surveylength() takes the variable containing the survey duration (as numeric) in the main dataset.
Filtervars() takes any list of numeric variables. One use I had in mind was to use binary filter variables.
Enumerator() takes the variable enumerator identifier. Must be numeric.
## **Instructions:**
When running the command you must have the main survey dataset open in Stata. The main dataset must not contain any duplicate id’s and the enumerator variable must not contain missing values.
## **Outputs:**
Scstats produces an excel file containing a list of each enumerator ID in the first column. Then for each variable specified in surveylength and filtervars, the excel contains the difference in means between the spotchecked and non-spotchecked samples, for each enumerator and the p-value associated with this difference under the null that the means are the same.
The excel is then formatted so that p-values under 0.1 are coloured in orange, and p-values under 0.01 are coloured under 0.01.
Interpretation:
For survey length I suspect that even with small sample sizes you will find that spotchecked surveys are longer. Then outputs gives the RA/FM evidence for just how much shorter the non-spotchecked surveys are.
For filter questions, the output gives compelling evidence that the enumerator may be fabricating results to reduce the length of surveys. This though, like the survey length evidence, is based on a few assumptions:
1.	The respondents that are spotchecked are like the respondent that are non-spotchecked. We might not expect the mean values to be the same if the spotchecked households have particular characteristics, for example closer to the nearest IPA office.	

A good practice might be to have FMs/AFMs/SFOs/Teamleaders randomize their daily spotchecks. They could draw an enumerator from a hat each day to select the sample.

You also want to have your spotchecks for each enumerator spread out over time. If, say, you have collected data in one area for a month, and then having moved to a new area this week you spotcheck an enumerator every day, you may well see differences in means. But this could just be driven by the change in area, rather than the any spotcheck effect.

2.	You need the respondents that are spotchecked to act the same as the non-spotchecked respondents. This is the trickiest part to prove. It could be the case that respondents give different answers when they know someone else’s supervisor is present. Respondents themselves may sometimes want to say “no” to filter questions to complete the interview more quickly. Would they be less inclined to do this when a supervisor is present? Difficult to say.
## **Improvements:**
•	Currently the stats are calculated using n*m regressions, where n is number of enumerators and m is number of filter variables. Since the stats are simple it would probably be computationally better to just us some bysort commands rather than making Stata compute all the other regression results. It does however allow the possibility of including covariates to increase statistical power.
•	Haven’t included enumerator names, only id’s.
•	Need to not have any duplicate id’s in the main or spotcheck data.
•	Could add a “by” command so that they outputs can be split. By region for example.
•	Requires Stata version 14.2. I had some fun using the new formatting options with putexcel. There was probably a way around this using mata. Putexcel still doesn’t let you change cell widths but you can do it using mata. You can probably do all the other formatting with mata I would think.
•	Should allow user to set the thresholds. And the colours? Or just switch the formatting off.
•	T-test is two sided. Could make it one sided under the assumption that enumerators only willfully make the collection shorter.
•	Allow variable labels along the top row of the output rather than just variable names.
