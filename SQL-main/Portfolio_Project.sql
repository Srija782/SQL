

select * from credit_card_transcations

----Change Data type 
--alter table credit_card_transcations alter column transaction_id int;
--alter table credit_card_transcations alter column amount decimal(10,0);
--alter table credit_card_transcations alter column transaction_date date;

-- The dataset contains data from 10/04/2013 to 05/26/2015
-- There are 6 types of expenses: Grocery, Food,Travel,Entertainment, Fuel and Bills
-- There are 4 types of credit cards: Gold, Signature, Platinum and silver

--solve below questions
--1. write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

--Method 1:
select top 5 city,sum(amount) as total_spend,sum(amount)*100/(select sum(amount) from credit_card_transcations)
from credit_card_transcations
group by city 
order by 2 desc

--Method2 2:
select top 5 b.city,b.total_spend,(100*b.total_spend/a.total_credit_card_spend)
from (select sum(amount) as total_credit_card_spend from credit_card_transcations) a 
join (select city,sum(amount) as total_spend from credit_card_transcations group by city) as b
on 1=1
order by b.total_spend desc


--2- write a query to print highest spend month and amount spent in that month for each card type

--Method1

with cte as(
select card_type,year(transaction_date) as yr,month(transaction_date) as mt,sum(amount) as monthly_spend,
DENSE_RANK() over(partition by card_type order by card_type,sum(amount) desc) as rn
from credit_card_transcations
group by card_type,year(transaction_date),month(transaction_date))
select * from cte where rn = 1

--Method 2:

with cte as(
select a.*, DENSE_RANK() over(partition by card_type order by card_type,a.Monthly_spend desc) as rn
from (select card_type,year(transaction_date) as yr,month(transaction_date) as mt,sum(amount) as Monthly_spend from credit_card_transcations
group by card_type,year(transaction_date),month(transaction_date)) as a
)select * from cte where rn =1


--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)


with cte as(
select A.*,case when total_spends >=1000000 then 'Y' else 'N' end as new_col from 
(select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spends from credit_card_transcations) as A),
new_cte as(
select *,
row_number() over(partition by card_type order by total_spends) as rn
from cte where new_col = 'Y')
select * from new_cte where rn =1


--4- write a query to find city which had lowest percentage spend for gold card type


select top 1 A.a_city,(100*city_card_spend)/city_amount as spend_percent from 
(select city as a_city, sum(amount) as city_amount from credit_card_transcations group by city ) as A
join 
(select city as b_city,card_type as b_card_type,sum(amount) as city_card_spend from credit_card_transcations group by city,card_type ) as b
on a_city = b_city
where b_card_type='Gold'
order by spend_percent asc



--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

--method 1:
select city,exp_type,sum(amount) as expense_type_spend from credit_card_transcations
group by city,exp_type
order by city,3 desc

select tab_1.city,tab_1.exp_type as hightest_exp_type,tab_2.exp_type as lowest_exp_type from
(select * from(
select city,exp_type,dense_rank() over(partition by city order by sum(amount) desc) as high_rn from credit_card_transcations
group by city,exp_type) as a
where high_rn = 1) as tab_1
join
(select * from(
select city,exp_type,dense_rank() over(partition by city order by sum(amount) asc) as low_rn from credit_card_transcations
group by city,exp_type) as a
where low_rn = 1) as tab_2
on tab_1.city = tab_2.city



--Method 2:

with cte as(
select city,exp_type,sum(amount) as tot_amount,dense_rank() over(partition by city order by sum(amount) desc) as high_rank,
dense_rank() over(partition by city order by sum(amount) ) as low_rank
from credit_card_transcations
group by city,exp_type
),new_cte as(
select * from cte where high_rank = 1 or low_rank = 1),
cte3 as(
select city,case when high_rank > 1 then exp_type end as highest_exp_type,
case when high_rank = 1 then exp_type end as lowest_exp_type
from new_cte)
select city,STRING_AGG(highest_exp_type,','),STRING_AGG(lowest_exp_type,',') from cte3
group by city


--6- write a query to find percentage contribution of spends by females for each expense type
--Method 1:
select A.*,B.*,100*(A.gender_spend/B.exp_type_spend) from
(select exp_type as a_exp,gender,sum(amount) as gender_spend from credit_card_transcations
group by exp_type,gender) as A join
--order by exp_type
(select exp_type as b_exp,sum(amount) as exp_type_spend from credit_card_transcations group by exp_type) as B
on A.a_exp = B.b_exp
where gender = 'F'
order by a_exp

--Method 2:
select exp_type, sum(case when gender = 'F' then amount else 0 end)*100/sum(amount) as Percent_col
from credit_card_transcations
group by exp_type

--7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as(
select card_type,exp_type,year(transaction_date) as yr,month(transaction_date) as mt,sum(amount) as monthly_spend from credit_card_transcations
group by card_type,exp_type,year(transaction_date),month(transaction_date)
--order by card_type,exp_type,yr,mt
)
select top 1 *,100*(monthly_spend-prev_month_spend)/prev_month_spend as mom_growth from
(select *,lag(monthly_spend,1) over(partition by card_type,exp_type order by yr,mt) as prev_month_spend from cte) as A
where yr=2014 and mt=1
and prev_month_spend is not null
order by mom_growth desc

--9- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city,sum(amount)/count(transaction_id) as ratio
--datename(weekday,transaction_date),
--datepart(weekday,transaction_date)
 from credit_card_transcations
 where datepart(weekday,transaction_date) in (1,7)
group by city

order by ratio desc

--10- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as(
select *,row_number() over(partition by city order by transaction_date,transaction_id) as rn,
min(transaction_date) over(partition by city order by transaction_date,transaction_id) as min_date from credit_card_transcations)
select *,datediff(day,min_date,transaction_date) from cte where rn =500



