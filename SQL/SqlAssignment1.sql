use hotwax_commerce;
-- 1 New Customers Acquired in June 2023
SELECT
	DISTINCT
    p.party_id,
	per.first_name,
	per.last_name,
	cm.info_string AS email,
	CONCAT(tn.country_code, '-', tn.contact_number) AS phone,
	p.created_date AS entry_date
FROM
	party p
JOIN person per
     ON
	p.party_id = per.party_id
JOIN party_role pr
     ON
	p.party_id = pr.party_id
	AND pr.role_type_id = 'CUSTOMER'
JOIN party_contact_mech pcm
     ON
	p.party_id = pcm.party_id
JOIN contact_mech cm
     ON
	pcm.contact_mech_id = cm.contact_mech_id
JOIN telecom_number tn
     ON
	pcm.contact_mech_id = tn.contact_mech_id
WHERE
	p.created_date >= '2023-06-01'
	AND p.created_date < '2023-07-01'
	AND pr.role_type_id = "CUSTOMER";


-- 2 List All Active Physical Products  
SELECT
	PRODUCT_ID,
	PRODUCT_TYPE_ID,
	INTERNAL_NAME
FROM
	PRODUCT
WHERE
	IS_VIRTUAL = "N"
	AND (SALES_DISCONTINUATION_DATE IS NULL
		OR SALES_DISCONTINUATION_DATE > current_timestamp());


-- 3 Products Missing NetSuite ID
SELECT
	p.product_id,
	p.internal_name,
	p.product_type_id,
	gi.id_value AS netsuite_id
FROM
	product p
LEFT JOIN good_identification gi
       ON
	p.product_id = gi.product_id
	AND gi.good_identification_type_id = 'ERP_ID'
WHERE
	gi.product_id IS NULL
	AND product_type_id != "SERVICE";



-- 4 Product IDs Across Systems
SELECT
	p.product_id,
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
FROM
	product p
LEFT JOIN good_identification gi
		USING (product_id);



--   5 Completed Orders in August 2023
SELECT
	p.PRODUCT_ID,
		p.PRODUCT_TYPE_ID,
		o.PRODUCT_STORE_ID,
		oi.quantity AS TOTAL_QUANTITY,
	p.INTERNAL_NAME,
	oisg.FACILITY_ID,
	f.EXTERNAL_ID,
	f.FACILITY_TYPE_ID,
	oh.ORDER_HISTORY_ID,
	o.ORDER_ID,
	oi.ORDER_ITEM_SEQ_ID,
	oi.SHIP_GROUP_SEQ_ID
FROM
	order_header o
JOIN order_item oi
		USING (order_id)
JOIN product p
		USING (product_id)
JOIN order_item_ship_group oisg ON
	o.order_id = oisg.order_id
	AND oi.ship_group_seq_id = oisg.ship_group_seq_id
JOIN order_history oh ON
	o.order_id = oh.order_id
JOIN facility f ON
	oisg.facility_id = f.facility_id
WHERE
	o.status_id = 'ORDER_COMPLETED'
	AND o.order_date >= '2023-08-01'
	AND o.order_date < '2023-09-01';



-- 6 Newly Created Sales Orders and Payment Methods

SELECT 
	oh.ORDER_ID,
	opp.max_amount AS TOTAL_AMOUNT,
	opp.payment_method_type_id AS PAYMENT_METHOD,
	oh.external_id AS Shopify_Order_ID
FROM
	order_header oh
JOIN order_payment_preference opp
		USING (order_id)
WHERE
	oh.status_id = 'ORDER_CREATED';



-- 7 Payment Captured but Not Shipped
SELECT 
	oh.ORDER_ID,
	oh.status_id AS ORDER_STATUS,
	opp.status_id AS PAYMENT_STATUS,
	s.status_id AS SHIPMENT_STATUS
FROM
	order_header oh
JOIN order_payment_preference opp
		USING (order_id)
JOIN order_shipment os ON
	oh.order_id = os.order_id
JOIN shipment s ON
	s.shipment_id = os.shipment_id
WHERE
	opp.status_id = 'PAYMENT_AUTHORIZED'
	AND s.status_id = 'SHIPMENT_CREATED';



-- 8 Orders Completed Hourly
SELECT
	count(order_id) AS TOTAL_ORDER ,
	HOUR(order_date) AS HOUR
FROM
	order_header
WHERE
	status_id = 'ORDER_COMPLETED'
GROUP BY
	HOUR(order_date)
ORDER BY
	HOUR(order_date);



-- 9 BOPIS Orders Revenue
SELECT
	count(oh.order_id) AS TOTAL_ORDER , 
		        SUM(COALESCE(OH.grand_total, 0) - COALESCE(Ad.Adjustments, 0)) AS TOTAL_REVENUE
FROM
	order_header oh
JOIN order_item_ship_group
		USING(order_id)
JOIN (
	SELECT
		order_id,
		SUM(Amount) AS Adjustments
	FROM
		ORDER_ADJUSTMENT
	GROUP BY
		order_id 
) Ad 
    ON
	Ad.order_id = oh.order_id
WHERE
	shipment_method_type_id = 'STORE_PICKUP'
	AND YEAR(order_date) = YEAR(current_date())-1;


-- 10 Canceled Orders (Last Month)
SELECT
	Count(DISTINCT o.order_id) AS TOTAL_ORDER ,
	o.change_reason AS CANCELLATION_REASON
FROM
	order_Status o
JOIN order_status i ON
	o.order_id = i.order_id
	AND i.status_id = 'ORDER_CANCELLED'
WHERE
	o.status_id = 'ITEM_CANCELLED'
GROUP BY
	o.change_reason;



-- 11 Product Threshold Value
SELECT
	product_id ,
	minimum_stock AS threshold
FROM
	product_facility;
