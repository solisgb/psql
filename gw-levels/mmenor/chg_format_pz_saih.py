# -*- coding: utf-8 -*-
"""
Created on Thu Apr  7 12:00:30 2022

@author: solis
"""
# import littleLogging as logging
import csv


def chg_format_pz_saih(org: str, dst: str):
    """
    Read csv file org and write data in another format

    Parameters
    ----------
    org : : str
        csv input file
    dst : : str
        csv output file

    Returns
    -------
    None.

    """
    step = 6
    nsondeos = 19
    header_col1 = 'id'
    with open(org) as fi, open(dst, mode='w', newline='') as fo:
        reader = csv.reader(fi, delimiter=";")
        writer = csv.writer(fo, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        for nrow, row in enumerate(reader):
            c1 = 0
            c2 = step
            if nrow == 0:
                ids = []
                for item in range(nsondeos):
                    ids.append(row[0].split(',')[c1:c2][0])
                    c1 = c2
                    c2 += step
            elif nrow == 1:
                writer.writerow([header_col1,] + row[0].split(',')[c1:c2])
            else:
                for i in range(nsondeos):
                    cells = [ids[i],] + row[0].split(',')[c1:c2]
                    if cells[0].strip() == '':
                        c1 = c2
                        c2 += step
                        continue
                    if ''.join(cells[1:]) == '':
                        c1 = c2
                        c2 += step
                        continue
                    writer.writerow(cells)
                    # print(ids[i], row[c1:c2])
                    c1 = c2
                    c2 += step
                if nrow == 5:
                    break






