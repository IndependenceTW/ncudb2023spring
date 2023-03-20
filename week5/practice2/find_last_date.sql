USE [ncudb]
GO
CREATE FUNCTION find_last_date
(	
	@date char(10)
)
RETURNS @date_table TABLE (

    [date] date NOT NULL
)
AS
BEGIN
    DECLARE @day_cnt int;

    SELECT @day_cnt = day_of_stock
    FROM calendar
    WHERE [date] = @date

    IF @day_cnt = 1 -- first date of this year which means we need to find last working day fo last year
    BEGIN
        INSERT @date_table
        SELECT TOP 1
            [date]
        FROM calendar
        WHERE (year([date]) = year(@date)-1) AND day_of_stock != -1
        ORDER BY [date] DESC;
    END

    ELSE -- find last working day of this year
    BEGIN
        INSERT @date_table
        SELECT MAX([date])
        FROM calendar
        WHERE [date] < @date AND day_of_stock != -1
    END
    RETURN
END