use hotwax_commerce ;
-- Completed Sales Orders (Physical Items)
Select oh.ORDER_ID,
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
FROM order_header oh JOIN order_item oi using(order_id)
					join ( select order_id, MAX(status_datetime) as STATUS_DATETIME from order_status group by order_id ) os ON os.order_id = oh.order_id
                    join product p ON oi.product_id = p.product_id 
Where  oh.status_id = 'ORDER_COMPLETED' AND oh.order_type_id = 'SALES_ORDER';


-- Completed Return Items

SELECT rh.RETURN_ID,
	ri.ORDER_ID,
	oh.PRODUCT_STORE_ID,
	STATUS_DATETIME,
	oh.ORDER_NAME,
	rh.FROM_PARTY_ID,
	rh.RETURN_DATE,
	rh.ENTRY_DATE,
	rh.RETURN_CHANNEL_ENUM_ID
FROM return_header rh join return_item ri ON rh.return_id = ri.return_id 
                        join order_header oh ON ri.order_id = oh.order_id
                        join (select return_id, MAX(status_datetime) as STATUS_DATETIME from return_status group by return_id ) ra ON ra.return_id = rh.return_id
where rh.status_id = 'RETURN_COMPLETED';



--  Single-Return Orders (Last Month)
Select rh.from_party_id as PARTY_ID,
		per.FIRST_NAME
from return_header rh join person per on per.party_id = rh.from_party_id
				join return_item ri on rh.return_id = ri.return_id
where month(rh.return_date) = Month(curdate()-1)
group by  ri.order_id,
			rh.from_party_id,
			per.first_name
having Count(distinct rh.return_id) = 1;


-- Returns and Appeasements
SELECT 	COUNT(DISTINCT rh.return_id) as TOTAL_RETURNS,
		SUM(ri.return_quantity * ri.return_price) as RETURN_TOTAL,
		COUNT(DISTINCT ra.return_adjustment_id ) as TOTAL_APPEASEMENTS,
		SUM(ra.amount) as APPEASEMENTS_TOTAL
from return_header rh JOIN return_item ri ON rh.return_id = ri.return_id
					CROSS JOIN return_adjustment ra ON rh.return_id = ra.return_id
where ra.return_adjustment_type_id = 'RET_MAN_ADJ';


-- Detailed Return Information
SELECT rh.RETURN_ID,
rh.ENTRY_DATE,
ra.RETURN_ADJUSTMENT_TYPE_ID,
ra.AMOUNT,
ra.COMMENTS,
ri.ORDER_ID,
oh.ORDER_DATE,
rh.RETURN_DATE,
oh.PRODUCT_STORE_ID
from return_header rh JOIN return_item ri ON rh.return_id = ri.return_id
					JOIN order_header oh ON ri.order_id = oh.order_id
                    JOIN return_adjustment ra ON ra.return_id = rh.return_id;
                    
                    
-- Orders with Multiple Returns
SELECT
    ri.order_id,
    rh.return_id,
    rh.return_date,
    ri.return_reason_id AS return_reason,
    ri.return_quantity
FROM return_header rh
JOIN return_item ri USING (return_id)
WHERE ri.order_id IN (
    SELECT order_id
    FROM return_item
    GROUP BY order_id
    HAVING COUNT(DISTINCT return_id) > 1)
ORDER BY ri.order_id, rh.return_date;


-- Store with Most One-Day Shipped Orders (Last Month)
SELECT
    f.facility_id,
    f.facility_name,
    COUNT(DISTINCT s.primary_order_id) AS total_one_day_ship_orders,
    DATE(CURDATE() - INTERVAL 1 MONTH) AS reporting_period
FROM shipment s
JOIN facility f
     ON f.facility_id = s.origin_facility_id
JOIN order_header oh
     ON oh.order_id = s.primary_order_id
WHERE oh.order_date >= DATE(CURDATE() - INTERVAL 1 MONTH)
  AND oh.order_date < DATE(CURDATE())
  AND TIMESTAMPDIFF(
        DAY,
        oh.order_date,
        s.estimated_ship_date
      ) <= 1
GROUP BY
    f.facility_id, f.facility_name;
    
    
-- List of Warehouse Pickers
SELECT fp.PARTY_ID,
		CONCAT(per.FIRST_NAME,' ', per.LAST_NAME) as FULL_NAME,
        fp.ROLE_TYPE_ID,
        fp.FACILITY_ID,
        p.status_id as STATUS
FROM PERSON per JOIN PARTY p ON p.party_id = per.party_id JOIN FACILITY_PARTY fp on p.party_id = fp.party_id 
where fp.role_type_id ='WAREHOUSE_PICKER'; 


-- Total Facilities That Sell the Product
SELECT
    p.product_id,
    p.internal_name AS product_name,
    COUNT(DISTINCT pf.facility_id) AS facility_count,
    GROUP_CONCAT(DISTINCT pf.facility_id ORDER BY pf.facility_id) AS facilities
FROM product_facility pf
JOIN product p
    ON p.product_id = pf.product_id
GROUP BY
    p.product_id,
    p.internal_name;
    
    
-- Total Items in Various Virtual Facilities
SELECT pf.PRODUCT_ID,
		pf.FACILITY_ID,
        f.FACILITY_TYPE_ID,
        i.quantity_on_hand_total as QOH,
        i.available_to_promise_total as ATP
FROM product_facility pf JOIN facility f ON pf.facility_id = f.facility_id 
		JOIN inventory_item i on i.product_id = pf.product_id AND i.facility_id = pf.facility_id
WHERE f.facility_type_id <> 'VIRTUAL_FACILITY';				