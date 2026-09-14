[app]

title = Task Planner
package.name = taskplanner
package.domain = org.taskplanner

source.dir = .
source.include_exts = py,png,jpg,jpeg,kv,atlas,json,txt

version = 1.0

requirements = python3,kivy

orientation = portrait

fullscreen = 0

android.archs = arm64-v8a

android.api = 35
android.minapi = 23

android.accept_sdk_license = True

android.permissions = INTERNET

[buildozer]

log_level = 2

warn_on_root = 1
