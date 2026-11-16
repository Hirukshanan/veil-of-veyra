from pathlib import Path
R=Path('C:/Users/Dark/Desktop/Projects/veil-of-veyra')
W=Path(__file__).parent.resolve()
s=(W/'baseline/lantern_awakening.gd').read_text()
s=s.replace('var owns_audio_bus := false','''var owns_audio_bus := false
var trace:Array=[]
func mark(label:String,begin:int):
	trace.append({"label":label,"us":Time.get_ticks_usec()-begin,"frame":Engine.get_process_frames(),"clock":clock})
''')
s=s.replace('\tgame._save_progress()','\tvar measured_save:=Time.get_ticks_usec()\n\tgame._save_progress()\n\tmark("start_save",measured_save)',1)
s=s.replace('\tgame.player.set_move_input(Vector2.ZERO)','\tvar measured_start:=Time.get_ticks_usec()\n\tgame.player.set_move_input(Vector2.ZERO)',1)
s=s.replace('\tmusic.play();_event("lantern_placement")','\tmark("start_before_audio",measured_start)\n\tvar measured_audio:=Time.get_ticks_usec()\n\tmusic.play();_event("lantern_placement")\n\tmark("start_audio",measured_audio)')
s=s.replace('\t_sample(0)','\tvar measured_sample:=Time.get_ticks_usec()\n\t_sample(0)\n\tmark("start_sample",measured_sample)')
s=s.replace('\tvar previous:=clock','\tvar measured_process:=Time.get_ticks_usec()\n\tvar previous:=clock')
s=s.replace('\t\t\t_event(cue[1])','\t\t\tvar measured_cue:=Time.get_ticks_usec()\n\t\t\t_event(cue[1])')
s=s.replace('\t_sample(clock)','\t\t\tmark("cue_"+str(cue[1]),measured_cue)\n\tvar measured_sample:=Time.get_ticks_usec()\n\t_sample(clock)\n\tmark("sample",measured_sample)\n\tmark("process",measured_process)')
s=s.replace('\tvar saved:bool=game._save_progress()','\tvar measured_save:=Time.get_ticks_usec()\n\tvar saved:bool=game._save_progress()\n\tmark("finish_save",measured_save)')
(R/'scripts/lantern_awakening.gd').write_text(s,encoding='utf-8')
