---MOONLLC Querry 1 CHEESE OVERSALES

 

--Which cheeses have sold at a greater quantity than was mined. List Cheese ID, Customer ID, 
--Order Date, Original Cheese Weight, Sold Cheese Weight per customer (list customer id with this value), 
--and Cheese Weight Over Total. Order by Cheese ID, Order Date lowest to smallest. (121)


WITH CheeseCustomerSales AS (
    SELECT
        C.CHEESE_ID,
        CU.CUSTOMER_ID,
        MAX(CT.ORDER_DATE) AS ORDER_DATE,
        C.WEIGHT AS CHEESE_WEIGHT,
        SUM(TD.WEIGHT) AS SOLD_CHEESE_WEIGHT,
        SUM(TD.WEIGHT) - C.WEIGHT AS WEIGHT_OVER_TOTAL
    FROM CHEESE C
    INNER JOIN TRANSACTION_DETAIL TD 
        ON C.CHEESE_ID = TD.CHEESE_ID
    INNER JOIN CUSTOMER_TRANSACTION CT 
        ON TD.CUSTOMER_TRANSACTION_ID = CT.CUSTOMER_TRANSACTION_ID
    INNER JOIN CUSTOMER CU 
        ON CT.CUSTOMER_ID = CU.CUSTOMER_ID
    GROUP BY 
        C.CHEESE_ID, 
        CU.CUSTOMER_ID, 
        C.WEIGHT
    HAVING C.WEIGHT < SUM(TD.WEIGHT)
)

SELECT *
FROM CheeseCustomerSales;

/*
"We need to identify potential accounting discrepancies in our cheese inventory system. 
The query will help us find instances where the recorded sales weight of a cheese exceeds its original weight, 
which is due to sales of cheese not being properly recorded before new sales are happening. 
This analysis will highlight potential data entry errors or tracking issues in our sales recording process that need to 
be addressed. Aswell it will identify customers that may have paid for cheese that does not exist so that issue can be 
addressed."
*/


---MOONLLC Querry 2 CHEESE TRANSPORT - VALUE OF CARGO COMPARED TO COST TO FLY SHIP


/*
Compare Total Cheese sale value to the cost to fly the ship they are on. List Spaceship ID, 
Spaceship Weight, Cheese Weight, Value of all Cheeses, Cost of Fly ship, and Net Cheese Value.
Order by Net Cheese Value smallest to largest. (13)
*/
SELECT
    SPACESHIP_ID,
    SPACESHIP_WEIGHT_TONS,
    CHEESE_WEIGHT_TONS,

    CONCAT('$', FORMAT(CHEESE_VALUE, 'N2')) AS CHEESE_VALUE,
    CONCAT('$', FORMAT(FUEL_COST_PER_SHIP, 'N2')) AS FUEL_COST_PER_SHIP,
    CONCAT('$', FORMAT(NET_CHEESE_VALUE, 'N2')) AS NET_CHEESE_VALUE

FROM (
    SELECT 
        S.SPACESHIP_ID AS SPACESHIP_ID,
        S.MAX_WEIGHT_CAPACITY AS SPACESHIP_WEIGHT_TONS,
        SUM(C.WEIGHT) AS CHEESE_WEIGHT_TONS,

        -- Total cheese value
        SUM(C.PRICE_PER_KILO * (C.WEIGHT * 1000)) AS CHEESE_VALUE,

        -- Fuel cost
        (SUM(C.WEIGHT) + S.MAX_WEIGHT_CAPACITY) * S.FUEL_COST_PER_TONS AS FUEL_COST_PER_SHIP,

        -- Net cheese value
        SUM(C.PRICE_PER_KILO * (C.WEIGHT * 1000)) 
        - ((SUM(C.WEIGHT) + S.MAX_WEIGHT_CAPACITY) * S.FUEL_COST_PER_TONS) 
        AS NET_CHEESE_VALUE

    FROM CHEESE C
    JOIN CHEESE_LOGISTICS CL 
        ON C.CHEESE_ID = CL.CHEESE_ID
    JOIN SPACESHIP S 
        ON S.SPACESHIP_ID = CL.SPACESHIP_ID

    GROUP BY 
        S.SPACESHIP_ID,
        S.MAX_WEIGHT_CAPACITY,
        S.FUEL_COST_PER_TONS
) X

ORDER BY NET_CHEESE_VALUE ASC;


/*
The company wants a list to see how much each spaceship is 
costing compared to the cheese cargo its transporting. 
*/

---MOONLLC Querry 3 CHEESE TRANSPORT FREE SPACE AND COST EFFECITINVES 

/*
A list of the amount wasted by not having each spaceship at capacity. 
 List Sspaceship ID, Max Weight Capacity per Ship, Sum of Total Weight of Cheese on Ship, and the amount of 
 wasted space on each ship as well as the cost of that wasted space. Include a total row. Order by Total Wasted Cost 
 highest to lowest. (14)
*/

