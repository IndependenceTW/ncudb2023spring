USE [ncudb]
GO
ALTER PROCEDURE dbo.find_date
    @start_date DATE,
    @num_days INT,
    @included_date INT, -- not include 0, include 1
    @go_earlier_or_later INT -- go earlier 0, go later 1
AS
BEGIN
    DECLARE @from_day Date

    DECLARE @command NVARCHAR(1000) = N'
    SELECT TOP (@N) [date], day_of_stock
    FROM dbo.calendar 
    WHERE 
        (@e_or_l=0 AND @include=0 AND [date] < @start AND day_of_stock != -1)
        OR
        (@e_or_l=1 AND @include=0 AND [date] > @start AND day_of_stock != -1)
        OR
        (@e_or_l=0 AND @include=1 AND [date] <= @start AND day_of_stock != -1)
        OR
        (@e_or_l=1 AND @include=1 AND [date] >= @start AND day_of_stock != -1)
    ORDER BY CASE WHEN @e_or_l = 0 THEN [date] END DESC,
            CASE WHEN @e_or_l = 1 THEN [date] END ASC'

    DECLARE @params NVARCHAR(50) = N'@N INT, @start DATE, @e_or_l INT, @include INT'
    
    EXECUTE sp_executesql @command, @params, @N=@num_days, @start=@start_date, @e_or_l=@go_earlier_or_later, @include=@included_date
END
