USE ncudb
GO
CREATE OR ALTER FUNCTION [dbo].[slope_calculate]
(
    @company VARCHAR(10),
    @begin_date DATE,
    @end_date DATE
)
RETURNS real
AS
BEGIN
    DECLARE @days int = (
        SELECT COUNT(*) FROM [dbo].[calendar]
        WHERE [date] > @begin_date 
        AND [date] <= @end_date 
        AND [day_of_stock] != -1
    )

    DECLARE @begin_price REAL = (SELECT c FROM stock_price WHERE stock_code=@company AND [date] = @begin_date)
    DECLARE @end_price REAL = (SELECT c FROM stock_price WHERE stock_code=@company AND [date] = @end_date)

    DECLARE @result REAL = (@end_price - @begin_price) / @days
    return @result

END