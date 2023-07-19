-- cleaning
-- we first need to clean the data. before downloading the data,
-- I excluded the Occuaption type since there's a large quantity
-- of blanks spaces making it unrialble.

select count(*) from application_record

ALTER TABLE application_record
DROP COLUMN FLAG_MOBIL;

ALTER TABLE application_record
DROP COLUMN FLAG_WORK_PHONE;

ALTER TABLE application_record
DROP COLUMN FLAG_PHONE;

ALTER TABLE application_record
DROP COLUMN FLAG_EMAIL;


-- this code checks to see if there's any dupplicate ID in the table "application_record"
-- and then returns the ID where there are multiple ID.
select ID, count(*) from application_record
group by ID
having count(*)>1
-- The rows with duplicate ID need to be deleted; however, when trying to delete the duplicate
-- an error is given because we can't modify a table that is within the query.
-- in order to go around this problem a cte is created in order to by pass this problem,
-- the dup_cte also identifies the rows with duplicate as labels it as dupcount.

CREATE TEMPORARY TABLE temp_table AS (
    SELECT ID,
           ROW_NUMBER() OVER (PARTITION BY ID ORDER BY ID) AS dupcount
    FROM application_record
);
-- now that the same table is not being reference in the subquery, sql allows us to delete
-- from the duplicates from the  original table.
DELETE FROM application_record
WHERE ID IN (
    SELECT ID
    FROM temp_table
    WHERE dupcount > 1
)

SET SQL_SAFE_UPDATES = 0
-- When viewing the data, I noticed that in 3 of the columns there were data that seems
-- weird.CNT_FAM_MEMBERS,CNT_CHILDREN, and AMT_INCOME_TOTAL. In order to check for outstanding
-- outliers. if the data is not within the 95% of standard diviation, where going to excluded it.
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
-- the following code deletes the outstanding liars for the following columns AMT_INCOME_TOTAL,CNT_CHILDREN, and CNT_FAM_MEMBERS,
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
