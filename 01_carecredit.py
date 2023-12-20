import os
import csv
import time

from concurrent.futures import ThreadPoolExecutor
from loguru import logger

import tls_requests


# Construct the relative path to the zipcodes_list.csv file
zipcode_file_path = os.path.join('results', 'zipcodes.csv')
# Construct the relative path to the log file
log_file_path = os.path.join('results', 'carecredit.log')
# Construct the relative path to the result file
result_file_path = os.path.join('results', 'carecredit.csv')

# Set up log file
logger.add(log_file_path, level='INFO', encoding='utf-8')

# Set up cookies
cookies = {
    'AKA_A2': 'A',
    'bm_sz': '279AD818D611894444F7D3443771C84F~YAAQsBQgF07s1laLAQAATe+AbxV/B15x+yJLQDN5hH9qB6UL/1hVraKhDH9EPq7rRibSUzPseVfVS9hAfoJP/JrZE+fVZHVELV/Tt9vJZnL6paz8uv5iRPTAb2duvcO6kwAi5YT8dXUyx97J56hpoGkS74LDIURGnWfIsRLnpsGZNOzDr0PhRjEaAthc/rYJunzMmAbxfckA2ZmLI/jUbZdTdiUZP0/CNemHM1pB4omXCarcIQZ30ov8hht5VQfLsp1ZLFC3NVqA7mEgdDHdZQs0FsorlkvBpFbRN0Bq3Zux1CPTPRB6~3355705~4539714',
    '_dy_c_exps': '',
    '_dycnst': 'dg',
    '_dyid': '1166432558590411733',
    '_dy_geo': 'HK.AS.HK_HCW.HK_HCW_Hong%20Kong',
    '_dy_df_geo': 'Hong%20Kong..Hong%20Kong',
    '59765': 'NT%204.0',
    '_fbp': 'fb.1.1698383144178.1506667713',
    '_gid': 'GA1.2.1779142413.1698383145',
    '_cs_c': '0',
    '_rdt_uuid': '1698383144976.d870556e-b182-4f5e-b48d-4e23944c87c1',
    'kn_cs_visitor_id': 'fcc5e238-4b3b-41d7-94e7-2f7de1247f6f',
    '_gcl_au': '1.1.928672924.1698383145',
    's_ecid': 'MCMID%7C39452463637403159161757677465035287375',
    '_pin_unauth': 'dWlkPU5Ea3pZMk00T1dJdFpEQTVaUzAwTnpBeExUaGxNRGd0TVdRMU1USXpZbVpqTjJVeQ',
    'ak_bmsc': '3B778A0F760336CA3402D1716FC1BD18~000000000000000000000000000000~YAAQsBQgF4js1laLAQAAYy6BbxXi2b5lSsFTWoml4GRGmanoTmghocOX7Oo+DTfcvn49HVNcbDUlahUsFo72UvLgevW8TWNT75SbIxrFIKcvmbZGbBrq32fKrkP6qWOCP7YmOUibUY6X8BUKQwGNPobI2Ki33v/N1OgDNExJtjXbDHZxugm0mLGzgc7XtO87xTafkfK4VLKvDaiolTVgj2DzskDfswI1iGRfZaPlFC0F9L7BH7G5kW9ALGmUI5qhk2A2g5m14Lbv1JD6TmYmlT/KI6R/udwv9tEMM+N5ghySP4OA+38oe/xM6xFN0r0f6/LHIVRdUZ1hDND5obNgGjoqYa2fauuDlXBH1TUoQezemBXBYVpIEZr3Ulb4ROZTRh8Cdb7NeY0lf2IWv+q6zXPYtkc5I8emO3SueoWcwc3emXUWbO0wYD9NrNO06Lvx5sl8TgUFqYZ5f/7hau0Wtial7zhTnFMLrRH2+tmDrXxW54/juo2eeL2druuRfvZIr7zekG5u7wOjG5HBs4gQI588+0I=',
    '_dy_csc_ses': 't',
    '_dy_c_att_exps': '',
    'PHPSESSID': '7f1d36bf8991591b3e577bc19b79ee3b7f103e30',
    '_dyjsession': '93c767d8576932c62d11896c072832df',
    'dy_fs_page': 'www.carecredit.com%2Fdoctor-locator%2Fresults%2Fany-profession%2Fany-specialty%2F%2F%3Flat%3D%26long%3D%26zip%3D%26city%3D%26state%3D%26profession%3D%26location%3D90022',
    '_dycst': 'd.an.c.ws.',
    'AMCVS_22602B6956FAB4777F000101%40AdobeOrg': '1',
    'AMCV_22602B6956FAB4777F000101%40AdobeOrg': '1176715910%7CMCIDTS%7C19658%7CMCMID%7C39452463637403159161757677465035287375%7CMCAAMLH-1698987956%7C3%7CMCAAMB-1698987956%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1698390356s%7CNONE%7CMCAID%7CNONE%7CMCSYNCSOP%7C411-19665%7CvVersion%7C5.4.0',
    's_cc': 'true',
    '_dyid_server': '1166432558590411733',
    '_cs_cvars': '%7B%221%22%3A%5B%22Page%20ID%22%2C%22us%7Cen%7Ccarecredit%7Ccon%7Cfind-a-location%7Cresults%7Csearch-results-1%22%5D%7D',
    'OptanonAlertBoxClosed': '2023-10-27T05:08:48.253Z',
    '_dy_toffset': '-336',
    'dl-zip': '23337',
    'dl-location': '23337',
    'dl-lat': '37.9304',
    'dl-long': '-75.4753',
    'AVI_COOKIE': '02c5bd7ffb-1f58-46aQ4f8zPv6Vs6mxGRhzQGc_JETuAC_lVq9a_kvSKXsz10tU4x0fxTnSXKOX1phg0TU4k',
    '_gat_gtag_UA_128469451_6': '1',
    '_dy_ses_load_seq': '51060%3A1698385220262',
    'utag_main': 'v_id:018b6f8623250012c85fa10d3b990506f008806700978$_sn:1$_se:13$_ss:0$_st:1698387020516$ses_id:1698383143718%3Bexp-session$_pn:13%3Bexp-session$vapi_domain:carecredit.com$dc_visit:1$dc_event:13%3Bexp-session$dc_region:ap-east-1%3Bexp-session',
    'OptanonConsent': 'isGpcEnabled=0&datestamp=Fri+Oct+27+2023+13%3A40%3A20+GMT%2B0800+(%E4%B8%AD%E5%9B%BD%E6%A0%87%E5%87%86%E6%97%B6%E9%97%B4)&version=202209.1.0&isIABGlobal=false&hosts=&consentId=929437a0-c86d-4c92-bc73-7e1337a616fa&interactionCount=2&landingPath=NotLandingPage&groups=C0001%3A1%2CC0002%3A1%2CC0003%3A1%2CC0004%3A1&geolocation=US%3BCA&AwaitingReconsent=false',
    '_dy_lu_ses': '93c767d8576932c62d11896c072832df%3A1698385220877',
    '_dy_soct': '491014.903521.1698383143*376244.628405.1698385220*460050.829322.1698385220*503148.933541.1698385220*597125.1150759.1698385220*351655.576584.1698385220*836151.1650601.1698385220',
    'gpv_Page': 'us%7Cen%7Ccarecredit%7Ccon%7Cfind-a-location%7Cresults%7Csearch-results-1',
    '_ga': 'GA1.2.2064963235.1698383145',
    'JSESSIONID': 'ccZvgS03bbqhRqvgl4p9bQjrd75Es-CXU1b0G2hJdDQ1dOgtxY6M!140512687!1702957033',
    'BigIP_CC_PRODDEL_APP_LB': '0202bae549-f712-4f83X7aeez7UtiZWFGWbeFJnoy_jTr19LPGI9KtjP4U-g8z-uKAZqbvC-zUAEnxcDhZ1E',
    'RT': '"z=1&dm=carecredit.com&si=e5f4e414-7d61-4c3f-b79d-ec16bcbe433c&ss=lo85gwmh&sl=d&tt=sci&bcn=%2F%2F68794906.akstat.io%2F&obo=3&ld=18nqk"',
    '_ga_SHD5X90J3V': 'GS1.1.1698383145.1.1.1698385225.27.0.0',
    's_pers': '%20s_vnum%3D1698768000453%2526vn%253D1%7C1698768000453%3B%20s_nr%3D1698385225866-New%7C1700977225866%3B%20s_invisit%3Dtrue%7C1698387025868%3B%20s_lv%3D1698385225870%7C1792993225870%3B%20s_lv_s%3DFirst%2520Visit%7C1698387025870%3B',
    's_sq': 'synchronyglobalprod%252Csynchronyccprod%3D%2526c.%2526a.%2526activitymap.%2526page%253Dus%25257Cen%25257Ccarecredit%25257Ccon%25257Cfind-a-location%25257Cresults%25257Csearch-results-1%2526link%253DLoad%252520More%2526region%253Ddl-content-new%2526pageIDType%253D1%2526.activitymap%2526.a%2526.c%2526pid%253Dus%25257Cen%25257Ccarecredit%25257Ccon%25257Cfind-a-location%25257Cresults%25257Csearch-results-1%2526pidt%253D1%2526oid%253DLoad%252520More%2526oidt%253D3%2526ot%253DSUBMIT',
    '_cs_id': '2c01148c-8503-af3b-d4dd-d5606a7cb4be.1698383161.1.1698385225.1698383161.1592473181.1732547161958',
    '_cs_s': '48.5.0.1698387025970',
    '_abck': '83E8F9F0BBB444575AF7DFAA693FBA4B~-1~YAAQty43F5SXC2uLAQAA5+egbwpHnDQuZv2B7/d9Bub/Ag5wYBrnNHR9ay2YrVwCPBDpVVhd2xazSL4iajgb65lbairohmHJUb1o4vD3Et3nn3My3AFNwx8bnlUTljz3YeZvAMVa2b+zaiqYpjZ899phIAdnbXWAqmiPQx01WIDogfr20A7FetdIxhm/064OaFoPdCQUaVWweRT0/3IZXVMnf9BqOPjEoVHzmwgMPGsYQQn2abYvvwu2lmZocnqMjE2QRFyJGwZ8jZg4mnOB5M5w42z6ba1B5JRfTE9/xThpMbi8msiQ1Wd6OQTdX8Ny5jUMrUSFOwYl5xvI2MDKCyB15L+iv9MBDVvMCgy2TjSbQldIhW4Ce9HtHha00xlsUAFzPm5lEO3E1C+Bjk+BYXoLEWzkwKg8fjOklXp35esQPitAuv7FOSDA~0~-1~-1',
    'bm_sv': '75832C6B867A4D6C7D9EAAB43971803E~YAAQty43F5WXC2uLAQAA5+egbxW5Ic7JHTbxwN3ngs/VooDUsFPOM0jlkn0Uvea69bcOEipZnPD96FaaGFjodC7TJsL0cwTe2/GnZu0oV3o5eUSPW7txA9m8wDgTpL0bB11+uKUSiQq2p+tfb6JIPR6cTE4HVSIU2Z1p938na8kN01P11A5+h3Anusn8XHJBLtIiNPH0GzbIBvP6jtREBaiMhYif84EtXL0ge9yalaTRdyNkgonS0IViKan0cKOuskB23AaD~1',
}

