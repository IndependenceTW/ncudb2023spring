USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[find_trend]
(
    @company VARCHAR(10)
)
RETURNS @result_table TABLE
(
    [start_date] DATE,
    [start_date_price] REAL,
    [end_date] DATE,
    [end_date_price] REAL,
    [trend] INT -- -1 空頭, 1 多頭 , 0 盤整
)
AS
BEGIN
    DECLARE @max_min_point TABLE
    (
        [date] DATE NOT NULL,
        [price] REAL NOT NULL,
        [min_or_max] INT -- 1: min, -1: max
    )
    INSERT INTO @max_min_point ([date], [price], [min_or_max])
    SELECT [date], [price], [min_or_max]
    FROM [dbo].[find_min_max](@company)
    ORDER BY [date] DESC

    DECLARE @tem_max_min_point TABLE
    (
        --新極日期與價格
        extremum_new REAL,
        date_new DATE,
        --舊極日期與價格
        extremum_old REAL,
        date_old DATE,
        --min -1, max 1
        extremum_type INT
    )
    INSERT INTO @tem_max_min_point
    SELECT T1.price, T1.date, T2.price, T2.date, T1.min_or_max
    FROM @max_min_point AS T1
    CROSS APPLY(
        SELECT TOP 1 * FROM @max_min_point
        WHERE min_or_max = T1.min_or_max AND date < T1.date
        ORDER BY date DESC
    ) T2
    
    INSERT INTO @result_table
    SELECT start_date, start_date_price, end_date, end_date_price, trend
    FROM (
        SELECT 
        T1.date_old AS start_date,
        T1.extremum_old AS start_date_price,
        T1.date_new AS end_date,
        T1.extremum_new AS end_date_price,
        CASE 
            WHEN T1.extremum_new > T1.extremum_old AND T2.extremum_new > T2.extremum_old THEN 1
            WHEN T1.extremum_new < T1.extremum_old AND T2.extremum_new < T2.extremum_old THEN -1
            ELSE 0
        END AS trend
        FROM @tem_max_min_point AS T1
        CROSS APPLY (
            SELECT TOP(1) * FROM @tem_max_min_point
            WHERE (
                date_new <= T1.date_new AND extremum_type != T1.extremum_type
            )
            ORDER BY date_new DESC
        ) T2
    ) RESULT

    RETURN
END
