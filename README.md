# Hotel Booking Analysis (MySQL)

## Project Overview
Analysis of about 119,000 hotel bookings to understand **cancellations, revenue and pricing** at two hotels (a City Hotel and a Resort Hotel).
The goal: find where the hotels lose money and what a manager could do about it.

## Dataset
- **Source:** Hotel Booking Demand (Kaggle)
- **Size:** about 119,000 bookings, 32 columns
- **Hotels:** City Hotel and Resort Hotel (Portugal), 2015 to 2017
- **Key columns:** `is_canceled`, `lead_time`, `deposit_type`, `adr` (average daily rate), `reserved_room_type`, `market_segment`, `distribution_channel`

## Tools and Skills
- **MySQL**
- Aggregations, `CASE WHEN`, subqueries
- CTEs
- Window functions: `RANK`, `LAG`, running totals, `SUM() OVER()`
- Revenue formula used: `adr x (weekend nights + week nights)`, counting **non-cancelled bookings only**

## Key Insights

### 1. City Hotel cancels far more often
**41.73%** of City Hotel bookings were cancelled (33,102 bookings) versus **27.76%** at the Resort Hotel (11,122 bookings).
About 4 in 10 City Hotel bookings never turn into a stay.

### 2. Non-refundable bookings cancel almost every time
Bookings marked **Non Refund** were cancelled **99.36%** of the time, compared with **28.38%** for No Deposit and **22.22%** for Refundable.
A non-refundable booking should be the safest type, so this looks backwards and needs further investigation (for example, by market segment and distribution channel) before changing any policy.

### 3. The earlier a guest books, the more likely they cancel
| Lead time | Cancellation rate |
|---|---|
| 0-30 days | 18.56% |
| 31-90 days | 37.70% |
| 91-180 days | 44.71% |
| 180+ days | 57.01% |

Bookings made more than 180 days ahead cancel about **3 times** as often as bookings made within 30 days.

### 4. Higher room types earn about 2x the nightly rate
- **City Hotel:** Room G averages **226.58** ADR versus **98.84** for Room A.
- **Resort Hotel:** Room H averages **183.97** ADR versus **75.81** for Room A.

Room A is the volume room (34,529 City and 16,567 Resort non-cancelled bookings), so upgrades from Room A are the main upside.
Room types with very few bookings (for example City Room C with 6) were not used for conclusions.

### 5. Summer is the peak revenue period
- **Resort Hotel:** the top month is **August 2017** (about 1.08M), followed by August 2016 (about 1.00M) and July 2017 (about 0.95M).
- **City Hotel:** the top months are August 2017 (about 885K), May 2017 (about 877K) and July 2017 (about 863K).

## Recommendations
1. **Introduce deposits or reconfirmation for long-lead bookings** (90+ days ahead), starting with the City Hotel, where cancellations are highest.
2. **Promote room upgrades and raise rates in July and August**, when revenue peaks.

## Limitations
- Data covers **two hotels in Portugal (2015-2017)**, so results may not apply to other markets.
- The analysis shows **patterns, not proven causes**.
- A few ADR values were zero or unusual, so ADR calculations by room type filter `adr > 0`.
- Peak months are ranked by year and month. Because 2017 is a later year, growth may inflate those months.

## How to Run
1. Download `hotel_bookings.csv` from Kaggle (Hotel Booking Demand).
2. Open `hotel_booking_analysis.sql` in MySQL Workbench.
3. Change the file path in the `LOAD DATA LOCAL INFILE` line to where you saved the CSV.
4. Run the script. It creates the table, loads the data and runs all 20 analysis queries.

## Queries Included (20)
- **Basics:** bookings per hotel, cancellation rate, bookings per year, lead time and stay length
- **Cancellations:** by market segment, deposit type, lead-time bucket, repeated guests
- **Revenue and ADR:** revenue per hotel, ADR by room type, monthly running total, peak months, weekend vs weekday
- **Guests and channels:** top countries, distribution channels, customer types, special requests
- **Advanced:** month-over-month growth with `LAG`, assigned vs reserved rooms, lost revenue from cancellations

## Author
**Shuhaib R**, aspiring Data Analyst, Bangalore
LinkedIn: https://www.linkedin.com/in/shuhaib-r-87649a322
