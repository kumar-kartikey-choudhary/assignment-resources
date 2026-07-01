# SQL Assignments 
---

## Assignment 1

### 1. New Customers Acquired in June 2023

```sql
SELECT p.party_id, per.first_name, per.last_name,
       cm.info_string AS email,
       CONCAT(tn.country_code , " " , tn.contact_number) AS phone,
       p.created_date AS entry_date,
       pr.role_type_id AS role
FROM party p
JOIN person per USING (party_id)
JOIN party_contact_mech pcm USING (party_id)
JOIN contact_mech cm USING (contact_mech_id)
JOIN telecom_number tn USING (contact_mech_id)
JOIN party_role pr USING (party_id)
WHERE p.created_date >= '2023-06-01'
  AND p.created_date < '2023-07-01'
  AND pr.role_type_id = 'CUSTOMER';
```

---

### 2. List All Active Physical Products

```sql
SELECT PRODUCT_ID, PRODUCT_TYPE_ID, INTERNAL_NAME
FROM PRODUCT
WHERE IS_VIRTUAL = 'N'
  AND (SALES_DISCONTINUATION_DATE IS NULL
       OR SALES_DISCONTINUATION_DATE > CURRENT_TIMESTAMP());
```

---

### 3. Products Missing NetSuite ID

```sql
SELECT
    p.product_id,
    p.internal_name,
    p.product_type_id,
    gi.id_value AS netsuite_id
FROM product p
LEFT JOIN good_identification gi
       ON p.product_id = gi.product_id
      AND gi.good_identification_type_id = 'ERP_ID'
WHERE gi.product_id IS NULL
  AND product_type_id != 'SERVICE';
```

---

### 4. Product IDs Across Systems

```sql
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
```

---

### 5. Completed Orders in August 2023

```sql
SELECT p.PRODUCT_ID, p.PRODUCT_TYPE_ID, o.PRODUCT_STORE_ID,
       oi.quantity AS TOTAL_QUANTITY, p.INTERNAL_NAME,
       oisg.FACILITY_ID, f.EXTERNAL_ID, f.FACILITY_TYPE_ID,
       oh.ORDER_HISTORY_ID, o.ORDER_ID,
       oi.ORDER_ITEM_SEQ_ID, oi.SHIP_GROUP_SEQ_ID
FROM order_header o
JOIN order_item oi USING (order_id)
JOIN product p USING (product_id)
JOIN order_item_ship_group oisg
     ON o.order_id = oisg.order_id
    AND oi.ship_group_seq_id = oisg.ship_group_seq_id
JOIN order_history oh ON o.order_id = oh.order_id
JOIN facility f ON oisg.facility_id = f.facility_id
WHERE o.status_id = 'ORDER_COMPLETED'
  AND o.order_date >= '2023-08-01'
  AND o.order_date < '2023-09-01';
```

---

### 6. Newly Created Sales Orders and Payment Methods

```sql
SELECT
    oh.ORDER_ID,
    opp.max_amount AS TOTAL_AMOUNT,
    opp.payment_method_type_id AS PAYMENT_METHOD,
    oh.external_id AS Shopify_Order_ID
FROM order_header oh
JOIN order_payment_preference opp USING (order_id)
WHERE oh.status_id = 'ORDER_CREATED';
```

---

### 7. Payment Captured but Not Shipped

```sql
SELECT
    oh.ORDER_ID,
    oh.status_id AS ORDER_STATUS,
    opp.status_id AS PAYMENT_STATUS,
    s.status_id AS SHIPMENT_STATUS
FROM order_header oh
JOIN order_payment_preference opp USING (order_id)
JOIN order_shipment os ON oh.order_id = os.order_id
JOIN shipment s ON s.shipment_id = os.shipment_id
WHERE opp.status_id = 'PAYMENT_AUTHORIZED'
  AND s.status_id = 'SHIPMENT_APPROVED';
```

---

### 8. Orders Completed Hourly

