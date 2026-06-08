Use hotwax_commerce;
-- Shipping Addresses for October 2023 Orders
SELECT
	oh.ORDER_ID, 
		orl.PARTY_ID,
	concat(p.first_name, " ", p.last_name) AS CUSTOMER_NAME,
	pa.address1 AS STREET_ADDRESS,
	pa.CITY,
	pa.state_province_geo_id AS STATE_PROVINCE,
	pa.POSTAL_CODE,
	pa.country_geo_id AS COUNTRY_CODE,
	oh.status_id AS ORDER_STATUS,
	oh.ORDER_DATE
FROM
	order_header oh
JOIN order_role orl ON
	orl.order_id = oh.order_id
	AND orl.role_type_id = 'PLACING_CUSTOMER'
JOIN Person p ON
	orl.party_id = p.party_id
JOIN order_contact_mech ocm ON
	ocm.order_id = oh.order_id
	AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON
	ocm.contact_mech_id = pa.contact_mech_id
WHERE
	oh.order_date >= '2023-10-01'
	AND oh.order_date < '2023-11-01'
ORDER BY
	oh.order_date;


-- Orders From New York
SELECT
	oh.ORDER_ID,
	concat(p.first_name, " ", p.last_name) AS CUSTOMER_NAME,
	pa.address1 AS STREET_ADDRESS,
	pa.CITY,
	pa.state_province_geo_id AS STATE_PROVINCE,
	oh.grand_total AS TOTAL_AMOUNT,
	pa.POSTAL_CODE,
	pa.country_geo_id AS COUNTRY_CODE,
	oh.status_id AS ORDER_STATUS,
	oh.ORDER_DATE
FROM
	order_header oh
JOIN order_role orl ON
	orl.order_id = oh.order_id
	AND orl.role_type_id = 'PLACING_CUSTOMER'
JOIN Person p ON
	orl.party_id = p.party_id
JOIN order_contact_mech ocm ON
	ocm.order_id = oh.order_id
	AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON
	ocm.contact_mech_id = pa.contact_mech_id
WHERE
	pa.state_province_geo_id = 'NY';


-- Top-Selling Product in New York
SELECT
	oi.PRODUCT_ID,
		p.INTERNAL_NAME,
	SUM(oi.quantity) AS TOTAL_QUANTITY_SOLD,
	pa.CITY,
	SUM(oi.quantity * oi.unit_price) AS REVENUE,
		CONCAT(
        DATE(MIN(oh.order_date), '%Y-%m-%d'),
        ' to ',
        DATE(MAX(oh.order_date), '%Y-%m-%d')
    ) AS date_range
FROM
	order_header oh
JOIN order_item oi
		USING(order_id)
JOIN Product p ON
	p.product_id = oi.product_id
JOIN order_contact_mech ocm ON
	ocm.order_id = oi.order_id
	AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON
	ocm.contact_mech_id = pa.contact_mech_id
WHERE
	pa.state_province_geo_id = 'NY'
GROUP BY
	oi.product_id ,
	p.internal_name
ORDER BY
	TOTAL_QUANTITY_SOLD DESC;


-- Store-Specific (Facility-Wise) Revenue
SELECT
	f.facility_id,
		f.facility_name,
	COUNT(DISTINCT oh.order_id) AS total_order,
	Sum(oi.quantity * oi.unit_price) AS total_revenue
FROM
	order_header oh
JOIN order_item oi ON
	oi.order_id = oh.order_id
JOIN order_item_ship_group oisg ON
	oisg.order_id = oh.order_id
JOIN facility f ON
	f.facility_id = oisg.facility_id
WHERE
	oh.status_id = 'ORDER_COMPLETED'
GROUP BY
	f.facility_id,
		f.facility_name;



-- Lost and Damaged Inventory
SELECT
	im.INVENTORY_ITEM_ID,
		im.PRODUCT_ID,
	im.FACILITY_ID,
	ABS(imd.quantity_on_hand_diff) AS QUANTITY_LOST_OR_DAMAGED,
	imd.reason_enum_id AS REASON_CODE,
	DATE(imd.created_stamp) AS TRANSACTION_DATE
FROM
	inventory_item im
JOIN inventory_item_detail imd
		USING(inventory_item_id)
WHERE
	imd.reason_enum_id IN ('VAR_DAMAGED', 'VAR_LOST')
GROUP BY
	im.INVENTORY_ITEM_ID,
		im.PRODUCT_ID,
	im.FACILITY_ID;



-- Low Stock or Out of Stock Items Report
SELECT
	p.product_id,
	p.internal_name AS product_name,
	pf.facility_id,
	ii.quantity_on_hand_total AS qoh,
	ii.available_to_promise_total AS atp,
	pf.minimum_stock AS reorder_threshold,
	CURDATE() AS date_checked
FROM
	product p
JOIN product_facility pf
     ON
	p.product_id = pf.product_id
JOIN inventory_item ii
     ON
	p.product_id = ii.product_id
	AND pf.facility_id = ii.facility_id
WHERE
	ii.available_to_promise_total <= pf.minimum_stock
	OR ii.available_to_promise_total <= 0;



-- Retrieve the Current Facility (Physical or Virtual) of Open Orders
SELECT
	DISTINCT
    oh.order_id,
	oh.status_id AS order_status,
	f.facility_id,
	f.facility_name,
	f.facility_type_id
FROM
	order_header oh
JOIN order_item_ship_group oisg
     ON
	oh.order_id = oisg.order_id
JOIN facility f
     ON
	oisg.facility_id = f.facility_id
WHERE
	oh.status_id = 'ORDER_APPROVED';



-- Items Where QOH and ATP Differ
SELECT
	product_id,
	facility_id,
	quantity_on_hand_total AS QOH,
	available_to_promise_total AS ATP,
	(quantity_on_hand_total - available_to_promise_total) AS DIFFERENCE
FROM
	inventory_item
WHERE
	quantity_on_hand_total <> available_to_promise_total;



-- Order Item Current Status Changed Date-Time
SELECT
	o.ORDER_ID,
		o.ORDER_ITEM_SEQ_ID,
	o.status_id AS CURRENT_STATUS_ID,
	o.status_datetime AS STATUS_CHANGE_DATETIME,
	o.status_user_login AS CHANGED_BY
FROM
	order_status o
JOIN order_status os ON
	o.order_id = os.order_id
	AND o.order_item_seq_id = os.order_item_seq_id
WHERE
	o.status_id = 'ITEM_APPROVED'
	AND os.status_id = 'ITEM_COMPLETED';



-- Total Orders by Sales Channel
SELECT 
		oh.sales_channel_enum_id AS SALES_CHANNEL,
		count(oh.order_id) AS TOTAL_ORDERS,
	SUM(COALESCE(OH.grand_total, 0) - COALESCE(Ad.Adjustments, 0)) AS TOTAL_REVENUE,
	CONCAT(Min(Date(OH.Entry_date)) , '--' , Max(Date(OH.Entry_date))) AS REPORTING_PERIOD
FROM
	order_header oh
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
	oh.status_id = 'ORDER_COMPLETED'
GROUP BY
	oh.sales_channel_enum_id;
