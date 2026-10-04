extends Node
# アプリケーション全体のバージョン情報。
#
# バージョン体系: v<Major>.<Minor>.<Patch>-beta.<CommitCount>+<ShortHash>
#   通常表示 : v0.0.1-beta.1
#   詳細表示 : v0.0.1-beta.1 (18a7f84)
#
# コミット直前に以下を更新すること (AIエージェント必須作業):
#   1. git rev-list --count HEAD  -> +1 した値を APP_BUILD_NUMBER へ
#   2. git rev-parse --short HEAD -> APP_COMMIT_HASH へ
#   3. project.godot の config/version を "0.0.1-beta.<CommitCount>" へ

const APP_MAJOR: int = 0
const APP_MINOR: int = 0
const APP_PATCH: int = 1

var app_build_number: int = 1
var app_commit_hash: String = "0000000"


func get_short_version() -> String:
	return "v%d.%d.%d-beta.%d" % [APP_MAJOR, APP_MINOR, APP_PATCH, app_build_number]


func get_detailed_version() -> String:
	return "%s (%s)" % [get_short_version(), app_commit_hash]


func get_package_version() -> String:
	return "%d.%d.%d-beta.%d" % [APP_MAJOR, APP_MINOR, APP_PATCH, app_build_number]
