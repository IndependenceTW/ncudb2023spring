USE [ncudb]

DECLARE @date DATE 
SELECT @date=MAX([date]) FROM stock_price

CREATE TABLE #dates ([date] DATE, [day_of_stock] INT);
INSERT INTO #dates ([date], [day_of_stock])
EXEC [dbo].[find_date] @date , 5, 1, 0

SELECT DISTINCT stock_code INTO #stock FROM stock_price WHERE [date] IN (SELECT [date] FROM #dates) 

CREATE TABLE #stock_temp(
    id INT IDENTITY(1, 1),
    [date] DATE NOT NULL,
    stock_code VARCHAR(10) NOT NULL,
    MA5 REAL NOT NULL,
    MA10 REAL NOT NULL,
    [percent] REAL
)

INSERT INTO #stock_temp([date], stock_code, MA5, MA10)
SELECT [date], stock_code, MA5, MA10 FROM stock_price WHERE [date] IN (SELECT [date] FROM #dates) AND stock_code IN (SELECT stock_code FROM #stock) ORDER BY [stock_code], [date]

DECLARE cur CURSOR LOCAL FOR SELECT id FROM #stock_temp
DECLARE @i INT
OPEN cur
FETCH NEXT FROM cur INTO @i

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE #stock_temp SET [percent] = (MA5 - MA10) / MA10 WHERE id=@i
    FETCH NEXT FROM cur INTO @i
END

SELECT * FROM #stock_temp WHERE [percent] >= 0.01

DROP TABLE #stock_temp
DROP TABLE #stock
DROP TABLE #dates

CLOSE cur
DEALLOCATE cur