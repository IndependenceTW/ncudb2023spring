USE [ncudb]
GO
CREATE PROCEDURE [Row_MA_calculation]
    @date char(10),
    @stock_code varchar(10)
AS
BEGIN
    SET NOCOUNT ON

    EXECUTE [MA_calculation] @date, @stock_code, 5
    EXECUTE [MA_calculation] @date, @stock_code, 10
    EXECUTE [MA_calculation] @date, @stock_code, 20
    EXECUTE [MA_calculation] @date, @stock_code, 60
    EXECUTE [MA_calculation] @date, @stock_code, 120
    EXECUTE [MA_calculation] @date, @stock_code, 240
END