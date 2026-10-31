#!/usr/bin/env python3
"""Real browser input against a read-only chapel observer; no gameplay injection."""
import base64
import json
from pathlib import Path
import time
import websocket
from browser_combat_smoke import CDP, canvas_point
from capture_browser_screenshots import devtools_target

OUT = Path('docs/qa/browser-chapel-captures')
OBS = """(() => {const c=document.querySelector('canvas'); if(!c || !window.__chapelQA)return null;const r=c.getBoundingClientRect();return {state:window.__chapelQA,canvas:{x:r.x,y:r.y,width:r.width,height:r.height}}})()"""

def main():
 OUT.mkdir(parents=True, exist_ok=True)
 cdp = CDP(websocket.create_connection(devtools_target(9222,45), timeout=15, http_proxy_host=None))
 latest = None
 evidence = []
 def wait(predicate, timeout=40):
  nonlocal latest
  end=time.monotonic()+timeout
  while time.monotonic()<end:
   latest=cdp.evaluate(OBS)
   if cdp.errors: raise AssertionError('Browser console error')
   if latest and predicate(latest['state']): return latest['state']
   time.sleep(.035)
  raise TimeoutError('Chapel browser state did not satisfy acceptance condition')
 def shot(name):
  data=cdp.command('Page.captureScreenshot',{'format':'png','fromSurface':True,'captureBeyondViewport':False})
  (OUT/(name+'.png')).write_bytes(base64.b64decode(data['data']))
  evidence.append({'name':name,'observation':latest})
 def click(point):
  cdp.click(*canvas_point(point, latest['state']['viewport'], latest['canvas']))
 def button(text):
  state=wait(lambda s:any(b['text']==text for b in s['buttons']))
  click(next(b['point'] for b in state['buttons'] if b['text']==text))
 def ready():
  return wait(lambda s:s.get('result') or (s.get('phase')=='PLAYER_TURN' and not s.get('busy') and not s.get('intro')))
 def zane(s): return next(u for u in s['units'] if u['id']=='zane')
 def enemy(s): return next(u for u in s['units'] if u['team']=='enemy')
 def move(destination):
  button('Move')
  state=wait(lambda s:bool(s.get('moves')))
  tile=next(t for t in state['moves'] if t['grid']==destination)
  click(tile['point'])
  wait(lambda s:zane(s)['grid']==destination and zane(s)['moved'] and not s['busy'])
 def action(command):
  state=ready()
  if command=='Fire':
   button('Skills')
   state=wait(lambda s:any('Fire' in b['text'] for b in s['buttons']))
   click(next(b['point'] for b in state['buttons'] if 'Fire' in b['text']))
   state=wait(lambda s:bool(s.get('abilities')))
  else:
   button('Attack')
   state=wait(lambda s:s.get('command')=='attack')
  target=enemy(state)
  # Hover the actual enemy foot; captures canonical damage preview before commit.
  x,y=canvas_point(target['point'],latest['state']['viewport'],latest['canvas'])
  cdp.command('Input.dispatchMouseEvent',{'type':'mouseMoved','x':x,'y':y})
  time.sleep(.12)
  wait(lambda s:bool(s.get('preview')))
  shot(command.lower()+'-forecast')
  ticket=state['ticket']
  mp=zane(state)['mp']
  click(target['point'])
  wait(lambda s:s.get('busy') and s.get('ticket',0)>ticket)
  shot(command.lower()+'-anticipation')
  # Capture multiple real rendered moments; frame names do not assert a specific atlas cell.
  for i in range(4):
   time.sleep(.07)
   latest_state=cdp.evaluate(OBS)
   if latest_state: latest.update(latest_state)
   shot(command.lower()+f'-sequence-{i}')
  after=ready()
  if not after.get('result'):
   assert zane(after)['mp']==mp-(12 if command=='Fire' else 0), 'Action resource cost duplicated'
  return after
 report={'passed':False}
 try:
  for domain in ['Page','Runtime','Log']: cdp.command(domain+'.enable')
  cdp.command('Emulation.setDeviceMetricsOverride',{'width':1920,'height':1080,'deviceScaleFactor':1,'mobile':False})
  cdp.command('Page.navigate',{'url':'http://127.0.0.1:8000/index.html'})
  state=ready()
  assert len(state['units'])==2 and zane(state)['hp']>0
  shot('chapel-loaded-1080p')
  for w,h in [(2560,1440),(3840,2160),(1920,1080)]:
   cdp.command('Emulation.setDeviceMetricsOverride',{'width':w,'height':h,'deviceScaleFactor':1,'mobile':False})
   time.sleep(.5)
   state=ready()
   shot(f'chapel-{w}x{h}')
  button('Status')
  time.sleep(.2)
  shot('zane-status')
  # Popup handles Escape; the battle command is not invoked by this key.
  cdp.command('Input.dispatchKeyEvent',{'type':'keyDown','key':'Escape','code':'Escape','windowsVirtualKeyCode':27})
  cdp.command('Input.dispatchKeyEvent',{'type':'keyUp','key':'Escape','code':'Escape','windowsVirtualKeyCode':27})
  for direction,delta in [('N',(0,-1)),('E',(1,0)),('S',(0,1)),('W',(-1,0))]:
   state=ready()
   origin=zane(state)['grid']
   button('Move')
   state=wait(lambda s:bool(s.get('moves')))
   candidates=[t for t in state['moves'] if (t['grid'][0]-origin[0])*delta[0]+(t['grid'][1]-origin[1])*delta[1]>0 and (t['grid'][1]==origin[1] if delta[0] else t['grid'][0]==origin[0])]
   assert candidates, 'No legal directional movement for '+direction
   tile=min(candidates,key=lambda t:abs(t['grid'][0]-origin[0])+abs(t['grid'][1]-origin[1]))
   click(tile['point'])
   state=wait(lambda s:zane(s)['grid']==tile['grid'] and zane(s)['moved'] and not s['busy'])
   assert zane(state)['facing']==direction
   shot('facing-'+{'N':'ne','E':'se','S':'sw','W':'nw'}[direction])
   button('Wait')
   time.sleep(.25)
   ready()
  # Approach through highlighted movement, then execute one actual sword attack.
  state=ready()
  if sum(abs(a-b) for a,b in zip(zane(state)['grid'],enemy(state)['grid']))>1:
   button('Move');state=wait(lambda s:bool(s.get('moves')))
   target=enemy(state)['grid']
   tile=min(state['moves'],key=lambda t:sum(abs(a-b) for a,b in zip(t['grid'],target)))
   click(tile['point']);wait(lambda s:zane(s)['grid']==tile['grid'] and not s['busy'])
  state=action('Attack')
  if not state.get('result') and zane(state)['acted']:
   button('Wait');time.sleep(.25)
  state=action('Fire')
  for _ in range(12):
   state=ready()
   if state.get('result'): break
   if zane(state)['acted']:
    button('Wait');time.sleep(.25)
   else: action('Fire')
  state=wait(lambda s:bool(s.get('result')))
  assert state['result']=='won', 'Duel did not reach victory'
  assert state['enemy_turns']>0, 'Enemy never responded'
  shot('victory-results')
  report['passed']=True
 except Exception as error:
  report['error']=repr(error)
  try: shot('failure')
  except Exception: pass
 finally:
  report.update(evidence=evidence,last=latest,errors=cdp.errors,inputs=cdp.inputs)
  (OUT/'report.json').write_text(json.dumps(report,indent=2))
  (OUT/'browser-events.json').write_text(json.dumps(cdp.events,indent=2))
  cdp.connection.close()
 return 0 if report['passed'] else 1

if __name__=='__main__': raise SystemExit(main())
