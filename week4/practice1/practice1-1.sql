USE ncudb

DECLARE @day_cnt INT

SELECT @day_cnt=day_of_stock
FROM dbo.calendar
WHERE [date]='2022-12-22'

SELECT [date]
FROM dbo.calendar
WHERE YEAR([date])=YEAR('2022-12-22')
    AND @day_cnt - day_of_stock BETWEEN 0 and 4
    AND day_of_stock != -1
