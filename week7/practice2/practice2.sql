USE ncudb
GO
CREATE OR ALTER PROCEDURE [dbo].[price_type]
    @company_input VARCHAR(10),
    @setting_days INT,
    @setting_date DATE,
    @type INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @sqltext VARCHAR(1000)
    CREATE TABLE #stock_temp(
        company_temp VARCHAR(10),
        date_temp DATE,
        h_temp BIGINT
    )
    DECLARE @is_workingday INT
    DECLARE @high_def FLOAT
    DECLARE @low_def FLOAT
    SET @type = 99

    SELECT @is_workingday = day_of_stock FROM dbo.calendar WHERE [date] = @setting_date
    IF @is_workingday = -1 RETURN

    SELECT @high_def=high, @low_def=low FROM dbo.price_type_def WHERE @setting_days=compare_with

    SET @sqltext = 'SELECT TOP(' + CAST(@setting_days AS VARCHAR) + ') stock_code, [date], h FROM dbo.stock_price WHERE stock_code = ''' + @company_input + ''' AND [date] <= ''' + CAST(@setting_date AS VARCHAR) + ''' ORDER BY [date] DESC'
    INSERT INTO #stock_temp(company_temp, date_temp, h_temp) EXEC(@sqltext)

    DECLARE @temp INT
    SELECT @temp = ROWID FROM (
        SELECT ROW_NUMBER() OVER(ORDER BY h_temp DESC) AS ROWID, * FROM #stock_temp) T1
    WHERE T1.date_temp = @setting_date


    IF @temp <= @high_def * @setting_days
        SET @type = 1
    ELSE IF @temp >= @setting_days - (@low_def * @setting_days)
        SET @type = -1
    ELSE
        SET @type = 0

    DROP TABLE #stock_temp
END