USE [ncudb]
GO
ALTER FUNCTION dbo.find_date
(
    @start_date DATE,
    @num_days INT,
    @included_date INT, -- not include 0, include 1
    @go_earlier_or_later INT -- go earlier 0, go later 1
)
RETURNS @dates TABLE
(
    [Date] DATE,
    [Day_of_Stock] INT,
    [Other] NVARCHAR(50)
)
AS
BEGIN
    --variable declaration
    DECLARE @day_cnt INT
    DECLARE @front_day INT
    DECLARE @to_day INT
    DECLARE @year_days INT
    --get start day of "day of stock"
    SELECT @day_cnt=day_of_stock
    FROM dbo.calendar
    WHERE [date]=@start_date
    --set earlier or later
    SET @front_day = IIF(@go_earlier_or_later=0, @day_cnt-@num_days+1, @day_cnt)
    SET @to_day = IIF(@go_earlier_or_later=0, @day_cnt, @day_cnt+@num_days-1)
    --set include start date or not
    IF @included_date=0
    BEGIN
        SET @front_day = IIF(@go_earlier_or_later=0, @front_day-1, @front_day+1)
        SET @to_day = IIF(@go_earlier_or_later=0, @to_day-1, @to_day+1)
    END

    IF @go_earlier_or_later=0
    BEGIN
        SELECT @year_days=total_day
        FROM year_calendar
        WHERE [year]=YEAR(@start_date)-1
    END
    ELSE
    BEGIN
        SELECT @year_days=total_day
        FROM year_calendar
        WHERE [year]=YEAR(@start_date)
    END

    INSERT INTO @dates
    SELECT *
    FROM calendar
    WHERE
        (day_of_stock BETWEEN @front_day AND @to_day
        AND YEAR([date])=YEAR(@start_date)
        AND day_of_stock != -1)
        OR
        (@front_day<=0
        AND @go_earlier_or_later=0
        AND day_of_stock>=@front_day+@year_days
        AND YEAR([date])=YEAR(@start_date)-1
        AND day_of_stock != -1)
        OR
        (@to_day>@year_days
        AND @go_earlier_or_later=1
        AND day_of_stock<=@to_day-@year_days
        AND YEAR([date])=YEAR(@start_date)+1
        AND day_of_stock != -1)

    RETURN
END