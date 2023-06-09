USE [ncudb]
GO
/****** Object:  StoredProcedure [dbo].[GB_aggregation]    Script Date: 2023/5/20 下午 09:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[GB_aggregation]
	-- Add the parameters for the stored procedure here
	@company VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--part1
	DECLARE @part1 TABLE
	(
		date DATE,
		price real,
		buy_or_sell INT
	)

	DECLARE @mid TABLE
	(
		date DATE,
		buy_or_sell INT
	)

	DECLARE @mid2 TABLE
	(
		date DATE,
		price real,
		buy_or_sell INT
	)

	CREATE TABLE #temp_table(
		stock_code VARCHAR(100),
		date DATE,
		result VARCHAR(20),
		yK real,
		yD real,
		tK real,
		tD real
	)

    -- Insert statements for procedure here
	INSERT INTO @mid
	SELECT * FROM GB_rule1_5(@company)

	INSERT INTO @mid
	SELECT * FROM GB_rule2_6(@company, 3)

	INSERT INTO @mid
	SELECT * FROM GB_rule3_7(@company, 2, 8, 3, 5, 3)

	INSERT INTO @mid
	SELECT * FROM GB_rule4_8(@company, 15, -10)

	INSERT INTO #temp_table(stock_code, date, result, yK, yD, tK, tD)
	SELECT stock_code, [date], cross_type, last_K, last_D, K_value, D_value
	FROM dbo.find_KD_cross(@company)

	ALTER TABLE #temp_table DROP COLUMN stock_code, yK, yD, tK, tD

	UPDATE #temp_table
	SET result = -1 WHERE result = '死亡交叉'

	UPDATE #temp_table
	SET result = 1 WHERE result = '黃金交叉'

	INSERT INTO @mid
	SELECT * FROM #temp_table

	INSERT INTO @mid2(date, price)
	SELECT date, c FROM stock_price
	WHERE stock_price.date in (SELECT date FROM @mid) and stock_price.stock_code = @company

	INSERT INTO @part1
	SELECT mid2.date, mid2.price, mid.buy_or_sell
    FROM
        (SELECT * FROM @mid2) mid2
    FULL JOIN
        (SELECT * FROM @mid) mid
    ON (mid2.date = mid.date)

	DROP TABLE #temp_table

	--SELECT * FROM @part1
	
	
	--part2
	DECLARE @result TABLE
	(
		date DATE,
		price real,
		buy_or_sell INT,
		asset real,
		stock_hold INT
	)

	INSERT INTO @result(date, price, buy_or_sell)
	SELECT * FROM @part1

	DECLARE @bos INT
	DECLARE @temp_asset INT = 0
	DECLARE @price real
	DECLARE @date DATE
	DECLARE @magnification INT = 3
	DECLARE @previous_bos INT
	DECLARE @hold_stock INT = 0

	DECLARE cur CURSOR LOCAL FOR
		SELECT date, price, buy_or_sell FROM @part1 ORDER BY [date]
	OPEN cur

	FETCH NEXT FROM cur INTO @date, @price, @bos
	SET @previous_bos = @bos

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @bos = 1
		BEGIN
			IF @previous_bos != 1
				SET @magnification = 3

			SET @temp_asset = @temp_asset - (@magnification * @price)

			SET @hold_stock = @hold_stock + @magnification
			IF @magnification > 1
				SET @magnification = @magnification - 1
			SET @previous_bos = 1

			UPDATE @result
			SET stock_hold = @hold_stock
			WHERE date = @date
		END

		ELSE IF (@bos = -1 and @hold_stock > 0)
		BEGIN
			IF @previous_bos != -1
				SET @magnification = 3

			IF @hold_stock < @magnification
			BEGIN
				SET @temp_asset = @temp_asset + (@hold_stock * @price)
				SET @hold_stock = 0
			END
			ELSE
			BEGIN
				SET @temp_asset = @temp_asset + (@magnification * @price)
				SET @hold_stock = @hold_stock - @magnification
			END

			IF @magnification > 1
				SET @magnification = @magnification - 1
			SET @previous_bos = -1

			UPDATE @result
			SET stock_hold = @hold_stock
			WHERE date = @date
		END

		ELSE IF (@bos = -1 and @hold_stock = 0)
		BEGIN
			UPDATE @result
			SET stock_hold = @hold_stock
			WHERE date = @date
		END

		UPDATE @result
		SET asset = @temp_asset
		WHERE date = @date

		FETCH NEXT FROM cur INTO @date, @price, @bos
	END

	SELECT * FROM @result
END
