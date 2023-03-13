import calendar
import pymssql
from datetime import date
from dateutil.rrule import rrule, DAILY
from selenium import webdriver
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from webdriver_manager.microsoft import EdgeChromiumDriverManager

# 根據自己的Database來填入資訊
db_settings = {
    "host": "172.30.52.193",
    "user": "sa",
    "password": "255089",
    "database": "ncudb",
    "charset": "utf8"
}

# 特殊節日
holiday_dir = {}
# holiday_dir = {'2023-01-02': '中華民國開國紀念日(補假)', '2023-01-18': '交易所休市(辦理結算交割)', '2023-01-19': '交易所休市(辦理結算交割)', '2023-01-20': '春節除夕前一日調整假日(0107補上班但交易所不交易)', '2023-01-23': '春節', '2023-01-24': '春節', '2023-01-25': '春節(補假0121春節除夕)', '2023-01-26': '春節(補假0122春節初一)', '2023-01-27': '春節調整假日(0204補上班但交易所不交易)',
#                '2023-02-27': '和平紀念日調整假日(0218補上班但交易所不交易)', '2023-02-28': '和平紀念日', '2023-04-03': '兒童節調整假日(0325補上班但交易所不交易)', '2023-04-04': '兒童節', '2023-04-05': '民族掃墓節', '2023-05-01': '勞動節', '2023-06-22': '端午節', '2023-06-23': '端午節調整假日(0617補上班但交易所不交易)', '2023-09-29': '中秋節', '2023-10-09': '國慶日調整假日(0923補上班但交易所不交易)', '2023-10-10': '國慶日'}

# 爬蟲


def crawler():

    # 這邊是用Edge作為範例，可以依照你使用瀏覽器的習慣做修改
    options = EdgeOptions()
    options.add_argument("--headless")  # 執行時不顯示瀏覽器
    options.add_argument("--disable-notifications")  # 禁止瀏覽器的彈跳通知
    # options.add_experimental_option("detach", True)  # 爬蟲完不關閉瀏覽器
    edge = webdriver.Edge(
        EdgeChromiumDriverManager().install(), options=options)

    edge.get("https://www.wantgoo.com/global/holiday/twse")
    try:
        # 等元件跑完再接下來的動作，避免讀取不到內容
        WebDriverWait(edge, 10).until(EC.presence_of_all_elements_located(
            (By.XPATH, "//tbody[@id='holidays']//tr//th")))
        # 練習1
        holiday_table = edge.find_elements(
            By.XPATH, '//tbody[@id="holidays"]//tr')
        for holiday in holiday_table:
            info = holiday.text.split(" ")
            # format date
            date = info[0].split("/")
            date = '-'.join(date)
            holiday_dir.update({date: info[2]})

    except TimeoutException as e:
        print(e)
    # edge.close()


# 載入SQL
def insertSQL():
    # 非休市日
    work_count = 0
    try:
        conn = pymssql.connect(**db_settings)
        # 請根據自己的資料表修改command
        command = "INSERT INTO [dbo].[Calendars] (date, day_of_stock, other) VALUES (%s, %d, %s)"
        # 練習1
        cursor = conn.cursor()
        start_date = date(2023, 1, 1)
        end_date = date(2023, 12, 31)

        for day in rrule(DAILY, dtstart=start_date, until=end_date):
            date_str = day.strftime("%Y-%m-%d")
            other = holiday_dir.get(date_str)
            if other is None and (day.weekday() != 5 and day.weekday() != 6):
                work_count += 1
                cursor.execute(command, (date_str, work_count, other))
            else:
                cursor.execute(command, (date_str, -1, other))
    except Exception as e:
        print(e)
    conn.commit()
    conn.close()


crawler()
insertSQL()
