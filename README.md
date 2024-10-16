# MedicalCreditCard
A medical credit card (MCC) is designed exclusively for medical services, originally intended to cover procedures not covered by insurance, such as dental care, hearing exams, or cosmetic procedures. Over time, these cards have evolved to encompass various healthcare charges, including treatments in hospitals or from other healthcare providers. 

This project aims to gather information to understand which hospitals, clinics, or physician practices collaborate with the three primary agencies issuing medical credit cards, accept MCC payments, and maybe actively promote such payment methods. The three main agencies, [CareCredit](https://www.carecredit.com/doctor-locator), [Comenity](https://goalphaeon.com/doctor-locator), and [Wells Fargo](https://retailservices.wellsfargo.com/locator/WFHALanding?searchAddress=&segment=&merchantName=&userAgent=), provide webpages enabling cardholders and potential applicants to identify medical practices that accept their cards based on address, ZIP code, and/or specialty. The project's primary logic is to use all U.S. ZIP codes to scrape relevant information and then conduct a descriptive analysis of the specialty and geographic distribution patterns of such practices.

## STEP 0 Retrieve US ZIP codes
Surprisingly, there is no officially recognized list of U.S. ZIP codes released by any authoritative institution. For this project, I will utilize the [uszipcode](https://uszipcode.readthedocs.io/) Python module's list, which includes 42,724 ZIP codes. This comprehensive database should effectively cover nearly all ZIP codes, considering that the USPS reports [41,704 ZIP Codes in the country](https://facts.usps.com/42000-zip-codes/).

The script used for this step is named 00_ziplist.py. The result is saved as zipcodes.csv in the result folder.

## STEP 1 Scrape information from the three webpages
### CareCredit
The script scrapes data from the CareCredit website to obtain information about healthcare providers that accept CareCredit credit card in different locations. It follows these main steps:

1. Data Retrieval: Utilizes multithreading with ThreadPoolExecutor to concurrently retrieve data for multiple locations.
2. Location Data: Reads zip codes data from a CSV file containing zip codes.
3. Data Processing: For each zip code, it sends HTTP requests to the CareCredit website, retrieves JSON responses, and extracts relevant information such as name, address, phone number, and specialties of healthcare providers from the HTML response. Because the ranking algorithm takes into consideration the relevance and popularity, the retrived results would include locations that have zip codes different from the sent one. **The script would only save the ones with matched zip codes and continue loading "next page" until five locations in a row have mismatched zip codes. It at maxmium would load 70 pages.**
4. Error Handling: Implements error handling for HTTP requests to handle potential exceptions.
5. Data Storage: Writes the retrieved data to a CSV file.
6. Logging: Logs the total number of requests made.

The script used for this step is named `01_carecredit.py`. The result and the log are saved as `carecredit.csv` and `carecredit.log` in the result folder. 

### Wells Fargo Health Advantage
The script scrapes data from the Wells Fargo website to obtain information about locations based on zip codes. It follows these main steps:

1. Data Retrieval: Utilizes multithreading with ThreadPoolExecutor to concurrently retrieve data for multiple locations.
2. Location Data: Reads zip codes data from a CSV file containing zip codes.
3. Data Processing: For each zip code, it sends HTTP requests to the Wells Fargo website, retrieves HTML responses, and extracts relevant information such as location name, address, phone number, and specialties of the location from the HTML response. Because the ranking algorithm takes into consideration the relevance and popularity, the retrived results would include locations that have zip codes different from the sent one. **The script would only save the ones with matched zip codes and continue loading "next page" until five locations in a row have mismatched zip codes. It at maximum would load 70 pages.**
4. Error Handling: Implements error handling for HTTP requests to handle potential exceptions.
5. Data Storage: Writes the retrieved data to a CSV file.
6. Logging: Logs the total number of requests made.

The script used for this step is named `02_WellsFargoHA.py`. The result and the log are saved as `WellsFargoHA.csv` and `WellsFargoHA.log` in the results folder. 

### Alphaeon
The script scrapes data from the Alphaeon credit card website for various locations based on zip codes. Here's a summary of its functionality:

1. Proxies: Defines a list of proxies to handle IP screening and banning by the Alphaeon website.
2. Data Retrieval: Utilizes multithreading with ThreadPoolExecutor to concurrently retrieve data for multiple locations.
3. Location Data: Reads zip codes data from a CSV file containing zip codes.
4. Data Processing: For each zip code, it constructs HTTP requests with randomized proxies, sends POST requests to the Alphaeon website, and extracts relevant information such as location name, address, phone number, and specialties of the location from the HTML response. Because the ranking algorithm takes into consideration the relevance and popularity, the retrived results would include locations that have zip codes different from the sent one. **The script would only save the ones with matched zip codes and continue loading "next page" until five locations in a row have mismatched zip codes. It at maximum would load 70 pages.**
5. Error Handling: Implements error handling for HTTP requests to handle potential exceptions.
6. Data Storage: Writes the retrieved data to a CSV file.
7. Logging: Logs the total number of requests made.

The script is named `03_alphaeon.py`, and the results and logs are saved as `alphaeon.csv` and `alphaeon.log`, respectively, in the results folder. 


## STEP 2 Clean
The data scraped from the three MCC providers' websites contains duplicates because some zip codes may have overlapped closet health facility results. These data sets also have different categorization of the specialty. For our analysis, I did the following cleaning:

1. Drop duplicates created during the scraping process and renames columns for consistency. Standardize the address and city fields to title case and drop additional duplicates based on the address and phone number. After this step, we have *209,138* unique health facilities from CareCredit, *3,383* from Wells Fargo Health Advantage, and *7,961* from Alphaeon;
2. Remove entries related to veterinary and animal practices from CareCredit and Alphaeon datasets as these two services were also accepted by some veterinary practices and these were not of interest to us;
3. Split long specialty descriptions into multiple rows for CareCredit and Alphaeon datasets. Clean up specialty descriptions by removing unnecessary white spaces and newline characters. After this step, a facility that provides multiple specialty services would have one row for each specaility in the data;
4. Rename certain specialty categories for consistency. Create a comprehensive list of specialties and groups them into broader categories (e.g., Dentistry, Vision Medicine). Filter out irrelevant categories (e.g., Unrelated, Medical Equipment).
5. Merge the cleaned data sets from the three providers. Remove duplicates caused by regrouping specialties.
Filter out practices located in US territories, retaining only those in the 50 states and DC.

The script is named `04_clean.R`, and the result is saved as `cleaned.Rdata`.


## STEP 3 Analayze
The main analysis of this project aims to describe the landscape of medical organizations that accept MCC. We made a table for this goal. 

1. Medical organizations are grouped by their specialty to count the number of MCC partners in each specialty. 
2. The total number of medical organizations by specialty, except dentist office, is extracted from the 2023 IQVIA US Physician Specialties Market Report. The dental office number is extracted from 2021 County Business Patterns data hosted by the U.S. Census Bureau.
3. The number of medical organizations in each specialty were then divided by the total number of corresponding medical organizations in the country for the MCC penetration rates by specialty. 
4. These numbers were organized into a table.

The script is named `05_describe.R`, and the result is saved as [tables.pdf](https://github.com/Cal-Fang/MedicalCreditCard/blob/main/results/tables.pdf).

