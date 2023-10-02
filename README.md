# Credit project
The purpose of this project is to create a machine learning model that can studies the data of current customer to see if a new customer would be consider a good or bad potential customers. For this project, two dataset were provided for this project. The first data set contained personal information about the clients demographics. The second dataset contained information about the payment history (late payments if any). 
## Process
In this project, I cleaned the data in SQL by ommiting information that would not be affect the data machine ex. email address,phone number, etc. Then, I removed any outstanding outliers that can affect the data ex. 20 dependents. I condense the payment dataset to return the most reacurring payment type (late or on time), and then combine both datasets through the customers ID. Exported clean data into python in order to create a machine learning model. This model would look at 70% of the data to study it and would use the remaining 30% to compare the accuracy of the prediction base on the data it study.

## This repository contains 2 files:
Cleaning code in SQL: The code that was use in SQL to clean and transform the data for the learning machine model.
Machine learning code in Python: This code contains the process of using the data to create a learning machine model.
