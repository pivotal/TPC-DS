set role dsbench;
:EXPLAIN_ANALYZE
-- start query 44 in stream 0 using template query92.tpl and seed 1427377650
select  
   sum(ws_ext_discount_amt)  as "Excess Discount Amount" 
from 
    web_sales 
   ,item 
   ,date_dim
where
i_manufact_id = 651
and i_item_sk = ws_item_sk 
and d_date between '1998-01-29' and 
        (cast('1998-01-29' as date) + '90 days'::interval)
and d_date_sk = ws_sold_date_sk 
and ws_ext_discount_amt  
     > ( 
         SELECT 
            1.3 * avg(ws_ext_discount_amt) 
         FROM 
            web_sales 
           ,date_dim
         WHERE 
              ws_item_sk = i_item_sk 
          and d_date between '1998-01-29' and
                             (cast('1998-01-29' as date) + '90 days'::interval)
          and d_date_sk = ws_sold_date_sk 
      ) 
order by sum(ws_ext_discount_amt)
limit 100;

-- end query 44 in stream 0 using template query92.tpl
