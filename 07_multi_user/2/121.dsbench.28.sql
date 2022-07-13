set role dsbench;
:EXPLAIN_ANALYZE
-- start query 21 in stream 1 using template query28.tpl and seed 1629204324
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 34 and 34+10 
             or ss_coupon_amt between 14317 and 14317+1000
             or ss_wholesale_cost between 8 and 8+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 165 and 165+10
          or ss_coupon_amt between 12634 and 12634+1000
          or ss_wholesale_cost between 48 and 48+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 86 and 86+10
          or ss_coupon_amt between 2230 and 2230+1000
          or ss_wholesale_cost between 70 and 70+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 19 and 19+10
          or ss_coupon_amt between 15856 and 15856+1000
          or ss_wholesale_cost between 74 and 74+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 183 and 183+10
          or ss_coupon_amt between 2253 and 2253+1000
          or ss_wholesale_cost between 15 and 15+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 74 and 74+10
          or ss_coupon_amt between 6773 and 6773+1000
          or ss_wholesale_cost between 31 and 31+20)) B6
limit 100;

-- end query 21 in stream 1 using template query28.tpl
