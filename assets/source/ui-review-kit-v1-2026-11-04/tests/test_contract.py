import json, pathlib, unittest, xml.etree.ElementTree as ET
P=pathlib.Path(__file__).resolve().parents[1]
class Contract(unittest.TestCase):
 def test_manifest(self):
  d=json.loads((P/'manifest.json').read_text()); self.assertEqual(d['status'],'isolated_review_prototype'); self.assertFalse(d['gameplay_integrated'])
  self.assertEqual(len(d['components']),4)
 def test_icons(self):
  for n in ['confirm','cancel','inspect','facing','warning']:
   root=ET.parse(P/'icons'/f'{n}.svg').getroot();self.assertEqual(root.attrib['viewBox'],'0 0 32 32')
 def test_theme_states(self):
  text=(P/'review-theme.tres').read_text()
  for state in ['normal','hover','pressed','disabled','focus']:self.assertIn('Button/styles/'+state,text)
 def test_contract_states(self):
  d=json.loads((P/'state-contract.json').read_text()); self.assertEqual(d['initial_state'],'commands')
  for s in ['commands','move_preview','target_preview','inspect_enemy','choose_facing','resolved']:
   self.assertIn(s,d['states']); self.assertTrue(d['states'][s]['hint'])
if __name__=='__main__':unittest.main()
