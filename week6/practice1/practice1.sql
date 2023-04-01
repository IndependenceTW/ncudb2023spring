USE [ncudb]
GO
ALTER PROCEDURE [dbo].[Trend_Analysis]
(
    @company VARCHAR(10),
    @day INT OUTPUT,
    @result CHAR(50) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @c REAL
    DECLARE @MA5 REAL
    DECLARE @MA10 REAL
    DECLARE @MA20 REAL
    DECLARE @Trend INT
    DECLARE @DailyTrend INT

    DECLARE cur CURSOR LOCAL FOR
    SELECT c, MA5, MA10, MA20 
    from stock_price
    WHERE stock_code = @company 
    ORDER BY [date] DESC
    open cur

    FETCH NEXT FROM cur INTO @c, @MA5, @MA10, @MA20
    set @day=0
    while @@FETCH_STATUS = 0 BEGIN
        if (@c > @MA5 AND @MA5 > @MA10 AND @MA10 > @MA20)
            SET @DailyTrend = 1
        ELSE IF (@c < @MA5 AND @MA5 < @MA10 AND @MA10 < @MA20)
            SET @DailyTrend = -1
        ELSE
            SET @DailyTrend = 0
        
        if(@day = 0)
            SET @Trend = @DailyTrend
        ELSE IF (@DailyTrend != @Trend)
            BREAK

        set @day = @day + 1
        FETCH NEXT FROM cur INTO @c, @MA5, @MA10, @MA20
    END

    if(@Trend = 1)
        set @Result='Up trend'
    ELSE IF (@Trend = -1)
        set @Result='Down trend'
    ELSE
        set @Result='Consolidate'
    close cur
    DEALLOCATE cur

END