```sql
SELECT COUNT(order_id) AS TOTAL_ORDER,
       HOUR(order_date) AS HOUR
FROM order_header
WHERE status_id = 'ORDER_COMPLETED'
GROUP BY HOUR(order_date)
ORDER BY HOUR(order_date);
```

---

### 9. BOPIS Orders Revenue

```sql
SELECT COUNT(oh.order_id) AS TOTAL_ORDER,
       SUM(COALESCE(OH.grand_total, 0) - COALESCE(Ad.Adjustments, 0)) AS TOTAL_REVENUE
FROM order_header oh
JOIN order_item_ship_group USING (order_id)
JOIN (
    SELECT order_id, SUM(Amount) AS Adjustments
    FROM ORDER_ADJUSTMENT
    GROUP BY order_id
) Ad ON Ad.order_id = oh.order_id
WHERE shipment_method_type_id = 'STORE_PICKUP'
  AND YEAR(order_date) = YEAR(CURRENT_DATE()) - 1;
```

---

### 10. Canceled Orders (Last Month)

```sql
SELECT COUNT(DISTINCT o.order_id) AS TOTAL_ORDER,
       o.change_reason AS CANCELLATION_REASON
FROM order_status o
JOIN order_status i ON o.order_id = i.order_id
  AND i.status_id = 'ORDER_CANCELLED'
WHERE o.status_id = 'ITEM_CANCELLED'
GROUP BY o.change_reason;
```

---

### 11. Product Threshold Value

```sql
SELECT product_id, minimum_stock AS threshold
FROM product_facility;
```

---

## Assignment 2

### 1. Shipping Addresses for October 2023 Orders

```sql
SELECT oh.ORDER_ID,
       orl.PARTY_ID,
       CONCAT(p.first_name, ' ', p.last_name) AS CUSTOMER_NAME,
       pa.address1 AS STREET_ADDRESS,
       pa.CITY,
       pa.state_province_geo_id AS STATE_PROVINCE,
       pa.POSTAL_CODE,
       pa.country_geo_id AS COUNTRY_CODE,
       oh.status_id AS ORDER_STATUS,
       oh.ORDER_DATE
FROM order_header oh
JOIN order_role orl ON orl.order_id = oh.order_id AND orl.role_type_id = 'PLACING_CUSTOMER'
JOIN Person p ON orl.party_id = p.party_id
JOIN order_contact_mech ocm ON ocm.order_id = oh.order_id AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.contact_mech_id = pa.contact_mech_id
WHERE oh.order_date >= '2023-10-01'
  AND oh.order_date < '2023-11-01'
ORDER BY oh.order_date;
```

---

### 2. Orders From New York

```sql
SELECT oh.ORDER_ID,
       CONCAT(p.first_name, ' ', p.last_name) AS CUSTOMER_NAME,
       pa.address1 AS STREET_ADDRESS,
       pa.CITY,
       pa.state_province_geo_id AS STATE_PROVINCE,
       oh.grand_total AS TOTAL_AMOUNT,
       pa.POSTAL_CODE,
       pa.country_geo_id AS COUNTRY_CODE,
       oh.status_id AS ORDER_STATUS,
       oh.ORDER_DATE
FROM order_header oh
JOIN order_role orl ON orl.order_id = oh.order_id AND orl.role_type_id = 'PLACING_CUSTOMER'
JOIN Person p ON orl.party_id = p.party_id
JOIN order_contact_mech ocm ON ocm.order_id = oh.order_id AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.contact_mech_id = pa.contact_mech_id
WHERE pa.state_province_geo_id = 'NY';
```

---

### 3. Top-Selling Product in New York

```sql
SELECT oi.PRODUCT_ID,
       p.INTERNAL_NAME,
       SUM(oi.quantity) AS TOTAL_QUANTITY_SOLD,
       pa.CITY,
       SUM(oi.quantity * oi.unit_price) AS REVENUE,
       CONCAT(
           DATE(MIN(oh.order_date), '%Y-%m-%d'),
           ' to ',
           DATE(MAX(oh.order_date), '%Y-%m-%d')
       ) AS date_range
FROM order_header oh
JOIN order_item oi USING (order_id)
JOIN Product p ON p.product_id = oi.product_id
JOIN order_contact_mech ocm ON ocm.order_id = oi.order_id AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.contact_mech_id = pa.contact_mech_id
WHERE pa.state_province_geo_id = 'NY'
GROUP BY oi.product_id, p.internal_name
ORDER BY TOTAL_QUANTITY_SOLD DESC;
```

