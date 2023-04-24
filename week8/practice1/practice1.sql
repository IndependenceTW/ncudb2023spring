USE [ncudb]
GO
CREATE OR ALTER FUNCTION [dbo].[find_MA_updown]
(
	@company varchar(10),
	@interval int , --往前抓的天數
	@change_interval int --決定上升或下降的天數，若沒有則視為平緩趨勢
)
RETURNS @MA_updown_trend TABLE
(
	company varchar(10),
	date date,
	yesterday_c real,
	today_c	 real,
	yesterday_MA real,
	today_MA real, 
	MA_diff INT, /* 判斷今日與昨日的MA為正或負 */
	trend INT, 	/* 1為上漲、-1為下跌、0為盤整 */
	counter_plus int,  /* 數前幾天共有多少今日MA>昨日MA */
	counter_minus int  /* 數前幾天共有多少今日MA<昨日MA */
)
AS
BEGIN
	/* 將公司、日期、MA20、昨日的MA20放入回傳的表中*/
	/* your code here */
	INSERT INTO @MA_updown_trend(company, [date], yesterday_c, today_c, yesterday_MA, today_MA)
    SELECT p1.stock_code AS company, p2.date AS today, p1.c AS yesterday_c, p2.c AS today_c, p1.MA20 AS yesterday_MA, p2.MA20 AS today_MA
    FROM stock_price p1
        INNER JOIN stock_price p2
        ON p1.stock_code = p2.stock_code
        INNER JOIN (
            SELECT DISTINCT t1.date AS yesterday, MIN(t2.date) AS today
            FROM stock_price t1
                INNER JOIN stock_price t2
                ON t1.stock_code = t2.stock_code
            WHERE t1.date < t2.date
            GROUP BY t1.stock_code, t1.date
        ) d ON yesterday=p1.date AND today=p2.date
    WHERE p1.stock_code = @company
    ORDER BY today

	
	/*更新MA_diff，若今天MA>昨日MA，則為1，反之則為-1*/
	UPDATE @MA_updown_trend
	SET MA_diff = 
	CASE
		WHEN date ='2021-01-04' THEN 0
		WHEN today_MA > yesterday_MA THEN 1
		WHEN today_MA < yesterday_MA THEN -1
		ELSE 0
	END

	DECLARE cur CURSOR LOCAL for
		SELECT date FROM @MA_updown_trend order by date asc
	open cur

	DECLARE @diff_plus INT
	DECLARE @diff_minus INT
	DECLARE @date_tmp date


	FETCH next from cur into @date_tmp

	WHILE @@FETCH_STATUS = 0 BEGIN
		/* your code here */
		/* 計算前面幾天有多少今日MA>昨日MA */
        SELECT @diff_plus = COUNT(*) FROM @MA_updown_trend WHERE [date] IN (SELECT TOP (@interval) [date] FROM @MA_updown_trend WHERE [date] <= @date_tmp ORDER BY [date] DESC) AND MA_diff = 1
		
		/* 計算前面幾天有多少今日MA<昨日MA */
        SELECT @diff_minus = COUNT(*) FROM @MA_updown_trend WHERE [date] IN (SELECT TOP (@interval) [date] FROM @MA_updown_trend WHERE [date] <= @date_tmp ORDER BY [date] DESC) AND MA_diff = -1
		
		
		/* 判斷上漲、下跌、平緩趨勢 */
		/* 更新 @MA_updown_trend */
        UPDATE @MA_updown_trend
        SET counter_plus = @diff_plus, 
            counter_minus = @diff_minus,
            trend = 
            CASE
                WHEN @diff_plus >= @change_interval THEN 1
                WHEN @diff_minus >= @change_interval THEN -1
                ELSE 0
            END
        WHERE [date] = @date_tmp

		FETCH next from cur into @date_tmp
	END
	CLOSE cur
	DEALLOCATE cur 
	return
END