###################################################################
###                                                           	###
###            Accuracy Tests MI Voter - birthyear		###
###				Python - Dedupe			###
###			California Policy Lab - 12/14/18	###
###                                                           	###
###################################################################

# program: dedupe.py
# Adapted from: https://github.com/dedupeio/dedupe-examples/blob/master/record_linkage_example/record_linkage_example.py

#################################################################
#1. Settings									
#################################################################

#import necessary packages
from __future__ import print_function

import random
import csv
import re
import logging
import numpy as np

import rlr
import pandas as pd
import dedupe
from unidecode import unidecode
import time

#start timer: 
t0 = time.time()

#log: 
logging.getLogger('dedupe').setLevel(logging.WARNING)

# Dedupe parameters - to be set by user
READ_FROM_TRAINING_FILE = True
READ_FROM_SETTINGS_FILE = True
WRITE_TRAINING_FILE = False
WRITE_SETTINGS_FILE = False
BLOCKING_TRAINING_SAMPLE_SIZE = 100000
SEED = 489

# Set threshold & recall - THRESHOLD OVERRIDES RECALL_WEIGHT
THRESHOLD = 0
RECALL_WEIGHT = 2.0

# Set Filepaths
#training files 
TRAINING_FILE = 'output/data_matching_training_5.json'
SETTINGS_FILE = 'output/data_matching_learned_settings_5'

#Output file path: 
OUTPUT_PATH = 'output/matched_pairs_5.csv'

#Input files: 
FNAME_2015 = '../data/2015_byear.csv'
FNAME_2017 = '../data/2017_byear.csv'

#specifying which fields will be used in the linking and how they will be treated: 
FIELDS = [
    {'field': 'fname', 'type': 'String', 'has missing': True},
    {'field': 'lname', 'type': 'String', 'has missing': True},
    {'field': 'mname', 'type': 'String', 'has missing': True},
    {'field': 'street', 'type': 'String', 'has missing': True},
    {'field': 'city', 'type': 'String', 'has missing': True},
    {'field': 'zip', 'type': 'String', 'has missing': True},
    {'field': 'streetnum', 'type': 'String', 'has missing': True},
    {'field': 'gender', 'type': 'Exact', 'has missing': True},
    {'field': 'byear', 'type': 'Exact', 'has missing': True}
]


#Pre-processing the data: 
def preprocess(column):
    """
    Do a little bit of data cleaning with the help of Unidecode and Regex.
    Things like casing, extra spaces, quotes and new lines can be ignored.
   
    This may be useful eventually, but leaving because fcn called later
    """

    column = unidecode(column)
    column = re.sub('\n', ' ', column)
    column = re.sub('-', '', column)
    column = re.sub('/', ' ', column)
    column = re.sub("'", '', column)
    column = re.sub(",", '', column)
    column = re.sub(":", ' ', column)
    column = re.sub('  +', ' ', column)
    column = column.strip().strip('"').strip("'").lower().strip()
    if not column :
        column = None
    return column

#Reading in CSVs
def read_from_csv(filename):
    """
    Read in our data from a CSV file and create a dictionary of records, 
    where the key is a unique record ID.
    """
    
    data_d = {}

    with open(filename) as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            clean_row = dict([(k, preprocess(v)) for (k, v) in row.items()])
            data_d[filename + str(i)] = dict(clean_row)

    return data_d
#################################################################
#2. TRAINING 									
#################################################################

#Training the data 
def train_linker(df1, df2):
    if READ_FROM_SETTINGS_FILE:
        with open(SETTINGS_FILE, 'rb') as sf:
            linker = dedupe.StaticRecordLink(sf)
    else:
        linker = dedupe.RecordLink(FIELDS)
        # It's terrible that you have to do this next line!!!!
        linker.classifier = rlr.RegularizedLogisticRegression()

        linker.sample(df1, df2, BLOCKING_TRAINING_SAMPLE_SIZE)

        if READ_FROM_TRAINING_FILE:
            print('reading labeled examples from ', TRAINING_FILE)
            with open(TRAINING_FILE, 'rb') as tf :
                linker.readTraining(tf)
        else:
            dedupe.consoleLabel(linker)

        linker.train()
    
    if WRITE_SETTINGS_FILE:
        with open(SETTINGS_FILE, 'wb') as sf:
            linker.writeSettings(sf)
    if WRITE_TRAINING_FILE:
        with open(TRAINING_FILE, 'w') as tf:
            linker.writeTraining(tf)
    
    return linker


