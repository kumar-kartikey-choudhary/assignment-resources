use hotwax_commerce;

-- 1 New Customers Acquired in June 2023
select p.party_id, per.first_name, per.last_name , cm.info_string as email, concat(tn.country_code"-"tn.contact_number) as phone, p.created_date as entry_date, pr.role_type_id as role from party p
																				join person per using (party_id)
																				join party_contact_mech pcm using (party_id) 
																				join contact_mech cm using (contact_mech_id) 
																				Join telecom_number tn using(contact_mech_id)
																				join party_role pr using(party_id)
																				WHERE p.created_date >= '2023-06-01' AND p.created_date < '2023-07-01' AND pr.role_type_id = "CUSTOMER";											



-- 2 List All Active Physical Products  
select PRODUCT_ID, PRODUCT_TYPE_ID, INTERNAL_NAME from PRODUCT where IS_VIRTUAL = "N" 
																AND (SALES_DISCONTINUATION_DATE IS NULL OR  SALES_DISCONTINUATION_DATE > current_timestamp());        
                                                                


-- 3 Products Missing NetSuite ID
SELECT
    p.product_id,
    p.internal_name,
    p.product_type_id,
    gi.id_value AS netsuite_id
FROM product p
LEFT JOIN good_identification gi
       ON p.product_id = gi.product_id
      AND gi.good_identification_type_id = 'ERP_ID'
WHERE gi.product_id IS NULL AND product_type_id != "SERVICE";


-- 4 Product IDs Across Systems
SELECT p.product_id,
    (CASE
            WHEN gi.good_identification_type_id = 'SHOPIFY_PROD_ID'
            THEN gi.id_value
        END) AS shopify_id,
    (CASE
            WHEN gi.good_identification_type_id = 'HC_GOOD_ID_TYPE'
            THEN gi.id_value
        END) AS hotwax_id,
    (CASE
            WHEN gi.good_identification_type_id = 'ERP_ID'
            THEN gi.id_value            
        END) AS netsuite_id
FROM product p
LEFT JOIN good_identification gi USING (product_id);





 --   5 Completed Orders in August 2023
Select p.PRODUCT_ID,
		p.PRODUCT_TYPE_ID,
		o.PRODUCT_STORE_ID,
		oi.quantity as TOTAL_QUANTITY,
        p.INTERNAL_NAME,
        oisg.FACILITY_ID,
        f.EXTERNAL_ID,
        f.FACILITY_TYPE_ID,
        oh.ORDER_HISTORY_ID,
        o.ORDER_ID,
        oi.ORDER_ITEM_SEQ_ID,
        oi.SHIP_GROUP_SEQ_ID
from order_header o 
join order_item oi using (order_id)
join product p using (product_id)
join order_item_ship_group oisg on  o.order_id = oisg.order_id AND oi.ship_group_seq_id = oisg.ship_group_seq_id
join order_history oh on o.order_id = oh.order_id
join facility f on oisg.facility_id = f.facility_id
where o.status_id = 'ORDER_COMPLETED'
  AND o.order_date >= '2023-08-01'
  AND o.order_date < '2023-09-01';  
  
  
  

-- 6 Newly Created Sales Orders and Payment Methods

select 
	oh.ORDER_ID,
    opp.max_amount as TOTAL_AMOUNT,
    opp.payment_method_type_id as PAYMENT_METHOD,
    oh.external_id as Shopify_Order_ID
from order_header oh 
join order_payment_preference opp using (order_id)
where oh.status_id = 'ORDER_CREATED';


-- 7 Payment Captured but Not Shipped
select 
	oh.ORDER_ID,
    oh.status_id as ORDER_STATUS,
    opp.status_id as PAYMENT_STATUS,
    s.status_id as SHIPMENT_STATUS
from order_header oh
join order_payment_preference opp using (order_id)
Join order_shipment os on oh.order_id = os.order_id
join shipment s on s.shipment_id = os.shipment_id
where opp.status_id = 'PAYMENT_AUTHORIZED' AND s.status_id = 'SHIPMENT_CREATED';


-- 8 Orders Completed Hourly
Select count(order_id) as TOTAL_ORDER , hour(order_date) as HOUR from order_header where status_id = 'ORDER_COMPLETED' group by hour(order_date) order by hour(order_date);

-- 9 BOPIS Orders Revenue
select count(oh.order_id) as TOTAL_ORDER , 
		        SUM(COALESCE(OH.grand_total, 0) - COALESCE(Ad.Adjustments, 0)) as TOTAL_REVENUE
from order_header oh  join order_item_ship_group using(order_id)
JOIN (
    SELECT 
        order_id, 
        SUM(Amount) AS Adjustments  
    FROM ORDER_ADJUSTMENT 
    GROUP BY order_id 
) Ad 
    ON Ad.order_id = oh.order_id
where shipment_method_type_id = 'STORE_PICKUP' AND YEAR(order_date) = YEAR(current_date())-1;

-- 10 Canceled Orders (Last Month)
select Count(distinct o.order_id) as TOTAL_ORDER , o.change_reason AS CANCELLATION_REASON from order_Status o join order_status i on o.order_id = i.order_id AND i.status_id = 'ORDER_CANCELLED' where o.status_id = 'ITEM_CANCELLED' group by o.change_reason;

-- 11 Product Threshold Value
select product_id , minimum_stock as threshold from product_facility;
