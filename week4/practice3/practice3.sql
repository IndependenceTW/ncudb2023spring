USE [ncudb]
GO
--stonks meme--
ALTER PROCEDURE [dbo].[find_stonks_by_date]
    @search_date DATE,
    @days INT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @dates TABLE([date] DATE)
    INSERT INTO @dates
    -- Get a list of databases
    SELECT [Date]
    FROM dbo.find_date(@search_date, @days, 1, 0)
    SELECT *
    FROM (
        SELECT [stock_code], COUNT(*) cnt, STRING_AGG([date], ',') [date]
        FROM stock_price
        WHERE EXISTS(
        SELECT [date]
            FROM @dates
            WHERE [date]=stock_price.[date]
        ) AND d >= 0
        GROUP BY [stock_code]
    ) result
    WHERE result.cnt = @days
END