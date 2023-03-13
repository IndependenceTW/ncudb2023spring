USE ncudb

SELECT stock_price.d, STRING_AGG(stock_info.[name], ',') Company, calendar.day_of_stock
FROM stock_price
    JOIN stock_info ON stock_info.stock_code=stock_price.stock_code
    JOIN calendar ON stock_price.[date]=calendar.[date]
WHERE [stock_price].[date]='2022-01-18'
    AND d BETWEEN -1 and 1
GROUP BY d, [calendar].day_of_stock


