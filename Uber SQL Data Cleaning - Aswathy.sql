-- Create a new database for the analysis
create database uber_analysis;
use uber_analysis;
select * from uber_request_data;

-- Update the columns to datetime formats
Alter table uber_request_data
add column  request_time datetime,
add column drop_time datetime,
add column response_time int;

--  Update 'request_time' by parsing 'Request timestamp' string
Update uber_request_data
set response_time = case
    when drop_time is null then null
    when timestampdiff(minute, request_time, drop_time) < 0 then null 
    else timestampdiff(minute, request_time, drop_time)
end;

-- Similarly,  Update 'drop_time' with converted date, handling different formats
Update uber_request_data
set request_time = case
    when `Request timestamp` like '%/%' then 
        str_to_date(`Request timestamp`, '%m/%d/%Y %H:%i')
    when `Request timestamp` like '%-%' then -- checking if format is day-month-year
        str_to_date(`Request timestamp`, '%d-%m-%Y %H:%i:%s')
    else
        null -- handling unexpected formats
end
where `Request timestamp` is not null;

-- Set 'drop_time' to NULL where 'Status' indicates trip was canceled or no driver found
Update uber_request_data
set drop_time = case
    when `Drop timestamp` like '%NA%' or `Drop timestamp` is null then null
    when `Drop timestamp` like '%-%' then
        str_to_date(`Drop timestamp`, '%d-%m-%Y %H:%i:%s')
    when `Drop timestamp` like '%/%' then
        str_to_date(`Drop timestamp`, '%m/%d/%Y %H:%i')
    else null
end;

-- Calculate response time in minutes
Update uber_request_data
set response_time = case
    when drop_time is null then null
    when timestampdiff(minute, request_time, drop_time) = 0 then null
    else timestampdiff(minute, request_time, drop_time)
end;

-- Dropping timestamp columns in text format
Alter table uber_request_data
drop column `Request timestamp`,
drop column `Drop timestamp`;

-- Verify the table
select * from uber_request_data;

-- Checking for descripancies
-- There are negative values in response time indicating 
-- There are drop times less than request time
Select * from uber_request_data where drop_time < request_time;

-- this happened due to the problems while entering the data, updating the dates to correct this
Update uber_request_data
set request_time = STR_TO_DATE(
  CONCAT(
    '2016-07-12 ', 
    date_format(request_time, ' %H:%i:%s')
  ),
  '%Y-%m-%d %H:%i:%s'
)
where request_time > drop_time;

-- Some response times were greater than 4000
select * from uber_request_data where response_time >1000;
-- Correcting this, by adjusting the dates
Update uber_request_data
set drop_time = str_to_date(
  concat(
    '2016-11-08 ',
    time_format(drop_time, '%H:%i:%s') 
  ),
  '%Y-%m-%d %H:%i:%s'
)
where response_time > 1000;

-- Creating additional columns by splitting date and hour of request and drop times
Alter table uber_request_data
add column request_date date,
add column request_time_hhmm varchar(5),
add column drop_date date,
add column drop_time_hhmm varchar(5);

Update uber_request_data
set
  request_date = date(request_time),
  request_time_hhmm = date_format(request_time, '%H:%i'),
  drop_date = date(drop_time),
  drop_time_hhmm = date_format(drop_time, '%H:%i');
  
select * from uber_request_data;

-- Handling missing values for Driver Id by setting NA as 0
-- Also, converting it to int format
Update uber_request_data
set `Driver id` = 0
where `Driver id` = 'NA';
Alter table uber_request_data
modify `Driver id` int;

/* The null values in date columns were kept as such
considering it won't affect the analysis */

/* Further analysis will be done in Excel and Python */









