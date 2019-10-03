for /f %%A in ('wmic logicaldisk where drivetype=3 get name') do
begin
'foreach
forfiles /P C:\dev /S /D 01/10/2019 /C "cmd /c echo @path 0x09 was modified on @fdate @ftime"