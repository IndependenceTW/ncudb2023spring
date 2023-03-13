import pymssql
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from webdriver_manager.microsoft import EdgeChromiumDriverManager

db_settings = {
    "host": "172.30.52.193",
    "user": "sa",
    "password": "255089",
    "database": "ncudb",
    "charset": "utf8"
}

# 儲存台灣50前10的陣列
taiwan50 = []
# taiwan50 = ['台積電', '鴻海', '聯發科', '台達電', '聯電', '中華電', '富邦金', '南亞', '中信金', '國泰金']

# 搜尋台灣50前10


def find_Taiwan50():
    # 這邊是用Edge作為範例，可以依照你使用瀏覽器的習慣做修改
    options = EdgeOptions()
    options.add_argument("--headless")  # 執行時不顯示瀏覽器
    options.add_argument("--disable-notifications")  # 禁止瀏覽器的彈跳通知
    # options.add_experimental_option("detach", True) # 爬蟲完不關閉瀏覽器
    edge = webdriver.Edge(
        EdgeChromiumDriverManager().install(), options=options)

    edge.get("https://www.cmoney.tw/etf/tw/0050")

    # 練習2
    try:
        WebDriverWait(edge, 10).until(EC.presence_of_all_elements_located(
            (By.XPATH, "//h3[text()='前10大成分股']/following-sibling::div//tbody//tr//td")))
        taiwan50_table = edge.find_elements(
            By.XPATH, '//h3[text()="前10大成分股"]/following-sibling::div//tbody//div[@class="stock__thead text-left"]')
        for stock in taiwan50_table:
            taiwan50.append(stock.text)
    except TimeoutException as e:
        print(e)

    # edge.close()

# 載入SQL (若為台灣50前10，isTaiwan50 = 1)


def find_stock(url, start, end):
    command = "INSERT INTO [dbo].[StockInfo] (stock_code, name, type, category, isTaiwan50) VALUES (%s, %s, %s, %s, %d)"

    try:
        conn = pymssql.connect(**db_settings)
        # 練習2
        cursor = conn.cursor()
        response = requests.get(url)
        soup = BeautifulSoup(response.text, "html.parser")

        # get the start
        result = soup.select("b:-soup-contains('{}')".format(start))
        start_element = result[0].parent.parent

        # get the end
        result = soup.select("b:-soup-contains('{}')".format(end))
        end_element = result[0].parent.parent

        # iterate the element between start and end
        now_element = start_element.nextSibling
        while (now_element is not end_element):
            stock_info = now_element.find_all('td')
            info_string = [e.text for e in stock_info]
            id_and_name = info_string[0].split()
            cursor.execute(command,
                           (id_and_name[0],
                            id_and_name[1],
                            info_string[3],
                            info_string[4],
                            1 if id_and_name[1] in taiwan50 else 0))
            now_element = now_element.nextSibling
    except Exception as e:
        print(e)

    conn.commit()
    conn.close()


find_Taiwan50()
# print(taiwan50)
find_stock("https://isin.twse.com.tw/isin/C_public.jsp?strMode=4", "股票", "特別股")
find_stock("https://isin.twse.com.tw/isin/C_public.jsp?strMode=2",
           "股票", "上市認購(售)權證")
