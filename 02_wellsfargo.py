import os
import csv
import time
import requests

from concurrent.futures import ThreadPoolExecutor
from loguru import logger
from parsel import Selector

# Construct the relative path to the zipcodes_list.csv file
zipcode_file_path = os.path.join('results', 'zipcodes.csv')
# Construct the relative path to the log file
log_file_path = os.path.join('results', 'wellsfargo.log')
# Construct the relative path to the result file
result_file_path = os.path.join('results', 'wellsfargo.csv')

# Set up log file
logger.add(log_file_path, level='INFO', encoding='utf-8')

def get_session():
    session = requests.Session()
    session.headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Pragma': 'no-cache',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0',
        'sec-ch-ua': '"Microsoft Edge";v="119", "Chromium";v="119", "Not?A_Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
    }
    return session


def get_datas(number, location):
    datas = []
    request_count_local = 0
    logger.info(f'Dealing with No.{number + 1} location：{location}')
    # Initialize fail count
    fail_count = 0
    session = get_session()

    # Iterate over pages
    for page in range(1, 70):
        request_count_local += 1
        if page == 1:
            params = {
                'searchAddress': location,
                'searchDistance': '75',
                'segment': '',
                'merchantName': '',
                'userAgent': 'false',
            }
            while True:
                try:
                    # Use proxies if you are outside America
                    # proxies = {'https': 'http://127.0.0.1:7890'}
                    proxies = None
                    response = session.get('https://retailservices.wellsfargo.com/locator/WFHALanding', params=params, proxies=proxies)
                    if 'The transaction failed.' in response.text:
                        session = get_session()
                        continue
                    if response.status_code == 200:
                        break
                except requests.RequestException:
                    pass

        else:
            params = {
                'pageIndex': (page - 1) * 25,
            }
            while True:
                try:
                    # Use proxies if you are outside America
                    # proxies = {'https': 'http://127.0.0.1:7890'}
                    proxies = None
                    response = session.get(
                        'https://retailservices.wellsfargo.com/locator/wfhapageMap',
                        params=params,
                        proxies=proxies
                    )
                    if response.status_code == 200:
                        break
                    else:
                        time.sleep(3)
                except requests.RequestException:
                    pass
        sel = Selector(response.text)
        # Iterate over results
        eles = sel.xpath("//*[@class='aResult']")
        assert eles or "sorry. No results matched your search. Please change your search informatio" in response.text or 'Please enter a valid ZIP code and search again.' in response.text or 'Something went wrong. We care about your expe' in response.text
        if not eles:
            break
        for ele in eles:
            zipcode = ele.xpath(".//*[@class='postal-code']/text()").get()
            if zipcode == location:
                data = dict()
                data['location'] = location
                data['name'] = ele.xpath(".//*[@class='fn-title']/text()").get()
                data['address1'] = ele.xpath(".//*[@class='street-address']/text()").get()
                data['city'] = ele.xpath(".//*[@class='locality']/text()").get()
                data['state'] = ele.xpath(".//*[@class='region']/text()").get()
                data['zipcode'] = zipcode
                data['phone'] = ele.xpath(".//*[@class='tel']/a/text()").get()
                data['specialties'] = ele.xpath(".//*[@class='fn-heading']/text()")[-1].get()
                datas.append(data)
                fail_count = 0
            else:
                fail_count += 1
                # Break the loop if fail count is equal or larger than 5
                if fail_count >= 5:
                    break

        else:
            if len(eles) < 25:
                break
            continue
        break
    return datas, request_count_local


# Read in all location
with open(zipcode_file_path, newline='', encoding='utf-8') as zipcode_file:
    reader = csv.reader(zipcode_file)
    rows = [row for row in reader]

locations = [row[2] for row in rows]
numbers = range(len(locations))

request_count = 0

with ThreadPoolExecutor(max_workers=2) as executor:
    for datas, request_count_local in executor.map(get_datas, numbers, locations):
        if datas:
            with open(result_file_path, 'a', newline='', encoding='utf-8_sig') as f:
                csv_f = csv.DictWriter(f, fieldnames=datas[0].keys())
                if f.tell() == 0:
                    csv_f.writeheader()
                csv_f.writerows(datas)
        request_count += request_count_local

logger.info(f'Total requests: {request_count}')