---

### 4. Store-Specific (Facility-Wise) Revenue

```sql
SELECT f.facility_id,
       f.facility_name,
       COUNT(DISTINCT oh.order_id) AS total_order,
       SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM order_header oh
JOIN order_item oi ON oi.order_id = oh.order_id
JOIN order_item_ship_group oisg ON oisg.order_id = oh.order_id
JOIN facility f ON f.facility_id = oisg.facility_id
WHERE oh.status_id = 'ORDER_COMPLETED'
GROUP BY f.facility_id, f.facility_name;
```

---

### 5. Lost and Damaged Inventory

```sql
SELECT im.INVENTORY_ITEM_ID,
       im.PRODUCT_ID,
       im.FACILITY_ID,
       ABS(imd.quantity_on_hand_diff) AS QUANTITY_LOST_OR_DAMAGED,
       imd.reason_enum_id AS REASON_CODE,
       DATE(imd.created_stamp) AS TRANSACTION_DATE
FROM inventory_item im
JOIN inventory_item_detail imd USING (inventory_item_id)
WHERE imd.reason_enum_id IN ('VAR_DAMAGED', 'VAR_LOST')
GROUP BY im.INVENTORY_ITEM_ID, im.PRODUCT_ID, im.FACILITY_ID;
```

---

### 6. Low Stock or Out of Stock Items Report

```sql
SELECT
    p.product_id,
    p.internal_name AS product_name,
    pf.facility_id,
    ii.quantity_on_hand_total AS qoh,
    ii.available_to_promise_total AS atp,
    pf.minimum_stock AS reorder_threshold,
    CURDATE() AS date_checked
FROM product p
JOIN product_facility pf ON p.product_id = pf.product_id
JOIN inventory_item ii ON p.product_id = ii.product_id AND pf.facility_id = ii.facility_id
WHERE ii.available_to_promise_total <= pf.minimum_stock
   OR ii.available_to_promise_total <= 0;
```

---

### 7. Retrieve the Current Facility (Physical or Virtual) of Open Orders

```sql
SELECT DISTINCT
    oh.order_id,
    oh.status_id AS order_status,
    f.facility_id,
    f.facility_name,
    f.facility_type_id
FROM order_header oh
JOIN order_item_ship_group oisg ON oh.order_id = oisg.order_id
JOIN facility f ON oisg.facility_id = f.facility_id
WHERE oh.status_id = 'ORDER_APPROVED';
```

---

### 8. Items Where QOH and ATP Differ

```sql
SELECT
    product_id,
    facility_id,
    quantity_on_hand_total AS QOH,
    available_to_promise_total AS ATP,
    (quantity_on_hand_total - available_to_promise_total) AS DIFFERENCE
FROM inventory_item
WHERE quantity_on_hand_total <> available_to_promise_total;
```

---

### 9. Order Item Current Status Changed Date-Time

```sql
SELECT o.ORDER_ID,
       o.ORDER_ITEM_SEQ_ID,
       o.status_id AS CURRENT_STATUS_ID,
       o.status_datetime AS STATUS_CHANGE_DATETIME,
       o.status_user_login AS CHANGED_BY
FROM order_status o
JOIN order_status os ON o.order_id = os.order_id
  AND o.order_item_seq_id = os.order_item_seq_id
WHERE o.status_id = 'ITEM_APPROVED'
  AND os.status_id = 'ITEM_COMPLETED';
```

---

### 10. Total Orders by Sales Channel

