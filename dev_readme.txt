sqlite3.c and sqlite3.h were modified in order to build .lib file in addition to .dll file for Windows 
(otherwise only .dll had been built). The SQLITE_API definition had been modified for Windows __declspec
statement.