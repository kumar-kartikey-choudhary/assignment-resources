use hotwax_commerce;
-- Total Shipments in January 2022
SELECT
	s.SHIPMENT_ID,
	s.estimated_ship_date AS SHIPMENT_DATE,
	s.origin_facility_id AS FACILITY_ID,
	s.primary_order_id AS ORDER_ID
FROM
	SHIPMENT s
WHERE
	s.created_date >= '2022-01-01'
	AND s.created_date < '2022-02-01'
	AND s.status_id = 'SHIPMENT_SHIPPED';


-- Shipments by Tracking Number
SELECT
	s.SHIPMENT_ID,
	s.primary_order_id AS ORDER_ID,
	srs.tracking_id_number AS TRACKING_NUMBER,
	s.estimated_ship_date AS SHIPMENT_DATE,
	srs.CARRIER_PARTY_ID,
	s.status_id AS SHIPMENT_STATUS
FROM
	shipment s
JOIN shipment_route_segment srs
		USING(shipment_id);


-- Average Shipments per Month (Q1 2022)



-- Brokered but Not Shipped Orders
SELECT
	s.primary_order_id AS ORDER_ID,
		DATE(oisg.created_stamp) AS BROKERED_DATE,
		oisg.facility_id AS BROKERED_FACILITY_ID,
		s.status_id AS SHIPMENT_STATUS,
		timestampdiff(HOUR, oisg.created_stamp, CURRENT_TIMESTAMP) AS TIME_SINCE_BROKERING
FROM
	shipment s
JOIN order_item_ship_group oisg ON
	oisg.order_id = s.primary_order_id
	AND s.primary_ship_group_seq_id = oisg.ship_group_seq_id
WHERE
	s.status_id NOT IN( 'SHIPMENT_SHIPPED', 'SHIPMENT_CANCELLED');


-- Multi-Item Orders (Single Ship Group)
SELECT
	s.primary_order_id AS ORDER_ID,
	count(oi.order_item_seq_id)AS TOTAL_ITEMS_IN_ORDER,
	s.primary_ship_group_seq_id AS SHIP_GROUP_SEQ_ID,
	s.SHIPMENT_ID,
	s.origin_facility_id AS FACILITY_ID,
	s.estimated_ship_date AS SHIPMENT_DATE
FROM
	SHIPMENT s
JOIN order_item oi ON
	s.primary_order_id = oi.order_id
	AND s.primary_ship_group_seq_id = oi.ship_group_seq_id
GROUP BY
	s.primary_order_id ,
	s.primary_ship_group_seq_id,
	s.shipment_id
HAVING
	COUNT(oi.order_item_seq_id) > 1;



-- Orders Shipped from Stores (25 Days Before New Year)
SELECT
	s.primary_order_id AS ORDER_ID,
		s.SHIPMENT_ID,
	s.origin_facility_id AS FACILITY_ID,
	s.estimated_ship_date AS SHIPMENT_DATE,
	oh.ORDER_DATE,
	count(oi.order_item_seq_id) AS TOTAL_ITEM,
	pa.STATE_PROVINCE_GEO_ID AS CUSTOMER_STATE
FROM
	shipment s
JOIN order_header oh ON
	s.primary_order_id = oh.order_id
JOIN order_item oi ON
	oh.order_id = oi.order_id
	AND s.primary_ship_group_seq_id = oi.ship_group_seq_id
JOIN shipment_contact_mech scm ON
	scm.shipment_id = s.shipment_id
	AND scm.shipment_contact_mech_type_id = 'SHIP_TO_ADDRESS'
JOIN postal_address pa ON
	pa.contact_mech_id = scm.contact_mech_id
WHERE
	s.estimated_ship_date >= DATE_SUB(
          DATE(s.estimated_ship_date, '%Y-12-31'),
          INTERVAL 24 DAY)
GROUP BY
	s.Shipment_id ,
	s.primary_order_id ,
	s.primary_ship_group_seq_id;



--  Single-Item Orders Fulfilled from Warehouses (Last Month)
SELECT
	s.primary_order_id AS order_id,
	COUNT(DISTINCT oi.order_item_seq_id) AS total_order_items,
	s.origin_facility_id AS facility_id,
	s.shipment_id,
	s.estimated_ship_date AS shipment_date,
	os.status_datetime AS order_completion_date
FROM
	shipment s
JOIN facility f
     ON
	s.origin_facility_id = f.facility_id
JOIN order_item oi
     ON
	s.primary_order_id = oi.order_id
	AND s.primary_ship_group_seq_id = oi.ship_group_seq_id
JOIN order_status os
     ON
	os.order_id = s.primary_order_id
	AND os.status_id = 'ORDER_COMPLETED'
WHERE
	f.facility_type_id = 'WAREHOUSE'
	AND s.estimated_ship_date >= DATE(CURDATE() - INTERVAL 1 MONTH)
	AND s.estimated_ship_date < DATE(CURDATE())
GROUP BY
	s.primary_order_id,
	s.shipment_id,
	s.origin_facility_id,
	s.estimated_ship_date,
	os.status_datetime
HAVING
	COUNT(DISTINCT oi.order_item_seq_id) = 1;


-- Shipping Refunds (Last Month)



-- Shipping Revenue (Last Month)
SELECT
	COUNT(DISTINCT s.primary_order_id) AS TOTAL_ORDER,
	SUM(oa.amount) AS TOTAL_SHIPPING_REVENUE,
	DATE_FORMAT(s.estimated_ship_date, '%Y-%m') AS MONTH
FROM
	shipment s
JOIN order_adjustment oa
     ON
	s.primary_order_id = oa.order_id
WHERE
	oa.order_adjustment_type_id = 'SHIPPING_CHARGES'
	AND s.estimated_ship_date >= DATE(CURDATE() - INTERVAL 1 MONTH)
	AND s.estimated_ship_date < DATE(CURDATE())
GROUP BY
	DATE(s.estimated_ship_date);



-- RETURN WITHOUT RESTOCK LOCATION 
SELECT
	rh.return_id,
	ri.order_id,
	rh.return_date,
	rh.from_party_id,
	rh.destination_facility_id AS restock_facility_id,
	ri.return_reason_id AS return_reason
FROM
	return_header rh
JOIN return_item ri
     ON
	rh.return_id = ri.return_id
WHERE
	rh.destination_facility_id IS NULL
	OR rh.destination_facility_id = '_NA_';
