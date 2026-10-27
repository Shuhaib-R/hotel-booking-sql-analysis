USE kaggle;

DROP TABLE IF EXISTS hotel_bookings;

CREATE TABLE hotel_bookings (
  hotel                           VARCHAR(20),
  is_canceled                     INT,
  lead_time                       INT,
  arrival_date_year               INT,
  arrival_date_month              VARCHAR(15),
  arrival_date_week_number        INT,
  arrival_date_day_of_month       INT,
  stays_in_weekend_nights         INT,
  stays_in_week_nights            INT,
  adults                          INT,
  children                        VARCHAR(10),
  babies                          INT,
  meal                            VARCHAR(15),
  country                         VARCHAR(10),
  market_segment                  VARCHAR(20),
  distribution_channel            VARCHAR(20),
  is_repeated_guest               INT,
  previous_cancellations          INT,
  previous_bookings_not_canceled  INT,
  reserved_room_type              VARCHAR(5),
  assigned_room_type              VARCHAR(5),
  booking_changes                 INT,
  deposit_type                    VARCHAR(20),
  agent                           VARCHAR(10),
  company                         VARCHAR(10),
  days_in_waiting_list            INT,
  customer_type                   VARCHAR(20),
  adr                             DECIMAL(10,2),
  required_car_parking_spaces     INT,
  total_of_special_requests       INT,
  reservation_status              VARCHAR(20),
  reservation_status_date         VARCHAR(15)
);

#Change the path to where you saved hotel_bookings.csv
LOAD DATA LOCAL INFILE 'C:/hotel/hotel_bookings33.csv'
INTO TABLE hotel_bookings
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT COUNT(*) FROM hotel_bookings;

#🟢
#1 - Total bookings per hotel, and each hotel's share %
SELECT hotel,COUNT(*) AS 'Total_Bookings',ROUND(COUNT(*) * 100.0/ SUM(COUNT(*)) OVER(),2) AS 'Total Share Percentage' FROM hotel_bookings
GROUP BY hotel
ORDER BY Total_Bookings DESC;

#🟢
#2 - Cancellation rate % per hotel
SELECT hotel,SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END)AS 'Cancelled_bookings',
ROUND(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Cancellation_rate  FROM hotel_bookings
GROUP BY hotel
ORDER BY Cancelled_bookings DESC;

#3 - Bookings per year
SELECT arrival_date_year,COUNT(*) AS 'Bookings' FROM hotel_bookings
GROUP BY arrival_date_year
ORDER BY Bookings DESC;

#4 - Average lead time and average stay length per hotel
SELECT hotel,ROUND(AVG(lead_time),2) AS 'Average_Lead_Time',ROUND(AVG(stays_in_weekend_nights + stays_in_week_nights),2) AS 'Average_stay_length' 
FROM hotel_bookings
GROUP BY hotel;

#🟡 Part 2: Cancellations 🚫
#5 - Cancellation rate by market segment
SELECT market_segment,SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Cancelled_Bookings,
ROUND(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END)*100 / COUNT(*),2) AS Cancellation_Rate FROM hotel_bookings
GROUP BY market_segment
ORDER BY Cancellation_Rate DESC;

#6 - Cancellation rate by deposit type (any surprise here? 👀)
SELECT deposit_type,SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Cancelled_Bookings,
ROUND(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END)*100 / COUNT(*),2) AS Cancellation_Rate FROM hotel_bookings
GROUP BY deposit_type
ORDER BY Cancellation_Rate DESC;

#7 - Cancellation rate by lead-time bucket (0-30, 31-90, 91-180, 180+ days) using CASE WHEN
SELECT CASE 
WHEN lead_time <= 30 THEN '1) 0-30 Days'
WHEN lead_time <= 90 THEN '2) 30-90 Days'
WHEN lead_time <= 180 THEN '3) 90-180 Days'
ELSE '4) 180+ Days' END AS lead_time_bucket,
COUNT(*) AS 'Total_Bookings', SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Cancelled_Bookings,
ROUND(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END)*100/COUNT(*),2) AS Cancelled_Rate
FROM hotel_bookings
GROUP BY lead_time_bucket
ORDER BY lead_time_bucket;

