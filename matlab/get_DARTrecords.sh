#!/bin/bash

urlbase="https://www.ngdc.noaa.gov/hazard/data/DART/20220115_tonga/dartXXXXX_20220114to20220119_meter_resid.txt"

wget ${urlbase//XXXXX/52401}
wget ${urlbase//XXXXX/52402}
wget ${urlbase//XXXXX/52403}
wget ${urlbase//XXXXX/52404}
wget ${urlbase//XXXXX/52405}
wget ${urlbase//XXXXX/52406}
