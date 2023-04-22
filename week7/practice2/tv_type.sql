USE ncudb
GO
CREATE OR ALTER PROCEDURE [dbo].[tradingVolume_type]
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
        tv_temp BIGINT
    )
    DECLARE @is_workingday INT
    DECLARE @veryHigh_def FLOAT
    DECLARE @high_def FLOAT
    DECLARE @low_def FLOAT
    DECLARE @veryLow_def FLOAT
    SET @type = 99

    SELECT @is_workingday = day_of_stock FROM dbo.calendar WHERE [date] = @setting_date
    IF @is_workingday = -1 RETURN

    SELECT @veryHigh_def = veryHigh_value, @high_def = high_value, @low_def = low_value, @veryLow_def = veryLow_value FROM dbo.tradingVolume_def WHERE compare_with = @setting_days

    SET @sqltext = 'SELECT TOP(' + CAST(@setting_days AS VARCHAR) + ') stock_code, [date], tv FROM dbo.stock_price WHERE stock_code = ''' + @company_input + ''' AND [date] <= ''' + CAST(@setting_date AS VARCHAR) + ''' ORDER BY [date] DESC'
    INSERT INTO #stock_temp(company_temp, date_temp, tv_temp) EXEC(@sqltext)

    DECLARE @temp INT
    SELECT @temp = ROWID FROM (
        SELECT ROW_NUMBER() OVER(ORDER BY tv_temp DESC) AS ROWID, * FROM #stock_temp) T1
    WHERE T1.date_temp = @setting_date

    IF @temp <= @veryHigh_def * @setting_days
        SET @type = 2
    ELSE IF @temp <= @high_def * @setting_days
        SET @type = 1
    ELSE IF @temp >= @setting_days - (@veryLow_def * @setting_days)
        SET @type = -2
    ELSE IF @temp >= @setting_days - (@low_def * @setting_days)
        SET @type = -1
    ELSE
        SET @type = 0
END