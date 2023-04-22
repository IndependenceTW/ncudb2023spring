USE [ncudb]
GO
CREATE OR ALTER PROCEDURE [dbo].[count_all_kd]
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @K_value FLOAT, @D_value FLOAT
    DECLARE @RSI REAL

    DECLARE @today_c FLOAT
    DECLARE @row_number INT
    DECLARE @stock_code VARCHAR(10)
    DECLARE @date DATE

    DECLARE @yesterday_K FLOAT, @yesterday_D FLOAT
    SET @yesterday_K = 50
    SET @yesterday_D = 50

    DECLARE cur CURSOR FOR
    SELECT ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY [date] ASC) AS ROW_ID, stock_code, [date], c FROM stock_price
    OPEN cur

    FETCH NEXT FROM cur INTO @row_number, @stock_code, @date, @today_c
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @row_number = 1
        BEGIN SET @yesterday_K = 50; SET @yesterday_D = 50; END
        
        SELECT @RSI = (@today_c - MIN([l])) / (MAX([h]) - MIN([l])) * 100
        FROM stock_price
        WHERE stock_code = @stock_code AND [date] in (SELECT [date] FROM dbo.find_date_func(@date, 9, 1, 0))
        GROUP BY stock_code

        SET @K_value = (2/3.0) * @yesterday_K + (1/3.0) * @RSI
        SET @D_value = (2/3.0) * @yesterday_D + (1/3.0) * @K_value

        UPDATE stock_price
        SET K_value = @K_value, D_value = @D_value
        WHERE stock_code = @stock_code AND [date] = @date

        SET @yesterday_K = @K_value
        SET @yesterday_D = @D_value

        FETCH NEXT FROM cur INTO @row_number, @stock_code, @date, @today_c
    END
    CLOSE cur
    DEALLOCATE cur
END