```sql
SELECT
    oh.sales_channel_enum_id AS SALES_CHANNEL,
    COUNT(oh.order_id) AS TOTAL_ORDERS,
    SUM(COALESCE(OH.grand_total, 0) - COALESCE(Ad.Adjustments, 0)) AS TOTAL_REVENUE,
    CONCAT(MIN(DATE(OH.Entry_date)), '--', MAX(DATE(OH.Entry_date))) AS REPORTING_PERIOD
FROM order_header oh
JOIN (
    SELECT order_id, SUM(Amount) AS Adjustments
    FROM ORDER_ADJUSTMENT
    GROUP BY order_id
) Ad ON Ad.order_id = oh.order_id
WHERE oh.status_id = 'ORDER_COMPLETED'
GROUP BY oh.sales_channel_enum_id;
```

---

## Assignment 3

### 1. Completed Sales Orders (Physical Items)

```sql
SELECT
	oh.ORDER_ID,
	oi.ORDER_ITEM_SEQ_ID,
	oi.PRODUCT_ID,
	p.PRODUCT_TYPE_ID,
	oh.SALES_CHANNEL_ENUM_ID,
	oh.ORDER_DATE,
	oh.ENTRY_DATE,
	os.STATUS_ID,
	os.STATUS_DATETIME,
	oh.ORDER_TYPE_ID,
	oh.PRODUCT_STORE_ID
FROM
	order_header oh
JOIN order_item oi
		USING(order_id)
JOIN order_status os ON
	os.order_id = oh.order_id
JOIN product p ON
	oi.product_id = p.product_id
JOIN product_type pt ON
	pt.product_type_id = p.product_type_id 
WHERE
	os.status_id = 'ORDER_COMPLETED' AND pt.is_physical = 'Y'
	AND oh.order_type_id = 'SALES_ORDER';

```

---

### 2. Completed Return Items

```sql
SELECT
	rh.RETURN_ID,
	ri.ORDER_ID,
	oh.PRODUCT_STORE_ID,
	rs.STATUS_DATETIME,
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
JOIN return_status rs ON
	rh.return_id = rs.return_id 
WHERE 
	rs.status_id = 'RETURN_COMPLETED';
```

---

### 3. Single-Return Orders (Last Month)

```sql
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

```

---

### 4. Returns and Appeasements

```sql
SELECT
    COUNT(DISTINCT rh.return_id) AS TOTAL_RETURNS,
    SUM(ri.return_quantity * ri.return_price) AS RETURN_TOTAL,
    COUNT(DISTINCT ra.return_adjustment_id) AS TOTAL_APPEASEMENTS,
    SUM(ra.amount) AS APPEASEMENTS_TOTAL
FROM return_header rh
JOIN return_item ri ON rh.return_id = ri.return_id
CROSS JOIN return_adjustment ra ON rh.return_id = ra.return_id
WHERE ra.return_adjustment_type_id = 'APPEASEMENT';
```

---

### 5. Detailed Return Information

```sql
SELECT rh.RETURN_ID, rh.ENTRY_DATE,
       ra.RETURN_ADJUSTMENT_TYPE_ID, ra.AMOUNT, ra.COMMENTS,
       ri.ORDER_ID, oh.ORDER_DATE, rh.RETURN_DATE, oh.PRODUCT_STORE_ID
FROM return_header rh
JOIN return_item ri ON rh.return_id = ri.return_id
JOIN order_header oh ON ri.order_id = oh.order_id
JOIN return_adjustment ra ON ra.return_id = rh.return_id;
```

---

### 6. Orders with Multiple Returns

```sql
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
    HAVING COUNT(DISTINCT return_id) > 1
)
ORDER BY ri.order_id, rh.return_date;
```

---

### 7. Store with Most One-Day Shipped Orders (Last Month)

```sql
SELECT
    f.facility_id,
    f.facility_name,
    COUNT(DISTINCT s.primary_order_id) AS total_one_day_ship_orders,
    DATE(CURDATE() - INTERVAL 1 MONTH) AS reporting_period
FROM shipment s
JOIN facility f ON f.facility_id = s.origin_facility_id
JOIN order_header oh ON oh.order_id = s.primary_order_id
WHERE oh.order_date >= DATE(CURDATE() - INTERVAL 1 MONTH)
  AND oh.order_date < DATE(CURDATE())
  AND TIMESTAMPDIFF(DAY, oh.order_date, s.estimated_ship_date) <= 1
GROUP BY f.facility_id, f.facility_name;
```