#8 - Do repeated guests cancel less?
SELECT SUM(CASE WHEN is_repeated_guest = 1 THEN 1 ELSE 0 END) AS repeated_guest,
SUM(CASE WHEN is_repeated_guest = 0 THEN 1 ELSE 0 END) AS non_repeated_guest FROM hotel_bookings;
SELECT CASE WHEN is_repeated_guest = 0 THEN 'Non_repeated_guest'
ELSE 'repeated_guest' END AS Guests,COUNT(*) AS Bookings,SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Cancelled_Bookings,
ROUND(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END)*100/COUNT(*),2) AS Cancellation_Rate
FROM hotel_bookings
GROUP BY Guests;

#🟠 Part 3: Revenue & ADR 💰
#9 - Revenue and average ADR per hotel (non-cancelled only)
SELECT hotel,COUNT(*) AS Completed_Bookings,ROUND(SUM(adr*(stays_in_weekend_nights+stays_in_week_nights)),2) AS Total_Revenue,
ROUND(AVG(adr),2) AS Avg_adr FROM hotel_bookings
WHERE is_canceled = 0
GROUP BY hotel;

#10 - ADR by room type
SELECT hotel,reserved_room_type,COUNT(*) AS Bookings,ROUND(AVG(adr),2) AS Avg_ADR FROM hotel_bookings
WHERE is_canceled = 0 AND adr > 0
GROUP BY hotel, reserved_room_type
ORDER BY hotel,Avg_ADR DESC;

#11 - Monthly revenue with a running total
WITH Monthly AS (
SELECT arrival_date_year AS Yr,CASE arrival_date_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END AS Mnth,ROUND(SUM(adr*(stays_in_weekend_nights + stays_in_week_nights)),2) AS Monthly_Revenue 
FROM hotel_bookings
WHERE is_canceled = 0
GROUP BY yr,mnth)
SELECT Yr,Mnth,Monthly_Revenue,ROUND(SUM(Monthly_Revenue) OVER(ORDER BY Yr,Mnth),2) AS Running_Total FROM Monthly
ORDER BY Yr,Mnth;

#12 - Peak season: top 3 months by revenue per hotel (RANK)
WITH Monthly AS (
SELECT hotel,arrival_date_year AS Yr,CASE arrival_date_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END AS arrival_month,
ROUND(SUM(adr*(stays_in_weekend_nights + stays_in_week_nights)),2) AS Revenue FROM hotel_bookings
WHERE is_canceled = 0
GROUP BY hotel,arrival_date_year,arrival_month),
RANKED AS (
SELECT *,RANK() OVER(PARTITION BY hotel ORDER BY Revenue DESC) AS 'Ranks' FROM Monthly)
SELECT * FROM RANKED
WHERE Ranks <4
ORDER BY hotel,Ranks;

#13 - Weekend vs weekday revenue share
SELECT hotel,ROUND(SUM(adr*stays_in_weekend_nights),2) AS Weekend_Revenue,ROUND(SUM(adr*stays_in_week_nights),2) AS Weekday_Revenue,
ROUND(SUM(adr*stays_in_weekend_nights)*100 / SUM(adr*(stays_in_weekend_nights + stays_in_week_nights)),2) AS 'Weekend%',
ROUND(SUM(adr*stays_in_week_nights)*100 / SUM(adr*(stays_in_weekend_nights + stays_in_week_nights)),2) AS 'Weekday%' FROM hotel_bookings
WHERE is_canceled = 0
GROUP BY hotel;

#🔴 Part 4: Guests & Channels 🌍
#14 - Top 10 guest countries
SELECT country,COUNT(*) AS Total_Bookings,ROUND(COUNT(*) *100/ (SELECT COUNT(*) FROM hotel_bookings),2) AS Share_Pct FROM hotel_bookings
GROUP BY country
ORDER BY Share_Pct DESC
LIMIT 10;

