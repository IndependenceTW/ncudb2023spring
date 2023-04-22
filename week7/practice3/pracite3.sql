USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[find_KD_cross]
(
    @target_stock VARCHAR(10)
)
RETURNS @result_table TABLE
(
    stock_code VARCHAR(10),
    [date] DATE,
    cross_type VARCHAR(10),
    last_K FLOAT,
    last_D FLOAT,
    K_value FLOAT,
    D_value FLOAT
)
AS
BEGIN
    DECLARE @k_value FLOAT 
    DECLARE @d_value FLOAT
    DECLARE @yesterday_k_value FLOAT
    DECLARE @yesterday_d_vlaue FLOAT
    DECLARE @today_date DATE

    DECLARE cur CURSOR LOCAL FOR
    SELECT [date], K_value, D_value
    FROM ncudb.dbo.stock_price
    WHERE stock_code = @target_stock
    ORDER BY [date] ASC

    OPEN cur
    FETCH NEXT FROM cur INTO @today_date, @yesterday_k_value, @yesterday_d_vlaue

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @yesterday_k_value = @k_value
        SET @yesterday_d_vlaue = @d_value
        FETCH NEXT FROM cur INTO @today_date, @k_value, @d_value
        IF @k_value > @d_value AND @yesterday_k_value < @yesterday_d_vlaue AND @yesterday_d_vlaue <= 20 AND @yesterday_k_value <= 20
        BEGIN
            INSERT INTO @result_table
            VALUES (@target_stock, @today_date, '黃金交叉', @yesterday_k_value, @yesterday_d_vlaue, @k_value, @d_value)
        END
        ELSE IF @k_value < @d_value AND @yesterday_k_value > @yesterday_d_vlaue AND @yesterday_d_vlaue >= 80 AND @yesterday_k_value >= 80
        BEGIN
            INSERT INTO @result_table
            VALUES (@target_stock, @today_date, '死亡交叉', @yesterday_k_value, @yesterday_d_vlaue, @k_value, @d_value)
        END
    END

    CLOSE cur
    DEALLOCATE cur
    RETURN 
END
