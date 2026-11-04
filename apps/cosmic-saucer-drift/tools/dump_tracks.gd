extends SceneTree
## Dumps every track (all variants) as JSON polylines for tools/plot_tracks.py.

func _init() -> void:
	var out := {}
	for id in Catalog.TRACK_IDS:
		for v in 3:
			var td := TrackData.make(id, v)
			var d := {"length": td.main.length, "n": td.main.n, "main": [], "short": [], "feats": [], "shards": [], "gap": [], "width": td.width}
			for i in td.main.n:
				var p := td.main.pts[i]
				d.main.append([p.x, p.y, p.z, td.main.surf[i], td.line[i], td.main.rgt[i].x, td.main.rgt[i].z, td.gap[i], td.open_l[i], td.open_r[i]])
			if td.short:
				for i in td.short.n:
					var p := td.short.pts[i]
					d.short.append([p.x, p.y, p.z])
			for f in td.feats:
				var i := td.main.index_at(f.s)
				var p := td.main.pts[i] + td.main.rgt[i] * float(f.get("lane", 0.0))
				d.feats.append([f.t, p.x, p.z])
			for sh in td.shards:
				d.shards.append([sh.pos.x, sh.pos.y, sh.pos.z])
			out["%s_%d" % [id, v]] = d
	var fa := FileAccess.open("user://tracks_dump.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("dumped to ", ProjectSettings.globalize_path("user://tracks_dump.json"))
	quit()
