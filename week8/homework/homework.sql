USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[GB_rule1_5]
(
    @company varchar(10)
)
RETURNS @result_table TABLE
(
    [date] DATE,
    buy_or_sell INT
)
AS
BEGIN
    DECLARE @temp_table TABLE
    (
        [date] DATE,
        [close] REAL,
        [MA20] REAL,
        [trend] INT
    )
    DECLARE @now_trend INT
    DECLARE @last_trend INT
    DECLARE @flag INT = 0
    DECLARE @now_date DATE
    DECLARE @ma REAL
    DECLARE @last_ma REAL
    DECLARE @close REAL
    DECLARE @last_close REAL
    DECLARE @cross INT = 0

    INSERT INTO @temp_table
    SELECT [date], [today_c], [today_ma], [trend] FROM ncudb.dbo.find_MA_updown(@company, 8, 6)

    DECLARE cur CURSOR LOCAL FOR
        SELECT [date], [trend], [close], [MA20] FROM @temp_table ORDER BY [date] ASC
    OPEN cur

    FETCH NEXT FROM cur INTO @now_date, @now_trend, @close, @ma
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @last_trend = @now_trend
        SET @last_ma = @ma
        SET @last_close = @close
        FETCH NEXT FROM cur INTO @now_date, @now_trend, @close, @ma

        SET @cross = 
        CASE 
            WHEN @last_close > @last_ma AND @close < @ma THEN -1
            WHEN @last_close < @last_ma AND @close > @ma THEN 1
            ELSE @cross
        END

        SET @flag = 
        CASE 
            WHEN @last_trend = -1 AND @now_trend = 0 THEN 1
            WHEN @last_trend = -1 AND @now_trend = 1 THEN 1
            WHEN @last_trend = 1 AND @now_trend = 0 THEN -1
            WHEN @last_trend = 1 AND @now_trend = -1 THEN -1
            ELSE @flag
        END

        IF @flag = 1 AND @close > @ma AND @cross = 1
        BEGIN
            INSERT INTO @result_table([date], buy_or_sell) VALUES(@now_date, 1)
            SET @flag = 0
            SET @cross = 0
        END
        IF @flag = -1 AND @close < @ma AND @cross = -1
        BEGIN
            INSERT INTO @result_table([date], buy_or_sell) VALUES(@now_date, -1)
            SET @flag = 0
            SET @cross = 0
        END
    END

    RETURN
END