---

### 8. List of Warehouse Pickers

```sql
SELECT fp.PARTY_ID,
       CONCAT(per.FIRST_NAME, ' ', per.LAST_NAME) AS FULL_NAME,
       fp.ROLE_TYPE_ID,
       fp.FACILITY_ID,
       p.status_id AS STATUS
FROM PERSON per
JOIN PARTY p ON p.party_id = per.party_id
JOIN FACILITY_PARTY fp ON p.party_id = fp.party_id
WHERE fp.role_type_id = 'WAREHOUSE_PICKER';
```

---

### 9. Total Facilities That Sell the Product

```sql
SELECT
    p.product_id,
    p.internal_name AS product_name,
    COUNT(DISTINCT pf.facility_id) AS facility_count,
    GROUP_CONCAT(DISTINCT pf.facility_id ORDER BY pf.facility_id) AS facilities
FROM product_facility pf
JOIN product p ON p.product_id = pf.product_id
GROUP BY p.product_id, p.internal_name;
```

---

### 10. Total Items in Various Virtual Facilities

```sql
SELECT pf.PRODUCT_ID, pf.FACILITY_ID, f.FACILITY_TYPE_ID,
       i.quantity_on_hand_total AS QOH,
       i.available_to_promise_total AS ATP
FROM product_facility pf
JOIN facility f ON pf.facility_id = f.facility_id
JOIN inventory_item i ON i.product_id = pf.product_id AND i.facility_id = pf.facility_id
WHERE f.facility_type_id <> 'VIRTUAL_FACILITY';
```

---

## Assignment 4

### 1. Total Shipments in January 2022

```sql
SELECT s.SHIPMENT_ID,
       s.estimated_ship_date AS SHIPMENT_DATE,
       s.origin_facility_id AS FACILITY_ID,
       s.primary_order_id AS ORDER_ID
FROM SHIPMENT s
WHERE s.created_date >= '2022-01-01'
  AND s.created_date < '2022-02-01'
  AND s.status_id = 'SHIPMENT_SHIPPED';
```

---

### 2. Shipments by Tracking Number

```sql
SELECT s.SHIPMENT_ID,
       s.primary_order_id AS ORDER_ID,
       srs.tracking_id_number AS TRACKING_NUMBER,
       s.estimated_ship_date AS SHIPMENT_DATE,
       srs.CARRIER_PARTY_ID,
       s.status_id AS SHIPMENT_STATUS
FROM shipment s
JOIN shipment_route_segment srs USING (shipment_id);
```

---

### 3. Average Shipments per Month (Q1 2022)

```sql
-- Query to be added
```

---

### 4. Brokered but Not Shipped Orders

```sql
SELECT s.primary_order_id AS ORDER_ID,
       DATE(oisg.created_stamp) AS BROKERED_DATE,
       oisg.facility_id AS BROKERED_FACILITY_ID,
       s.status_id AS SHIPMENT_STATUS,
       TIMESTAMPDIFF(HOUR, oisg.created_stamp, CURRENT_TIMESTAMP) AS TIME_SINCE_BROKERING
FROM shipment s
JOIN order_item_ship_group oisg
     ON oisg.order_id = s.primary_order_id
    AND s.primary_ship_group_seq_id = oisg.ship_group_seq_id
WHERE s.status_id NOT IN ('SHIPMENT_SHIPPED', 'SHIPMENT_CANCELLED');
```

---

### 5. Multi-Item Orders (Single Ship Group)

```sql
SELECT s.primary_order_id AS ORDER_ID,
       COUNT(oi.order_item_seq_id) AS TOTAL_ITEMS_IN_ORDER,
       s.primary_ship_group_seq_id AS SHIP_GROUP_SEQ_ID,
       s.SHIPMENT_ID,
       s.origin_facility_id AS FACILITY_ID,
       s.estimated_ship_date AS SHIPMENT_DATE
FROM SHIPMENT s
JOIN order_item oi ON s.primary_order_id = oi.order_id
  AND s.primary_ship_group_seq_id = oi.ship_group_seq_id
GROUP BY s.primary_order_id, s.primary_ship_group_seq_id, s.shipment_id
HAVING COUNT(oi.order_item_seq_id) > 1;
```

