import csv
import os

from uszipcode import SearchEngine
from loguru import logger

# Construct the relative path to the zipcodes_list.csv file
zipcode_file_path = os.path.join('data', 'zipcodes.csv')
# Construct the relative path to the log file
log_file_path = os.path.join('data', 'log', 'zipcodes.log')


# Obtain the zipcode list
def zip_list():
    # Set up log file
    logger.add(log_file_path, level='INFO', encoding='utf-8')
    logger.info(f'Accessing zipcodes...')

    # Check if the zipcodes list exists
    if "zipcodes.csv" in os.listdir("results"):
        logger.info(f'Zipcodes list already exists. You can delete the file and rerun this script if you want to redo it.')
    else:
        logger.info(f'Creating zipcodes list...')

        sr = SearchEngine()
        z = sr.by_coordinates(42, -71, radius=300000000, returns=0, zipcode_type=None)
        z_list = [[item.major_city for item in z],
                  [item.state for item in z],
                  [item.zipcode for item in z],
                  [item.zipcode_type for item in z]]

        with open(zipcode_file_path, "w") as f:
            wr = csv.writer(f)
            wr.writerows(zip(*z_list))
            logger.info(f'Zipcodes list created successfully. {len(z)} zipcodes accessed.')


zip_list()
