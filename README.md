# MedicalCreditCard
A medical credit card is designed exclusively for medical services, originally intended to cover procedures not covered by insurance, such as dental care, hearing exams, or cosmetic procedures. Over time, these cards have evolved to encompass various healthcare charges, including treatments in hospitals or from other healthcare providers. 
This project aims to gather information about medical practices partnered with the three primary agencies issuing medical credit cards. The goal is to understand which hospitals, clinics, or physician practices collaborate with these agencies, accept medical credit card payments, and maybe actively promote such payment methods. The three main agencies, [CareCredit](https://www.carecredit.com/doctor-locator), [Comenity](https://goalphaeon.com/doctor-locator), and [Wells Fargo](https://retailservices.wellsfargo.com/locator/WFHALanding?searchAddress=&segment=&merchantName=&userAgent=), provide webpages enabling cardholders and potential applicants to identify medical practices that accept their cards based on address, ZIP code, and/or specialty. The project's primary logic is to use all U.S. ZIP codes to scrape relevant information and then conduct a descriptive analysis of the specialty and geographic distribution patterns of such practices.

## STEP 0 Retrieve US ZIP codes
Surprisingly, there is no officially recognized list of U.S. ZIP codes released by any authoritative institution. For this project, I will utilize the [uszipcode](https://uszipcode.readthedocs.io/) Python module's list, which includes 42,724 ZIP codes. This comprehensive database should effectively cover nearly all ZIP codes, considering that the USPS reports [41,704 ZIP Codes in the country](https://facts.usps.com/42000-zip-codes/).

The script used for this step is named 00_ziplist.py. The result is saved as zipcodes.csv in the result folder.

## STEP 1 Scrape information from the three webpages
