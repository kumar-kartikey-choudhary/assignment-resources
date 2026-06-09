use hotwax_commerce ;
-- Completed Sales Orders (Physical Items)
SELECT
	oh.ORDER_ID,
	oi.ORDER_ITEM_SEQ_ID,
	oi.PRODUCT_ID,
	p.PRODUCT_TYPE_ID,
	oh.SALES_CHANNEL_ENUM_ID,
	oh.ORDER_DATE,
	oh.ENTRY_DATE,
	oh.STATUS_ID,
	STATUS_DATETIME,
	oh.ORDER_TYPE_ID,
	oh.PRODUCT_STORE_ID
FROM
	order_header oh
JOIN order_item oi
		USING(order_id)
JOIN (
	SELECT
		order_id,
		MAX(status_datetime) AS STATUS_DATETIME
	FROM
		order_status
	GROUP BY
		order_id ) os ON
	os.order_id = oh.order_id
JOIN product p ON
	oi.product_id = p.product_id
WHERE
	oh.status_id = 'ORDER_COMPLETED'
	AND oh.order_type_id = 'SALES_ORDER';




-- Completed Return Items

SELECT
	rh.RETURN_ID,
	ri.ORDER_ID,
	oh.PRODUCT_STORE_ID,
	STATUS_DATETIME,
	oh.ORDER_NAME,
	rh.FROM_PARTY_ID,
	rh.RETURN_DATE,
	rh.ENTRY_DATE,
	rh.RETURN_CHANNEL_ENUM_ID
FROM
	return_header rh
JOIN return_item ri ON
	rh.return_id = ri.return_id
JOIN order_header oh ON
	ri.order_id = oh.order_id
JOIN (
	SELECT
		return_id,
		MAX(status_datetime) AS STATUS_DATETIME
	FROM
		return_status
	GROUP BY
		return_id ) ra ON
	ra.return_id = rh.return_id
WHERE
	rh.status_id = 'RETURN_COMPLETED';




--  Single-Return Orders (Last Month)
SELECT
	rh.from_party_id AS PARTY_ID,
		per.FIRST_NAME
FROM
	return_header rh
JOIN person per ON
	per.party_id = rh.from_party_id
JOIN return_item ri ON
	rh.return_id = ri.return_id
WHERE
	MONTH(rh.return_date) = MONTH(curdate()-1)
GROUP BY
	ri.order_id,
			rh.from_party_id,
			per.first_name
HAVING
	Count(DISTINCT rh.return_id) = 1;



-- Returns and Appeasements
SELECT
	COUNT(DISTINCT rh.return_id) AS TOTAL_RETURNS,
		SUM(ri.return_quantity * ri.return_price) AS RETURN_TOTAL,
		COUNT(DISTINCT ra.return_adjustment_id ) AS TOTAL_APPEASEMENTS,
		SUM(ra.amount) AS APPEASEMENTS_TOTAL
FROM
	return_header rh
JOIN return_item ri ON
	rh.return_id = ri.return_id
CROSS JOIN return_adjustment ra ON
	rh.return_id = ra.return_id
WHERE
	ra.return_adjustment_type_id = 'APPEASEMENT';



-- Detailed Return Information
SELECT
	rh.RETURN_ID,
	rh.ENTRY_DATE,
	ra.RETURN_ADJUSTMENT_TYPE_ID,
	ra.AMOUNT,
	ra.COMMENTS,
	ri.ORDER_ID,
	oh.ORDER_DATE,
	rh.RETURN_DATE,
	oh.PRODUCT_STORE_ID
FROM
	return_header rh
JOIN return_item ri ON
	rh.return_id = ri.return_id
JOIN order_header oh ON
	ri.order_id = oh.order_id
JOIN return_adjustment ra ON
	ra.return_id = rh.return_id;



-- Orders with Multiple Returns
SELECT
	ri.order_id,
	rh.return_id,
	rh.return_date,
	ri.return_reason_id AS return_reason,
	ri.return_quantity
FROM
	return_header rh
JOIN return_item ri
		USING (return_id)
WHERE
	ri.order_id IN (
	SELECT
		order_id
	FROM
		return_item
	GROUP BY
		order_id
	HAVING
		COUNT(DISTINCT return_id) > 1)
ORDER BY
	ri.order_id,
	rh.return_date;



