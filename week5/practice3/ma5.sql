USE [ncudb]
GO
ALTER PROCEDURE [MA_calculation]
    @date char(10),
    @stock_code varchar(10),
    @days int
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @MA REAL

    SELECT @MA = AVG([c])
    FROM stock_price
    WHERE [date] in (SELECT [date]
        FROM find_date(@date, @days, 1, 0)) AND stock_code = @stock_code

    UPDATE stock_price
    SET MA5 = IIF(@days=5, @MA, MA5),
        MA10 = IIF(@days=10, @MA, MA10),
        MA20 = IIF(@days=20, @MA, MA20),
        MA60 = IIF(@days=60, @MA, MA60),
        MA120 = IIF(@days=120, @MA, MA120),
        MA240 = IIF(@days=240, @MA, MA240)
    WHERE [date] = @date AND stock_code = @stock_code
END