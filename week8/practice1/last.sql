USE [ncudb]
GO

SELECT DISTINCT t1.date AS yesterday, MIN(t2.date) AS today
    FROM stock_price t1
        INNER JOIN stock_price t2
        ON t1.stock_code = t2.stock_code
    WHERE t1.date < t2.date
    GROUP BY t1.stock_code, t1.date