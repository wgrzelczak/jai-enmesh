@echo off
pushd "%~dp0"
jai -import_dir ../../ -import_dir ../local_modules enmesh-app.jai
popd