headers = {
    'authority': 'www.carecredit.com',
    'accept': '*/*',
    'accept-language': 'zh-CN,zh;q=0.9',
    'referer': 'https://www.carecredit.com/doctor-locator/results/Any-Profession/Any-Specialty//?Sort=D&Radius=5&Page=2',
    'sec-ch-ua': '"Google Chrome";v="117", "Not;A=Brand";v="8", "Chromium";v="117"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
    'user-agent': 'Mozilla/5.0 (Linux; Android 10; EVR-AL00 Build/HUAWEIEVR-AL00; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/74.0.3729.186 Mobile Safari/537.36 baiduboxapp/11.0.5.12 (Baidu; P1 10)',
    'x-requested-with': 'XMLHttpRequest',
}


def get_datas(number, location):
    datas = []
    request_count_local = 0
    logger.info(f'Dealing with No.{number + 1} location：{location}')
    # Initialize fail count
    fail_count = 0
    headers = {
        'Referer': 'https://www.carecredit.com/doctor-locator/results/Any-Profession/Any-Specialty//?Sort=D&Radius=5&Page=2',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; EVR-AL00 Build/HUAWEIEVR-AL00; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/74.0.3729.186 Mobile Safari/537.36 baiduboxapp/11.0.5.12 (Baidu; P1 10)',
    }
    # Iterate over pages
    for page in range(1, 70):
        request_count_local += 1
        params = {
            'Page': page,
            'Radius': '5',
            'Sort': 'D',
            'd': 'Touch',
            'location': location,
            'pagename': 'CCGetLocatorService',
        }
        while True:
            try:
                proxies = None
                response = tls_requests.get('https://www.carecredit.com/sites/Satellite', params=params, headers=headers, proxies=proxies)
                if response.status_code == 200:
                    break
                else:
                    time.sleep(3)
            except tls_requests.RequestException:
                pass
        # Iterate over results
        for result in response.json().get('results', []):
            if result['zipcode'] == location:
                data = dict()
                data['location'] = location
                data['name'] = result['name']
                data['address1'] = result['address1']
                data['city'] = result['city']
                data['state'] = result['state']
                data['zipcode'] = result['zipcode']
                data['phone'] = result['phone']
                data['specialties'] = ', '.join([specialty['Specialty'] for specialty in result.get('specialties', [])])
                datas.append(data)
                fail_count = 0
            else:
                fail_count += 1
                # Break the loop if fail count is equal or larger than 5
                if fail_count >= 5:
                    break

        else:
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
