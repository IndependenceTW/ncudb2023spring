USE [ncudb]
GO
ALTER PROCEDURE [dbo].[MA_Trend_By_Percent]
    @MA1_input VARCHAR(10),
    @MA2_input VARCHAR(10),
    @duration INT,
    @target_percent REAL, -- 0.1 means 10%
    @trend_input INT -- 1 means up, -1 means down
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @stock_code VARCHAR(10)
    DECLARE @sql_command NVARCHAR(1000)
    DECLARE @parm_definition NVARCHAR(500)
    DECLARE @date DATE 
    SELECT @date=MAX([date]) FROM stock_price

    DECLARE @i INT
    DECLARE @code VARCHAR(10)
    DECLARE @MA1_value REAL
    DECLARE @MA2_value REAL
    DECLARE @now_percent REAL

    CREATE TABLE #stock(
        stock_code VARCHAR(10)
    )
    CREATE TABLE #stock_temp(
        id INT IDENTITY(1, 1),
        [date] DATE NOT NULL,
        stock_code VARCHAR(10) NOT NULL,
        MA_1 REAL NOT NULL,
        MA_2 REAL NOT NULL
    )

    CREATE TABLE #dates(
        [date] DATE,
        day_of_stock INT
    )
    INSERT INTO #dates
    EXEC [dbo].[find_date] @date, @duration, 1, 0

    DECLARE cur CURSOR LOCAL FOR SELECT DISTINCT stock_code FROM dbo.stock_price
    OPEN cur
    FETCH NEXT FROM cur INTO @stock_code

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql_command = N'SELECT [date], stock_code, '+ @MA1_input + ',' + @MA2_input +' FROM stock_price WHERE [date] IN (SELECT [date] FROM #dates) AND stock_code=@code_input ORDER BY [date]'
        SET @parm_definition = N'@code_input VARCHAR(10)'
        
        DELETE FROM #stock_temp
        INSERT INTO #stock_temp([date], stock_code, MA_1, MA_2)
        EXEC sp_executesql @sql_command, @parm_definition, @code_input=@stock_code

        WHILE EXISTS(SELECT * FROM #stock_temp)
        BEGIN
            SELECT TOP(1) @i=id, @code=stock_code, @MA1_value=MA_1, @MA2_value=MA_2 FROM #stock_temp
            SET @now_percent = (@MA1_value - @MA2_value) / @MA2_value
            IF (@now_percent >= @target_percent AND @trend_input = 1) OR (@now_percent <= -@target_percent AND @trend_input = -1)
            BEGIN
                INSERT INTO #stock (stock_code)
                VALUES (@code)
                BREAK 
            END
            DELETE #stock_temp WHERE id=@i
        END

        FETCH NEXT FROM cur INTO @stock_code
    END

    CLOSE cur
    DEALLOCATE cur
    SELECT * FROM #stock
END