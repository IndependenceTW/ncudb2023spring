USE ncudb

DECLARE @day_cnt INT

SELECT @day_cnt=day_of_stock
FROM dbo.calendar
WHERE [date]='2022-12-22'

SELECT stock_code, COUNT(*) CNT, STRING_AGG([date], ',') [date], STRING_AGG(d, ',') d
FROM stock_price
WHERE EXISTS(
    SELECT [date]
    FROM calendar
    WHERE stock_price.[date] = calendar.[date]
        AND YEAR([date]) = YEAR('2022-12-22')
        AND @day_cnt - day_of_stock BETWEEN 0 AND 4
        AND day_of_stock != -1
) AND d>0
GROUP BY stock_code