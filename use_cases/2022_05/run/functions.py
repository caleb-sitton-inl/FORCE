import math
import pandas as pd
import os, copy
import numpy as np

coefs = { 'NOAK':{'m':1.294,
                  'f':1.382,
                  'a_sca':862.9, 
                  'n_sca':-0.501,
                  'a_mod':365.6,
                  'n_mod':0},
          'FOAK':{'m':1.294,
                  'f':1.382,
                  'a_sca':862.9, 
                  'n_sca':-0.501,
                  'a_mod':365.6,
                  'n_mod':0}}
AC_to_DC = 1/1.076 # AC power consumed over DC power consumed

def compute_capex(capacity, m,f,a_sca, n_sca, a_mod, n_mod):
  """ 
    Determines the capex of the HTSE plant in $/kW-AC
    @ In, capacity, float, capacity of the HTSE in MW-AC
    @ In, m, float, indirect cost multiplier
    @ In, f, float, installation factor
    @ In, a_sca, float, scalable equipment cost coefficient
    @ In, n_sca, float, scalable equipment scaling exponent
    @ In, a_mod, float, modular equipment cost coefficient
    @ In, n_mod, float, modular equipment scaling exponent
    @ Out, capex, float, capex in $/kW-AC
  """
  capex = m*f* ( a_sca*math.exp(n_sca*math.log(capacity*AC_to_DC)) + a_mod*math.exp(n_mod*math.log(capacity*AC_to_DC)))
  return capex

def htse_noak_capex(data, meta):
  """
    Determines the Capex cost of the HTSE plant (NOAK) in $/MW-AC
    @ In, data, dict, request for data
    @ In, meta, dict, state information
    @ Out, data, dict, filled data
    @ In, meta, dict, state information
  """
  d = coefs['NOAK']
  m, f, a_sca, n_sca, a_mod, n_mod = d['m'], d['f'], d['a_sca'], d['n_sca'], d['a_mod'], d['n_mod']
  cap = math.fabs(meta['HERON']['RAVEN_vars']['htse_capacity']) # HTSE capacity cast as negative number
  capex = -1000*compute_capex(cap, m, f, a_sca, n_sca, a_mod, n_mod)
  data = {'driver': capex}
  return data, meta

def find_lower_nearest_idx(array, value): 
  idx = 0
  for i,a in enumerate(array):
    if value>a:
      idx = i
  return idx


def get_co2_price(data, meta):
  """
    Determines the cost of CO2 as a function of the quantity asked for, 
    Based on preliminary data from D. Wendt analysis for Braidwood NPP
    @ In, data, dict, request for data
    @ In, meta, dict, state information
    @ Out, data, dict, filled data
    @ In, meta, dict, state information
  """
  t = meta['HERON']['time_index']
  # year = meta['HERON']['year_index']
  for comp in meta['HERON']['Components']:
    if comp.name == 'CO2_source':
      npp = comp
      break
  else:
    raise RuntimeError
  print(meta['HERON'].keys())
  #co2_demand = data['driver']
  
  co2_demand = meta['HERON']['activity'].get_activity(npp, 'production', 'co2', t)
  print(co2_demand)
  #.get_activity(npp, 'production', 'heat', t)

  df = pd.read_csv(os.path.join(os.path.dirname(__file__), '../data/braidwood.csv'))
  cost_data = df.iloc[:,-1].to_numpy()
  co2_demand_data = df.iloc[:,-2].to_numpy()
  diff = np.absolute(co2_demand_data-co2_demand)
  idx = np.argmin(diff)
  co2_cost = cost_data[idx]
  data = {'reference_price': co2_cost}
  return data, meta


def co2_supply_curve(data, meta):
  """
    Determines the cost of CO2 as a function of the quantity asked for, 
    Based on preliminary data from D. Wendt analysis for Braidwood NPP
    @ In, data, dict, request for data
    @ In, meta, dict, state information
    @ Out, data, dict, filled data
    @ In, meta, dict, state information
  """
  co2_cost = 0
  co2_demand_year = meta['HERON']['RAVEN_vars']['CO2_source_capacity'] #kg/year
  co2_demand_hour = co2_demand_year/(365*24) # kg/h
  # Get the data for the Braidwood plant
  df = pd.read_csv(os.path.join(os.path.dirname(__file__), '../data/braidwood.csv'))
  cost_data = df.iloc[:,-1].to_numpy()
  co2_demand_data = df.iloc[:,-2].to_numpy()
  diff = np.absolute(co2_demand_data-co2_demand_hour)
  idx = np.argmin(diff)
  co2_cost = cost_data[idx]
  #co2_cost = cost_data[find_lower_nearest_idx(co2_demand_data, co2_demand)]
  data = {'reference_price': co2_cost}
  return data, meta 


def test_capex():
  d = coefs['NOAK']
  m, f, a_sca, n_sca, a_mod, n_mod = d['m'], d['f'], d['a_sca'], d['n_sca'], d['a_mod'], d['n_mod']
  capex = -1000*compute_capex(250, m, f, a_sca, n_sca, a_mod, n_mod)
  print(capex)

def test_co2_supply_curve():
  meta = {'HERON':{'activity':{'co2':340000}}}
  data ={}
  data, meta = co2_supply_curve(data, meta)
  print(data['driver'])

if __name__ == "__main__":
  test_co2_supply_curve()# Works!