# -*- coding: utf-8 -*-
"""
Created on Thu Apr  7 11:54:17 2022

@author: solis
"""
import littleLogging as logging

# ================ parameters ============================

org = r'H:\LSGB\20220324_informe_pz\data_chs\saih\SAIH_pz_Mar_Menor_20220303_v02.csv'

# piezometric data
# dst = r'H:\LSGB\20220324_informe_pz\data_chs\saih\pz_mmenor_saih_2.csv'
# first_col = 0
# npuntos = 19
# step = 6

# pp data
dst = r'H:\LSGB\20220324_informe_pz\data_chs\pp_mmenor_saih_2.csv'
first_col = 114
npuntos = 2
step = 2

# q albujon
dst = r'H:\LSGB\20220324_informe_pz\data_chs\saih\albujon_saih.csv'
first_col = 118
npuntos = 1
step = 2

# Before runnig, be sure the unwanted block of data parameters are unommented (#)

# =============================================================


if __name__ == "__main__":

    try:
        from time import time
        import traceback

        from change_format import Change_format

        startTime = time()

        cf = Change_format(org, dst, first_col, npuntos, step)

        cf.chg_format()

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