WITH SPACESHIP_EFFICIENCY AS (
    SELECT 
        S.SPACESHIP_ID AS SPACESHIP_NUM, 
        S.MAX_WEIGHT_CAPACITY AS MAX_WEIGHT_PER_SHIP, 
        SUM(C.WEIGHT) AS TOTAL_CHEESE_WEIGHT,
        (S.MAX_WEIGHT_CAPACITY - SUM(C.WEIGHT)) AS WASTED_WEIGHT,

        (SUM(C.WEIGHT) + S.MAX_WEIGHT_CAPACITY) * S.FUEL_COST_PER_TONS 
            AS TOTAL_FUEL_COST,

        CASE 
            WHEN (S.MAX_WEIGHT_CAPACITY - SUM(C.WEIGHT)) > 0 
                THEN (S.MAX_WEIGHT_CAPACITY - SUM(C.WEIGHT)) * S.FUEL_COST_PER_TONS
            ELSE 
                (SUM(C.WEIGHT) - S.MAX_WEIGHT_CAPACITY) * S.COST * 0.00005
        END AS WASTED_FUEL_COST
    FROM CHEESE C
    INNER JOIN CHEESE_LOGISTICS CL 
        ON C.CHEESE_ID = CL.CHEESE_ID
    INNER JOIN SPACESHIP S 
        ON S.SPACESHIP_ID = CL.SPACESHIP_ID
    GROUP BY 
        S.SPACESHIP_ID, 
        S.MAX_WEIGHT_CAPACITY, 
        S.FUEL_COST_PER_TONS,
        S.COST
)

SELECT
    SPACESHIP_NUM,
    MAX_WEIGHT_PER_SHIP,
    TOTAL_CHEESE_WEIGHT,
    WASTED_WEIGHT,
    CONCAT('$', FORMAT(TOTAL_FUEL_COST, 'N2')) AS TOTAL_FUEL_COST,
    CONCAT('$', FORMAT(WASTED_FUEL_COST, 'N2')) AS WASTED_FUEL_COST
FROM (
    SELECT 
        CAST(SPACESHIP_NUM AS VARCHAR(20)) AS SPACESHIP_NUM,
        MAX_WEIGHT_PER_SHIP,
        TOTAL_CHEESE_WEIGHT,
        WASTED_WEIGHT,
        TOTAL_FUEL_COST,
        WASTED_FUEL_COST
    FROM SPACESHIP_EFFICIENCY

    UNION ALL

    SELECT 
        'TOTAL',
        NULL,
        SUM(TOTAL_CHEESE_WEIGHT),
        SUM(WASTED_WEIGHT),
        NULL,
        SUM(WASTED_FUEL_COST)
    FROM SPACESHIP_EFFICIENCY
) X
ORDER BY WASTED_FUEL_COST ASC;




/*
The company wants to know if they transport the cheese in the most efficient and cost-effective way. 
If the cheese is not being transported in the most efficient way than this query can help decide on 
lowering the amount of spaceships in the fleet or waiting to mine more cheese before flying.
*/


---MOONLLC Querry 4 UNSOLD CHEESE

/*
Find the value of all the unsold cheese. List Cheese ID, Value of Cheese, Mining Area ID, Mining Area Quality. 
Include a total row as well as rows of all the mining areas with counts of number of unsold cheeses. 
Order by Cheese ID low to high then Mining Area unsold Cheese low to high. (448)
*/
WITH UNSOLD_CHEESE AS (
    SELECT 
        C.CHEESE_ID AS CHEESE_NUM, 
        C.PRICE_PER_KILO * (C.WEIGHT * 1000) AS CHEESE_VALUE_RAW,
        C.MINING_AREA_ID AS MINING_AREA, 
        COUNT(*) OVER (PARTITION BY C.MINING_AREA_ID) AS TOTAL_FROM_AREA,
        MA.MINE_QUALITY AS MINING_AREA_QUALITY
    FROM CHEESE C
    INNER JOIN MINING_AREA MA
        ON C.MINING_AREA_ID = MA.MINING_AREA_ID
    LEFT JOIN TRANSACTION_DETAIL TD 
        ON C.CHEESE_ID = TD.CHEESE_ID
    LEFT JOIN CUSTOMER_TRANSACTION CT 
        ON TD.CUSTOMER_TRANSACTION_ID = CT.CUSTOMER_TRANSACTION_ID
    LEFT JOIN CUSTOMER CU 
        ON CT.CUSTOMER_ID = CU.CUSTOMER_ID
    WHERE CU.CUSTOMER_ID IS NULL
)

SELECT
    CHEESE_NUM,
    CONCAT('$', FORMAT(CHEESE_VALUE_RAW, 'N2')) AS CHEESE_VALUE,
    MINING_AREA,
    TOTAL_FROM_AREA,
    MINING_AREA_QUALITY
FROM (
    -- DETAIL ROWS
    SELECT 
        CAST(CHEESE_NUM AS VARCHAR(20)) AS CHEESE_NUM,
        CHEESE_VALUE_RAW,
        MINING_AREA,
        TOTAL_FROM_AREA,
        MINING_AREA_QUALITY
    FROM UNSOLD_CHEESE

    UNION ALL

    -- TOTAL ROW
    SELECT  
        'TOTAL',
        SUM(CHEESE_VALUE_RAW),
        NULL,
        NULL,
        ROUND(AVG(MINING_AREA_QUALITY), 2)
    FROM UNSOLD_CHEESE

    UNION ALL

    -- MINING AREA TOTALS
    SELECT  
        'MINING AREA',
        SUM(CHEESE_VALUE_RAW),
        MINING_AREA,
        COUNT(*),
        ROUND(AVG(MINING_AREA_QUALITY), 2)
    FROM UNSOLD_CHEESE
    GROUP BY MINING_AREA
) X
ORDER BY Mining_AREA, CHEESE_VALUE_RAW ASC, TOTAL_FROM_AREA ASC;


/*
Management wants a list of all cheese that is unsold, and which Mining Area it came from. 
They want this information to determine if any of the cheeses need to be put on sale or find trends for 
Mining Areas that are not producing cheese that get sold.
*/






