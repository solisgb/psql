# -*- coding: utf-8 -*-
"""
Created on Thu Apr  7 11:54:17 2022

@author: solis
"""
import littleLogging as logging

org = r'H:\LSGB\data2db\SAIH_pz_Mar_Menor_20220303_v02.csv'
dst = r'H:\LSGB\20220324_informe_pz\data_chs\pz_mmenor.csv'


if __name__ == "__main__":

    try:
        from datetime import datetime
        from time import time
        import traceback

        import chg_format_pz_saih as cf

        now = datetime.now()

        startTime = time()

        cf.chg_format_pz_saih(org, dst)

        xtime = time() - startTime
        print(f'El script tardó {xtime:0.1f} s')

    except ValueError:
        msg = traceback.format_exc()
        logging.append(f'ValueError exception\n{msg}')
    except ImportError:
        msg = traceback.format_exc()
        print (f'ImportError exception\n{msg}')
    except Exception:
        msg = traceback.format_exc()
        logging.append(f'Exception\n{msg}')
    finally:
        logging.dump()
        print('\nFin')
