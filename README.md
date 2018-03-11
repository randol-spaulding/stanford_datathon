# 2018 Stanford Datathon submission

The data is built and exported to csv files by running build_data.m. The same data is then fit to the logistic model in model.m, which exports as two tables

In policy_data.csv, we list out the policy types enacted by each state from 2014-2016 horizontally. It's organized this way for easy code formatting.

The following policy types were accounted for
* Prescription Drug Monitoring Programs
* Prescribing Guidelines and Limits
* Provider Education or Training
* Rescue Drugs (i.e., Naloxone)
* Pain Clinics and Pain Management
* Legislative and Administrative Programs


In optimal_policies.csv, we show which policies were enacted by each state in the year prior to their greatest decrease in overdose mortality rates.

In final_model_B and final_model_P, we provide a measure of relation between each policy case and the following predictors:
* Mental health providers
* Unemployment
* Income inequality
* Violent crime
* Injury deaths
* Severe housing value
* Percent uninsured
* Healthcare cost
* Median income
* Residential segregation, white/non-white
* Population size
* Population living in rural area

The B values provide a measure of correlation, while P values provide the correlation's effectiveness.
