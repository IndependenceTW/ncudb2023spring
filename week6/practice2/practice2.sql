USE [ncudb]
GO
CREATE PROCEDURE MA_Analysis
    @company VARCHAR(10),
    @target1 VARCHAR(10),
    @target2 VARCHAR(10),
    @result CHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @trend INT, @daily_trend INT
    DECLARE @day INT = 0
    DECLARE @ma1 REAL, @ma2 REAL
    DECLARE @analysis_table TABLE (MA1 REAL, MA2 REAL)
    DECLARE @command VARCHAR(100) = 'SELECT ' + @target1 + ', ' + @target2 + ' FROM stock_price WHERE stock_code=''' + @company + ''' ORDER BY date DESC'

    INSERT INTO @analysis_table
    EXEC(@command)

    DECLARE cur CURSOR LOCAL FOR SELECT * FROM @analysis_table
    OPEN cur

    FETCH NEXT FROM cur INTO @ma1, @ma2
    WHILE @@FETCH_STATUS = 0
    BEGIN

        IF @ma1 > @ma2
            SET @daily_trend = 1
        ELSE IF @ma1 < @ma2
            SET @daily_trend = -1
        ELSE
            SET @daily_trend = 0

        IF @day = 0
            SET @trend = @daily_trend
        ELSE IF @daily_trend != @trend
            BREAK

        SET @day = @day + 1
        FETCH NEXT FROM cur INTO @ma1, @ma2
    END

    IF @trend = 1
        SET @result = @target1 + ' over ' + @target2 + ' ' + CAST(@day AS VARCHAR(10)) + ' days'
    ELSE IF @trend = -1
        SET @result = @target1 + ' under ' + @target2 + ' ' + CAST(@day AS VARCHAR(10)) + ' days'
    ELSE
        SET @result = @target1 + ' equal ' + @target2 + ' ' + CAST(@day AS VARCHAR(10)) + ' days'
END 