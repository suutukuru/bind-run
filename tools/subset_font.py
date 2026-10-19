#!/usr/bin/env python3
"""ゲーム内で使う文字だけを IPAゴシックから切り出して assets/fonts/ui_font.ttf を作る。

Web 版の読み込みを軽くするため（元は約 6MB）。.gd と .tres の文字列リテラルにある文字を集める。
文字を足したら、このスクリプトを再実行する: python3 tools/subset_font.py
元のフォント: fonts-ipafont-gothic の ipag.ttf（IPAフォントライセンス v1.0。assets/fonts/LICENSE-IPA.txt）
派生プログラムなので、ライセンスに従い元の名前（IPA）を使わない名前に変更する。
"""
import re
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path("/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf")
OUTPUT = ROOT / "assets/fonts/ui_font.ttf"
FAMILY = "BindRunUI"
LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"')


def collect_chars() -> set[str]:
	chars: set[str] = set(chr(c) for c in range(0x20, 0x7F))
	# ひらがな・カタカナは全部入れる（文言を足しても欠けないように）
	chars |= set(chr(c) for c in range(0x3041, 0x3097))
	chars |= set(chr(c) for c in range(0x30A1, 0x30FD))
	chars |= set("、。「」（）！？・ー～…％＋－　")
	for pattern in ("scenes/**/*.gd", "scripts/**/*.gd", "data/**/*.tres"):
		for path in ROOT.glob(pattern):
			for line in path.read_text(encoding="utf-8").splitlines():
				if line.lstrip().startswith("#"):
					continue
				for literal in LITERAL.findall(line):
					chars |= set(literal)
	chars.discard("\n")
	return chars


def main() -> int:
	chars = collect_chars()
	options = subset.Options()
	options.layout_features = ["*"]
	options.name_IDs = [1, 2, 3, 4, 6]
	options.notdef_outline = True
	font = TTFont(str(SOURCE))
	subsetter = subset.Subsetter(options)
	subsetter.populate(text="".join(sorted(chars)))
	subsetter.subset(font)
	for record in font["name"].names:
		if record.nameID in (1, 16):
			record.string = FAMILY
		elif record.nameID == 4:
			record.string = FAMILY + " Regular"
		elif record.nameID in (3, 6):
			record.string = FAMILY + "-Regular"
	OUTPUT.parent.mkdir(parents=True, exist_ok=True)
	font.save(str(OUTPUT))
	print(f"{len(chars)} chars -> {OUTPUT} ({OUTPUT.stat().st_size} bytes)")
	return 0


if __name__ == "__main__":
	sys.exit(main())
