USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[GB_rule2_6]
(
    @company varchar(10),
    @days INT
)
RETURNS @result_table TABLE
(
    [date] DATE,
    buy_or_sell INT
)
AS
BEGIN
    -- 建立暫存表
    DECLARE @temp_table TABLE (
        [date] date,
        trend INT,
        yesterday_c REAL,
        today_c REAL,
        yesterday_ma REAL,
        today_ma REAL
    )

    -- 將資訊放入暫存表中
    INSERT INTO @temp_table
    SELECT [date], trend, yesterday_c, today_c, yesterday_ma, today_ma
    FROM [dbo].find_MA_updown('2330', 8, 6)

    -- 變數宣告
    DECLARE @date DATE, @trend INT, @yesterday_c REAL, @today_c REAL, @yesterday_ma REAL, @today_ma REAL
    DECLARE @result_date DATE

    -- 開啟cursor 逐行確認
    DECLARE cur CURSOR LOCAL FOR
        SELECT [date], trend, yesterday_c, today_c, yesterday_ma, today_ma
        FROM @temp_table
        ORDER BY [date] ASC

    OPEN cur
    FETCH NEXT FROM cur INTO @date, @trend, @yesterday_c, @today_c, @yesterday_ma, @today_ma

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 符合上升趨勢並收盤跌破平均線
        IF @trend = 1 AND @yesterday_c > @yesterday_ma AND @today_c < @today_ma
        BEGIN
        -- 往後查詢是否有在漲破平均線
            SET @result_date = (
                SELECT TOP (1) [date]
                FROM @temp_table t1
                WHERE EXISTS (
                    SELECT [date] FROM dbo.find_date_func(@date, @days, 0, 1)
                    WHERE [date] = t1.[date]
                )
                AND t1.today_c > t1.today_ma
                AND NOT EXISTS (
                    SELECT [date] FROM @result_table t2
                    WHERE t1.[date] = t2.[date]
                )
            )

            IF @result_date IS NOT NULL
            BEGIN
                INSERT INTO @result_table
                VALUES (@result_date, 1)
            END

        END
        -- 符合下降趨勢並收盤漲破平均線
        IF @trend = -1 AND @yesterday_c < @yesterday_ma AND @today_c > @today_ma
        BEGIN
        -- 往後查詢是否有在跌破平均線
            SET @result_date = (
                SELECT TOP (1) [date]
                FROM @temp_table t1
                WHERE EXISTS (
                    SELECT [date] FROM dbo.find_date_func(@date, @days, 0, 1)
                    WHERE [date] = t1.[date]
                )
                AND t1.today_c < t1.today_ma
                AND NOT EXISTS (
                    SELECT [date] FROM @result_table t2
                    WHERE t1.[date] = t2.[date]
                )
            )

            IF @result_date IS NOT NULL
            BEGIN
                INSERT INTO @result_table
                VALUES (@result_date, -1)
            END
        END
        FETCH NEXT FROM cur INTO @date, @trend, @yesterday_c, @today_c, @yesterday_ma, @today_ma
    END
    CLOSE cur
    DEALLOCATE cur
    RETURN
END