#15 - Best distribution channel by revenue and cancellation rate
SELECT distribution_channel,COUNT(*) AS Bookings,SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Cancelled_Bookings,
ROUND(AVG(is_canceled)*100,2) AS Cancel_Rate,
SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_weekend_nights+stays_in_week_nights) ELSE 0 END) AS Total_Revenue,
SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_weekend_nights+stays_in_week_nights) ELSE 0 END) * 100 / 
ROUND((SELECT SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_weekend_nights+stays_in_week_nights) ELSE 0 END) FROM hotel_bookings),2) AS Revenue_Share
FROM hotel_bookings
GROUP BY distribution_channel
ORDER BY Revenue_Share DESC;

#16 - Customer type analysis (Transient, Contract, Group...)
SELECT customer_type,COUNT(*) AS Total_Bookings,
SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_weekend_nights+stays_in_week_nights) ELSE 0 END) AS Total_Revenue,
ROUND(AVG(is_canceled)*100,2) AS 'Cancel_Rate%',ROUND(AVG(lead_time),1) AS Avg_Lead_Day
,ROUND(AVG(CASE WHEN is_canceled = 0 THEN adr END),2) AS Avg_Adr
FROM hotel_bookings
GROUP BY customer_type;

#17 - Do special requests relate to a higher ADR?
SELECT total_of_special_requests,COUNT(*) AS Bookings,ROUND(AVG(CASE WHEN is_canceled = 0 THEN adr END),2) AS Avg_ADR FROM hotel_bookings
WHERE is_canceled = 0
GROUP BY total_of_special_requests
ORDER BY total_of_special_requests;

#🏆 Part 5: Interview Level
#18 - Month-over-month revenue growth % (LAG)
WITH AMT AS (
SELECT arrival_date_year,CASE arrival_date_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END AS months,SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_weekend_nights+stays_in_week_nights) ELSE 0 END) AS Total_Revenue FROM hotel_bookings
    GROUP BY arrival_date_year,months
    ORDER BY arrival_date_year,months),
    Final AS (
    SELECT *,LAG(Total_Revenue) OVER(ORDER BY arrival_date_year,months) AS Previous FROM AMT)
    SELECT arrival_date_year,months,Total_Revenue,Previous,ROUND((Total_Revenue - Previous)*100.0 / NULLIF(Previous,0),2) AS MOM_Percentage FROM Final;

#19 - Rooms where assigned ≠ reserved, and the cancellation rate for them
WITH AMT AS (
SELECT CASE WHEN reserved_room_type <> assigned_room_type THEN 'Different Room' ELSE 'Same_Room' END AS Room_Matching,
COUNT(*) AS Total_Bookings,SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_weekend_nights + stays_in_week_nights) ELSE 0 END) AS Total_Revenue,
SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Canceled_Bookings,
SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END)*100.0/ COUNT(*) AS 'Cancel_Rate%' FROM hotel_bookings
GROUP BY Room_Matching)
SELECT Room_Matching,Total_Bookings,Canceled_Bookings,Total_Revenue,`Cancel_Rate%`,ROUND(Total_Revenue * 100.0/ SUM(Total_Revenue) OVER(),2)  AS 'Share%' 
FROM AMT;

#20 - Lost revenue: estimated revenue from cancelled bookings, by month
WITH AMT AS (
SELECT arrival_date_year,CASE arrival_date_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END AS months,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Cancelled_Bookings,
    SUM(CASE WHEN is_canceled = 1 THEN adr * (stays_in_weekend_nights+stays_in_week_nights) ELSE 0 END) AS Lost_Revenue,
    SUM(CASE WHEN is_canceled = 0 THEN adr * (stays_in_weekend_nights+stays_in_week_nights) ELSE 0 END) AS Actual_Revenue
    FROM hotel_bookings
GROUP BY arrival_date_year,months)
SELECT *,Lost_Revenue * 100.0 / (Lost_Revenue+Actual_Revenue) AS 'Lost%' FROM AMT
ORDER BY arrival_date_year,months;