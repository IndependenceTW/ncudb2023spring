USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[find_crossover_date]
(
    @company varchar(10),
    @change_interval int
)
RETURNS @trend_tmp TABLE
(
    [date] date NOT NULL,
    company VARCHAR(10) NOT NULL,
    MA_price REAL,
    close_price REAL NOT NULL,
    /*高於均線 1 低於均線 -1*/
    point_region INT,
    /*是(1)否(0)為交界點*/
    crossover_point INT,
    cur_trend INT,
    [counter] INT
)
AS
BEGIN
    INSERT INTO @trend_tmp([date], company, MA_price, close_price)
    SELECT [date], stock_code, MA5, c
    FROM [dbo].stock_price
    WHERE stock_code = @company

    UPDATE @trend_tmp
    SET point_region = CASE WHEN close_price > MA_price THEN 1 ELSE -1 END

    DECLARE cur CURSOR LOCAL FOR
        SELECT [date], company, point_region FROM @trend_tmp 
    OPEN cur
    DECLARE @current_trend INT
    DECLARE @day_change_count INT

    DECLARE @date_tmp DATE, @company_tmp VARCHAR(10), @point_region_tmp INT
    FETCH NEXT FROM cur INTO @date_tmp, @company_tmp, @point_region_tmp

    SET @current_trend = @point_region_tmp
    SET @day_change_count = 0
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @day_change_count = COUNT(*)
        FROM @trend_tmp
        WHERE point_region != @current_trend
        AND [date] IN (SELECT [date] FROM find_date_func(@date_tmp, @change_interval, 1, 0))

        IF @day_change_count >= @change_interval
        BEGIN
            UPDATE @trend_tmp
            SET crossover_point = 1
            WHERE [date] = @date_tmp
            IF @current_trend = 1
                SET @current_trend = -1
            ELSE
                SET @current_trend = 1
        END

        UPDATE @trend_tmp
        SET [counter] = @day_change_count, cur_trend=@current_trend
        WHERE [date] = @date_tmp

        FETCH NEXT FROM cur INTO @date_tmp, @company_tmp, @point_region_tmp
    END
    CLOSE cur
    DEALLOCATE cur
    RETURN
END