-- Store with Most One-Day Shipped Orders (Last Month)
SELECT
	f.facility_id,
	f.facility_name,
	COUNT(DISTINCT s.primary_order_id) AS total_one_day_ship_orders,
	DATE(CURDATE() - INTERVAL 1 MONTH) AS reporting_period
FROM
	shipment s
JOIN facility f
     ON
	f.facility_id = s.origin_facility_id
JOIN order_header oh
     ON
	oh.order_id = s.primary_order_id
WHERE
	oh.order_date >= DATE(CURDATE() - INTERVAL 1 MONTH)
	AND oh.order_date < DATE(CURDATE())
	AND TIMESTAMPDIFF(
        DAY,
        oh.order_date,
        s.estimated_ship_date
      ) <= 1
GROUP BY
	f.facility_id,
	f.facility_name;



-- List of Warehouse Pickers
SELECT
	fp.PARTY_ID,
		CONCAT(per.FIRST_NAME, ' ', per.LAST_NAME) AS FULL_NAME,
	fp.ROLE_TYPE_ID,
	fp.FACILITY_ID,
	p.status_id AS STATUS
FROM
	PERSON per
JOIN PARTY p ON
	p.party_id = per.party_id
JOIN FACILITY_PARTY fp ON
	p.party_id = fp.party_id
WHERE
	fp.role_type_id = 'WAREHOUSE_PICKER';



-- Total Facilities That Sell the Product
SELECT
	p.product_id,
	p.internal_name AS product_name,
	COUNT(DISTINCT pf.facility_id) AS facility_count,
	GROUP_CONCAT(DISTINCT pf.facility_id ORDER BY pf.facility_id) AS facilities
FROM
	product_facility pf
JOIN product p
    ON
	p.product_id = pf.product_id
GROUP BY
	p.product_id,
	p.internal_name;



-- Total Items in Various Virtual Facilities
SELECT
	pf.PRODUCT_ID,
		pf.FACILITY_ID,
	f.FACILITY_TYPE_ID,
	i.quantity_on_hand_total AS QOH,
	i.available_to_promise_total AS ATP
FROM
	product_facility pf
JOIN facility f ON
	pf.facility_id = f.facility_id
JOIN inventory_item i ON
	i.product_id = pf.product_id
	AND i.facility_id = pf.facility_id
WHERE
	f.facility_type_id <> 'VIRTUAL_FACILITY';


  
-- Transfer Orders Without Inventory Reservation
SELECT
    oh.order_id AS transfer_order_id,
    s.origin_facility_id AS from_facility_id,
    s.destination_facility_id AS to_facility_id,
    oi.product_id,
    oi.quantity AS requested_quantity,
    COALESCE(SUM(oir.quantity), 0) AS reserved_quantity,
    oh.order_date AS transfer_date,
    oh.status_id AS status
FROM order_header oh
JOIN order_item oi
     ON oh.order_id = oi.order_id
JOIN shipment s
     ON oh.order_id = s.primary_order_id
      AND s.primary_ship_group_seq_id = oi.ship_group_seq_id
LEFT JOIN order_item_ship_grp_inv_res oir
     ON oi.order_id = oir.order_id
    AND oi.order_item_seq_id = oir.order_item_seq_id
    AND oi.ship_group_seq_id = oir.ship_group_seq_id
WHERE oh.order_type_id = 'TRANSFER_ORDER'
GROUP BY
    oh.order_id,
    s.origin_facility_id ,
    s.destination_facility_id,
    oi.product_id,
    oi.quantity,
    oh.order_date,
    oh.status_id
HAVING COALESCE(SUM(oir.quantity), 0) < oi.quantity;


-- Orders Without Picklist 
SELECT
    oh.order_id,
    oh.order_date,
    oh.status_id AS order_status,
    oisg.facility_id,
    TIMESTAMPDIFF(
        HOUR,
        oisg.created_stamp,
        CURRENT_TIMESTAMP
    ) AS duration_hours
FROM order_header oh
JOIN order_item_ship_group oisg
     ON oh.order_id = oisg.order_id
JOIN shipment s
     ON s.primary_order_id = oh.order_id
WHERE NOT EXISTS (
    SELECT 1
    FROM picklist_shipment ps
    WHERE ps.shipment_id = s.shipment_id
);    
