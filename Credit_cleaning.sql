-- cleaning
-- We first need to clean the data. before downloading the data,
-- I excluded the Occupation type since there's a large quantity
-- of blank spaces making it unusable.

select count(*) from application_record

ALTER TABLE application_record
DROP COLUMN FLAG_MOBIL;

ALTER TABLE application_record
DROP COLUMN FLAG_WORK_PHONE;

ALTER TABLE application_record
DROP COLUMN FLAG_PHONE;

ALTER TABLE application_record
DROP COLUMN FLAG_EMAIL;


-- this code checks to see if there's any duplicate ID in the table "application_record"
-- and then returns the ID where there are multiple ID.
select ID, count(*) from application_record
group by ID
having count(*)>1
-- The rows with duplicate ID need to be deleted; however, when trying to delete the duplicate
-- an error is given because we can't modify a table that is within the query.
-- In order to go around this problem a cte is created in order to bypass this problem,
-- the dup_cte also identifies the rows with duplicate and labels it as dupcount.

CREATE TEMPORARY TABLE temp_table AS (
    SELECT ID,
           ROW_NUMBER() OVER (PARTITION BY ID ORDER BY ID) AS dupcount
    FROM application_record
);
-- Now that the same table is not being referenced in the subquery, SQL allows us to delete
-- from the duplicates from the  original table.
DELETE FROM application_record
WHERE ID IN (
    SELECT ID
    FROM temp_table
    WHERE dupcount > 1
)

SET SQL_SAFE_UPDATES = 0
-- When viewing the data, I noticed that in 3 of the columns, there were data that seems
-- weird.CNT_FAM_MEMBERS,CNT_CHILDREN, and AMT_INCOME_TOTAL. In order to check for outstanding
-- outliers. if the data is not within 95% of the standard deviation, where going to exclude it.
select * from (
select CNT_CHILDREN, 
(CNT_CHILDREN - AVG(CNT_CHILDREN) over())/stddev(CNT_CHILDREN) over() as Zscore
from application_record
group by CNT_CHILDREN) score_table
where Zscore >1.96 or  Zscore < -1.96

select * from (
select AMT_INCOME_TOTAL, 
(AMT_INCOME_TOTAL - AVG(AMT_INCOME_TOTAL) over())/stddev(AMT_INCOME_TOTAL) over() as Zscore
from application_record
group by AMT_INCOME_TOTAL) score_table
where Zscore >1.96 or  Zscore < -1.96

select * from (
select CNT_FAM_MEMBERS, 
(CNT_FAM_MEMBERS - AVG(CNT_FAM_MEMBERS) over())/stddev(CNT_FAM_MEMBERS) over() as Zscore
from application_record
group by CNT_FAM_MEMBERS) score_table
where Zscore >1.96 or  Zscore < -1.96
-- the following code deletes the outstanding liars for the following columns AMT_INCOME_TOTAL, CNT_CHILDREN, and CNT_FAM_MEMBERS,
DELETE FROM application_record
WHERE AMT_INCOME_TOTAL IN (
    SELECT AMT_INCOME_TOTAL
    FROM (
        SELECT AMT_INCOME_TOTAL,
               (AMT_INCOME_TOTAL - AVG(AMT_INCOME_TOTAL) OVER ()) / STDDEV(AMT_INCOME_TOTAL) OVER () AS Zscore
        FROM application_record
        GROUP BY AMT_INCOME_TOTAL
    ) score_table
    WHERE Zscore > 1.96 OR Zscore < -1.96
);

DELETE FROM application_record
WHERE CNT_CHILDREN IN (
    SELECT CNT_CHILDREN
    FROM (
        SELECT CNT_CHILDREN,
               (CNT_CHILDREN - AVG(CNT_CHILDREN) OVER ()) / STDDEV(CNT_CHILDREN) OVER () AS Zscore
        FROM application_record
        GROUP BY CNT_CHILDREN
    ) score_table
    WHERE Zscore > 1.96 OR Zscore < -1.96
);

DELETE FROM application_record
WHERE CNT_FAM_MEMBERS IN (
    SELECT CNT_FAM_MEMBERS
    FROM (
        SELECT CNT_FAM_MEMBERS,
               (CNT_FAM_MEMBERS - AVG(CNT_FAM_MEMBERS) OVER ()) / STDDEV(CNT_FAM_MEMBERS) OVER () AS Zscore
        FROM application_record
        GROUP BY CNT_FAM_MEMBERS
    ) score_table
    WHERE Zscore > 1.96 OR Zscore < -1.96
);
-- application records is now clean that we removed any outstanding outliers, removed columns that we couldn't use, and remove duplicate ID.


-- drops table if made. This is helpful to see how created tables are being affected without altering the original table.
Drop table if exists Table2
Drop table if exists credit_alt 

-- Creates a table that will be a copy of the Credit_record table. I created this table to make changes without losing data.
create table Table2(
ID int, 
Months int,
AStatus text
)
-- insterts the data of the original table into the copy table(Table2)
insert into Table2 (ID, Months, AStatus)
select ID, MONTHS_BALANCE, STATUS
from credit_record 

-- Status tells us how late if late dept payments are made. If customers paid on time, didn't use the card, or were late than 30 days(no effect on card)
-- they were labeled as 0 (good customer). If they were over 30 days( bad customers) they were labeled as 1.
update Table2 
set AStatus = case
when AStatus = 'X' then '0'
when AStatus = 'C' then '0'
when AStatus = '2' then '1'
when AStatus = '3' then '1'
when AStatus = '4' then '1'
when AStatus = '5' then '1'
else AStatus
end;
-- The table provides the status of the customer for each month. Depending on the customers, customers have multiple input for status depending 
-- on the months they have been a customer. In order to assign one specific number to the customers, I decided to assign the status that 
-- shows more frequently. The following code looks at the table and returns the row that appeared the most assigning that number to the customer ID.
SELECT t.ID, t.AStatus, t.frequency
FROM (
    SELECT ID, AStatus, COUNT(*) AS frequency,
           ROW_NUMBER() OVER (PARTITION BY ID ORDER BY COUNT(*) DESC) AS rn
    FROM Table2
    GROUP BY ID, AStatus
) t
WHERE t.rn = 1
ORDER BY t.ID;

-- Create a new table since that will be joined with the application_records. This table will only have the ID(in order to join the table) and 
-- Pay_delay.
create table credit_alt(
ID int, 
pay_delay int
) 
-- inserting the data of table 2.
insert into credit_alt (ID, pay_delay)
SELECT t.ID, t.AStatus
FROM (
    SELECT ID, AStatus, COUNT(*) AS frequency,
           ROW_NUMBER() OVER (PARTITION BY ID ORDER BY COUNT(*) DESC) AS rn
    FROM Table2
    GROUP BY ID, AStatus
) t
WHERE t.rn = 1
ORDER BY t.ID;

-- Joins both tables. This becomes the final clean table of the data. Now it's ready to analyze.
SELECT application_record.ID, CODE_GENDER, FLAG_OWN_CAR,FLAG_OWN_REALTY,CNT_CHILDREN, AMT_INCOME_TOTAL, NAME_INCOME_TYPE, NAME_EDUCATION_TYPE,NAME_FAMILY_STATUS,NAME_HOUSING_TYPE,DAYS_BIRTH,DAYS_EMPLOYED,CNT_FAM_MEMBERS,pay_delay
FROM application_record
JOIN credit_alt ON application_record.ID = credit_alt.ID;
 










  














