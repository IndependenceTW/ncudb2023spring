USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[find_min_max]
(
    @company varchar(10)
)
RETURNS @min_max_table TABLE
(
    [date] DATE,
    [price] REAL,
    [min_or_max] INT -- 1: max, -1: min
)
AS
BEGIN
    DECLARE @trend_table TABLE
    (
        [date] DATE,
        [price] REAL,
        [trend] INT
    )

    INSERT INTO @trend_table([date], [price], [trend])
    SELECT [date], [close_price], [cur_trend]
    FROM [dbo].[find_crossover_date](@company, 3)

    DECLARE cur CURSOR LOCAL FOR
        SELECT [date], [price], [trend]
        FROM @trend_table
        ORDER BY [date] ASC
    OPEN cur

    DECLARE @cur_date DATE, @cur_price REAL, @cur_trend INT
    DECLARE @max_min_date DATE, @max_min_price REAL
    DECLARE @compare_trend INT

    FETCH NEXT FROM cur INTO @cur_date, @cur_price, @cur_trend
    SET @max_min_date = @cur_date
    SET @max_min_price = @cur_price
    SET @compare_trend = @cur_trend

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @cur_trend != @compare_trend
        BEGIN
            INSERT INTO @min_max_table([date], [price], [min_or_max])
            VALUES (@max_min_date, @max_min_price, @compare_trend)
            SET @max_min_date = @cur_date
            SET @max_min_price = @cur_price
            SET @compare_trend = @cur_trend
        END
        
        IF @compare_trend = 1
        BEGIN
            IF @cur_price > @max_min_price
            BEGIN
                SET @max_min_date = @cur_date
                SET @max_min_price = @cur_price
            END
        END
        ELSE
        BEGIN
            IF @cur_price < @max_min_price
            BEGIN
                SET @max_min_date = @cur_date
                SET @max_min_price = @cur_price
            END
        END

        FETCH NEXT FROM cur INTO @cur_date, @cur_price, @cur_trend
    END

    CLOSE cur
    DEALLOCATE cur
    RETURN
END