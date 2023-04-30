USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[GB_rule1]
(
    @company varchar(10)
)
RETURNS @result_table TABLE
(
    [date] DATE
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
    DECLARE @close REAL

    INSERT INTO @temp_table
    SELECT [date], [today_c], [today_ma], [trend] FROM ncudb.dbo.find_MA_updown(@company, 8, 6)

    DECLARE cur CURSOR LOCAL FOR
        SELECT [date], [trend], [close], [MA20] FROM @temp_table ORDER BY [date] ASC
    OPEN cur

    FETCH NEXT FROM cur INTO @now_date, @now_trend, @close, @ma
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @last_trend = @now_trend
        FETCH NEXT FROM cur INTO @now_date, @now_trend, @close, @ma

        SET @flag = 
        CASE 
            WHEN @last_trend = -1 AND @now_trend = 0 THEN 1
            WHEN @last_trend = -1 AND @now_trend = 1 THEN 1
            WHEN @now_trend = -1 THEN 0
            ELSE @flag
        END

        IF @flag = 1 AND @close > @ma
        BEGIN
            INSERT INTO @result_table([date]) VALUES(@now_date)
            SET @flag = 0
        END
    END

    RETURN
END