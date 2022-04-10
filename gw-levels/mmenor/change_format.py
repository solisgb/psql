# -*- coding: utf-8 -*-
"""
Created on Thu Apr  7 12:00:30 2022

@author: solis
"""
# import littleLogging as logging
import csv

class Change_format():

    def __init__(self, org, dst, first_col, npuntos, step):
        """
        Read some data from a csv file org and write them in another format

        Parameters
        ----------
        org : str
            csv input file
        dst : str
            csv output file
        first_col : int
            first col to read in org
        npuntos : int
            # points to read.
        step : int
            # columns for each point.

        Returns
        -------
        None.

        """
        self.org = org
        self.dst = dst
        self.step = step
        self.npuntos = npuntos
        self.first_col = first_col


    def chg_format(self, stop_at_line = -1):
        """
        Read csv file org and write data in another format (piezometric data)

        Parameters
        ----------
        stop_at_line : int
            execution stops after #line in self.org =stop_at_line
            first line is 0, not 1

        Returns
        -------
        None.

        """
        header_col1 = 'id'
        with open(self.org) as fi, open(self.dst, mode='w', newline='') as fo:
            reader = csv.reader(fi, delimiter=";")
            writer = csv.writer(fo, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            for nrow, row in enumerate(reader):
                print(nrow)
                c1 = self.first_col
                c2 = c1 + self.step
                if nrow == 0:
                    ids = []
                    for item in range(self.npuntos):
                        ids.append(row[0].split(',')[c1:c2][0])
                        c1 = c2
                        c2 += self.step
                elif nrow == 1:
                    writer.writerow([header_col1,] + row[0].split(',')[c1:c2])
                else:
                    for i in range(self.npuntos):
                        cells = [ids[i],] + row[0].split(',')[c1:c2]
                        if cells[1].strip() == '' or ''.join(cells[2:]) == '':
                            c1 = c2
                            c2 += self.step
                            continue
                        writer.writerow(cells)
                        # print(ids[i], row[c1:c2])
                        c1 = c2
                        c2 += self.step
                    if nrow == stop_at_line:
                         break
