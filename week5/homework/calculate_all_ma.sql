USE [ncudb]
GO
ALTER PROCEDURE [calculate_all_ma]
AS
BEGIN
    DECLARE @date DATE
    DECLARE @stock_code VARCHAR(10)

    DECLARE cur CURSOR FOR
        SELECT [date], stock_code
        FROM stock_price
        WHERE MA5 is null 
            OR MA10 is null 
            OR MA20 is null 
            OR MA60 is null 
            OR MA120 is null 
            OR MA240 is null

    OPEN cur
    FETCH NEXT FROM cur INTO @date, @stock_code

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXECUTE [Row_MA_calculation] @date, @stock_code
        FETCH NEXT FROM cur INTO @date, @stock_code
    END

    CLOSE cur
    DEALLOCATE cur
END