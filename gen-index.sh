#!/bin/sh
# gen-index.sh
#
# Generates plain static index.html pages under public/ so the GitLab
# Pages site is browsable - Pages does not autoindex directories, and
# package filenames change every release, so these are built fresh each
# deploy from whatever actually landed in public/ rather than hand-written.
set -e

cd "$CI_PROJECT_DIR" 2>/dev/null || true

html_escape() {
	printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

human_size() {
	awk -v b="$1" 'BEGIN {
		if (b < 1024) { printf "%d B", b; exit }
		u["1"]="KiB"; u["2"]="MiB"; u["3"]="GiB"
		v = b; i = 0
		while (v >= 1024 && i < 3) { v /= 1024; i++ }
		printf "%.1f %s", v, u[i]
	}'
}

page_head() {
	title="$1"
	cat <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(html_escape "$title")</title>
<style>
  :root { color-scheme: light dark; }
  body {
    font-family: ui-monospace, SFMono-Regular, Consolas, Menlo, monospace;
    max-width: 60rem;
    margin: 2rem auto;
    padding: 0 1rem;
    line-height: 1.5;
  }
  h1 { font-size: 1.3rem; }
  table { border-collapse: collapse; width: 100%; margin-top: 1rem; }
  th, td { text-align: left; padding: 0.35rem 0.75rem 0.35rem 0; border-bottom: 1px solid #8888; }
  th { font-weight: normal; opacity: 0.7; }
  a { text-decoration: none; }
  a:hover { text-decoration: underline; }
  code, pre {
    background: #80808022;
    border-radius: 4px;
  }
  pre { padding: 0.75rem; overflow-x: auto; }
  code { padding: 0.1rem 0.3rem; }
  .muted { opacity: 0.6; }
  nav a { margin-right: 1rem; }
</style>
</head>
<body>
EOF
}

page_tail() {
	printf '</body>\n</html>\n'
}

gen_arch_index() {
	arch="$1"
	dir="public/$arch"
	[ -d "$dir" ] || return 0

	out="$dir/index.html"
	{
		page_head "$arch - rsv-ng void repo"
		printf '<nav><a href="../index.html">&larr; repo root</a></nav>\n'
		printf '<h1>%s</h1>\n' "$(html_escape "$arch")"
		printf '<table>\n<tr><th>name</th><th>size</th><th>modified (UTC)</th></tr>\n'

		# shellcheck disable=SC2012
		for f in "$dir"/*; do
			[ -f "$f" ] || continue
			name="$(basename "$f")"
			[ "$name" = "index.html" ] && continue
			size="$(human_size "$(stat -c%s "$f")")"
			mtime="$(stat -c '%Y' "$f")"
			mdate="$(date -u -d "@$mtime" '+%Y-%m-%d %H:%M' 2>/dev/null || date -u -r "$mtime" '+%Y-%m-%d %H:%M')"
			printf '<tr><td><a href="%s">%s</a></td><td>%s</td><td>%s</td></tr>\n' \
				"$(html_escape "$name")" "$(html_escape "$name")" "$size" "$mdate"
		done

		printf '</table>\n'
		page_tail
	} >"$out"
}

gen_root_index() {
	{
		page_head "rsv-ng void repo"
		printf '<h1>rsv-ng void repo</h1>\n'
		printf '<p class="muted">Void Linux (xbps) package repository, built by CI on every push to main.</p>\n'

		printf '<h2>Install</h2>\n<pre>xbps-install -R https://runit-rsv.gitlab.io/rsv-main/ARCH rsv-ng</pre>\n'
		printf '<p class="muted">Replace <code>ARCH</code> with one of the architectures below, matching <code>xbps-uhelper arch</code> on your system.</p>\n'

		printf '<h2>Architectures</h2>\n<table>\n<tr><th>arch</th></tr>\n'
		for arch in x86_64 x86_64-musl; do
			[ -d "public/$arch" ] || continue
			printf '<tr><td><a href="%s/index.html">%s</a></td></tr>\n' "$arch" "$(html_escape "$arch")"
		done
		printf '</table>\n'

		printf '<p class="muted"><a href="https://gitlab.com/runit-rsv/rsv-main">source</a></p>\n'
		page_tail
	} >public/index.html
}

for arch in x86_64 x86_64-musl; do
	gen_arch_index "$arch"
done
gen_root_index
