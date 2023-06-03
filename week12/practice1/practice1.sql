USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[slope_trend]
(
    @company VARCHAR(10),
    @interval_size INT,
    @statement_type NVARCHAR(20) = ''
)
RETURNS @result_table TABLE
(
    [start_date] DATE,
    start_date_price REAL,
    end_date DATE,
    end_date_price REAL,
    slope REAL,
    trend NVARCHAR(20)
)
AS
BEGIN
    DECLARE @date_select TABLE(
        [date] DATE NOT NULL,
        [close_price] REAL NOT NULL
    )
    IF @statement_type = 'Extremum_MAX'
    BEGIN
        INSERT @date_select ([date], close_price)
        SELECT [date], [price]
        FROM find_min_max(@company)
        WHERE min_or_max = 1
        ORDER BY [date] DESC
    END
    ELSE IF @statement_type = 'Extremum_MIN'
    BEGIN
        INSERT @date_select ([date], close_price)
        SELECT [date], [price]
        FROM find_min_max(@company)
        WHERE min_or_max = -1 
        ORDER BY [date] DESC 
    END
    ELSE IF @statement_type = 'Interval'
    BEGIN
        INSERT @date_select ([date], close_price)  
        SELECT T1.[date], T1.[c]
        FROM(
            SELECT ROW_NUMBER() OVER (ORDER BY [date] DESC) AS ROW, [date], c
            FROM stock_price
            WHERE stock_code = @company
        ) T1
        WHERE (T1.ROW % @interval_size) = 1
    END

    INSERT INTO @result_table([start_date], start_date_price, [end_date], end_date_price)
    SELECT T2.[date], T2.[close_price], T1.[date], T1.[close_price]
    FROM @date_select AS T1
    CROSS APPLY(
        SELECT TOP (1) * FROM @date_select
        WHERE [date] < T1.[date]
        ORDER BY DATE DESC
    ) T2

    UPDATE @result_table
    SET slope = dbo.slope_calculate(@company, [start_date], [end_date])

    UPDATE @result_table
    SET trend = (
        CASE 
            WHEN T1.slope > T2.slope AND T2.slope > 0 AND T1.slope > 0 THEN '價格加速上漲'
            WHEN T1.slope < T2.slope AND T2.slope > 0 AND T1.slope > 0 THEN '價格上漲趨緩'
            WHEN T1.slope > 0 AND T2.slope < 0 THEN '轉為上漲'
            WHEN T1.slope > T2.slope AND T2.slope < 0 AND T1.slope < 0 THEN '價格下跌趨緩'
            WHEN T1.slope < T2.slope AND T2.slope < 0 AND T1.slope < 0 THEN '價格加速下跌'
            WHEN T1.slope < 0 AND T2.slope > 0 THEN '轉為下跌'
            ELSE '價格持平'
        END
    )
    FROM @result_table AS T1
    CROSS APPLY(
        SELECT TOP (1) * FROM @result_table
        WHERE [start_date] < T1.[start_date]
        ORDER BY [start_date] DESC
    ) T2

    RETURN
END