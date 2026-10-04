class_name UiPalette
extends RefCounted
# docs/sample_image の 3 枚から抽出した共通カラーパレット。
# 色値はこのファイル以外にハードコードしない (デザインの一貫性担保)。

# --- UI パネル ---
const PANEL_NAVY := Color("0D124A")
const PANEL_NAVY_DEEP := Color("0B1048")
const PANEL_BORDER := Color("FFFFFF")
const PANEL_SHADOW := Color("000000")

# --- テキスト ---
const TEXT_PRIMARY := Color("FFFFFF")
const TEXT_DIM := Color("9AA6D8")
const TEXT_NAME := Color("F2C64C")

# --- フィールド ---
const SKY := Color("89CDCE")
const GRASS := Color("75A947")
const GRASS_DARK := Color("3A5930")
const DIRT := Color("956C40")
const DIRT_LIGHT := Color("C8934F")
const WATER := Color("2B7AC5")
const WATER_HIGHLIGHT := Color("6FC2F4")
const OUTLINE_BLACK := Color("000000")

# --- ステータスゲージ ---
const HP_GOOD := Color("5CD65C")
const HP_WARN := Color("E8C34A")
const HP_DANGER := Color("E05454")
