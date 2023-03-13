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
    --variable declaration--
    DECLARE @front INT
    DECLARE @back INT
    DECLARE @day_cnt INT
    --include the start date or not--
    IF @included_date=1
    BEGIN
        SET @front = 0
        SET @back = @num_days-1
    END
    ELSE
    BEGIN
        SET @front = 1
        SET @back = @num_days
    END
    --decide go front or go back--
    If @go_earlier_or_later=0
    BEGIN
        DECLARE @temp INT
        SET @temp = @front * -1
        SET @front = @back * -1
        SET @back = @temp
    END
    --initial the day of stock--
    SELECT @day_cnt=[day_of_stock]
    FROM ncudb.dbo.calendar
    WHERE [date]=@start_date
    --select the return table--
    INSERT INTO @dates
    SELECT [date], [day_of_stock], [other]
    FROM ncudb.dbo.calendar
    WHERE YEAR([date])=YEAR(@start_date)
        AND day_of_stock-@day_cnt BETWEEN @front AND @back
        AND day_of_stock!=-1
    RETURN
END