---

### 6. Orders Shipped from Stores (25 Days Before New Year)

```sql
SELECT s.primary_order_id AS ORDER_ID,
       s.SHIPMENT_ID,
       s.origin_facility_id AS FACILITY_ID,
       s.estimated_ship_date AS SHIPMENT_DATE,
       oh.ORDER_DATE,
       COUNT(oi.order_item_seq_id) AS TOTAL_ITEM,
       pa.STATE_PROVINCE_GEO_ID AS CUSTOMER_STATE
FROM shipment s
JOIN order_header oh ON s.primary_order_id = oh.order_id
JOIN order_item oi ON oh.order_id = oi.order_id AND s.primary_ship_group_seq_id = oi.ship_group_seq_id
JOIN shipment_contact_mech scm ON scm.shipment_id = s.shipment_id AND scm.shipment_contact_mech_type_id = 'SHIP_TO_ADDRESS'
JOIN postal_address pa ON pa.contact_mech_id = scm.contact_mech_id
WHERE s.estimated_ship_date >= DATE_SUB(
          DATE(s.estimated_ship_date, '%Y-12-31'),
          INTERVAL 24 DAY)
GROUP BY s.Shipment_id, s.primary_order_id, s.primary_ship_group_seq_id;
```

---

### 7. Single-Item Orders Fulfilled from Warehouses (Last Month)

```sql
SELECT
    s.primary_order_id AS order_id,
    COUNT(DISTINCT oi.order_item_seq_id) AS total_order_items,
    s.origin_facility_id AS facility_id,
    s.shipment_id,
    s.estimated_ship_date AS shipment_date,
    os.status_datetime AS order_completion_date
FROM shipment s
JOIN facility f ON s.origin_facility_id = f.facility_id
JOIN order_item oi ON s.primary_order_id = oi.order_id AND s.primary_ship_group_seq_id = oi.ship_group_seq_id
JOIN order_status os ON os.order_id = s.primary_order_id AND os.status_id = 'ORDER_COMPLETED'
WHERE f.facility_type_id = 'WAREHOUSE'
  AND s.estimated_ship_date >= DATE(CURDATE() - INTERVAL 1 MONTH)
  AND s.estimated_ship_date < DATE(CURDATE())
GROUP BY s.primary_order_id, s.shipment_id, s.origin_facility_id, s.estimated_ship_date, os.status_datetime
HAVING COUNT(DISTINCT oi.order_item_seq_id) = 1;
```

---

### 8. Shipping Refunds (Last Month)

```sql
-- Query to be added
```

---

### 9. Shipping Revenue (Last Month)

```sql
SELECT
    COUNT(DISTINCT s.primary_order_id) AS TOTAL_ORDER,
    SUM(oa.amount) AS TOTAL_SHIPPING_REVENUE,
    DATE_FORMAT(s.estimated_ship_date, '%Y-%m') AS MONTH
FROM shipment s
JOIN order_adjustment oa ON s.primary_order_id = oa.order_id
WHERE oa.order_adjustment_type_id = 'SHIPPING_CHARGES'
  AND s.estimated_ship_date >= DATE(CURDATE() - INTERVAL 1 MONTH)
  AND s.estimated_ship_date < DATE(CURDATE())
GROUP BY DATE(s.estimated_ship_date);
```

---

### 10. Return Without Restock Location

```sql
SELECT
    rh.return_id,
    ri.order_id,
    rh.return_date,
    rh.from_party_id,
    rh.destination_facility_id AS restock_facility_id,
    ri.return_reason_id AS return_reason
FROM return_header rh
JOIN return_item ri ON rh.return_id = ri.return_id
WHERE rh.destination_facility_id IS NULL
   OR rh.destination_facility_id = '_NA_';
```