def scores_by_threshold(linker, min_, max_, recall_weight=2):
    thresholds = np.arange(min_, max_, 0.1)
    comparison_results = {threshold: [] for threshold in thresholds}
    def run_matching(threshold):
        l = []
        for (entry_2015, entry_2017), score in linker.match(
            records_2015, records_2017, threshold=threshold
        ):
            id_2015 = entry_2015.replace(FNAME_2015, '')
            id_2017 = entry_2017.replace(FNAME_2017, '')
            l.append({
                'id_2015': id_2015,
                'id_2017': id_2017,
                'score': score
            })
        return l
        
    for threshold in thresholds:
        comparison_results[threshold] = run_matching(threshold)
    if recall_weight:
        optimum_threshold = linker.threshold(records_2015, records_2017, recall_weight=recall_weight)
        comparison_results['optimum'] = run_matching(optimum_threshold)

    comparison_results = {k: pd.DataFrame(v) for k, v in comparison_results.items()}

    full_comparison = None
    for threshold, df in comparison_results.items():
        df = df.rename(columns={
            'score': 'score_{:.1f}'.format(threshold) if threshold != 'optimum' else 'score_optimum'
        })
        if full_comparison is None:
            full_comparison = df
        else:
            full_comparison = full_comparison.merge(df, on=['id_2015', 'id_2017'], how='outer')
    if recall_weight:
        full_comparison['optimum_threshold'] = optimum_threshold
    return full_comparison


def num_matches(scores_df):
    optimum_threshold = scores_df.iloc[0]['optimum_threshold']
    num_matches = scores_df[[s for s in scores_df.columns if s.startswith('score_')]].apply(pd.notnull).sum()
    num_matches['optimum_threshold'] = optimum_threshold
    return num_matches.rename({
        s: s.replace('score_', 'matches_') for s in num_matches.index
    })


def linker_diagnostics(linker=None, min_threshold=0, max_threshold=1., static=False, write_settings=False, seed=None):
    if not linker:
        linker = train_linker(static=static, write_settings=write_settings, seed=seed)
    scores = num_matches(scores_by_threshold(linker, min_threshold, max_threshold)).to_dict()
    
    d = {
        'classifier.alpha': linker.classifier.alpha,
        'classifier.bias': linker.classifier.bias,
        'classifier.weights': linker.classifier.weights,
        'blocker.predicates': linker.blocker.predicates,
    }
    d.update(scores)
    return


def cluster_linked_pairs(linked_pairs):
    cluster_membership = {}

    for cluster_id, (linked_pair, score) in enumerate(linked_pairs):
        for record_id in linked_pair:
            cluster_membership[record_id] = (cluster_id, score)

    return cluster_membership

#################################################################
#3. OUTPUTTING LINKED FILES								
#################################################################

if __name__ == '__main__':

    if SEED:
        random.seed(SEED)
        np.random.seed(SEED)

    records_2015 = read_from_csv(FNAME_2015)
    records_2017 = read_from_csv(FNAME_2017)

    linker = train_linker(records_2015, records_2017)

    if not THRESHOLD:
        threshold = linker.threshold(records_2015, records_2017, recall_weight=RECALL_WEIGHT)
    else:
        threshold = THRESHOLD
    linked_pairs = linker.match(records_2015, records_2017, threshold=threshold)

    clustered_records = cluster_linked_pairs(linked_pairs)

    dfs = []
    cluster_df = pd.DataFrame.from_dict(clustered_records, orient='index').rename(columns={
        0: 'cluster_id',
        1: 'link_score'
    })
    for fno, (fname, records) in enumerate(((FNAME_2015, records_2015), (FNAME_2017, records_2017))):
        records_df = pd.DataFrame.from_dict(records, orient='index')
        merged = records_df.merge(cluster_df, left_index=True, right_index=True, how='inner')
        merged['fileno'] = fno
        merged = merged[['cluster_id', 'link_score', 'fileno'] + list(records_df.columns)]
        dfs.append(merged)
    full_output = dfs.pop(0)
    while dfs:
        full_output = full_output.append(dfs.pop(0))
    full_output.to_csv(OUTPUT_PATH, index=False)


#stop timer
t1 = time.time()

#print runtime
total = t1-t0
print(total)