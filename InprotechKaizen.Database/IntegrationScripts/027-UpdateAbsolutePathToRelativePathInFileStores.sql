PRINT '**** R47719 One-time installation step to ensure all file store paths are relative'

UPDATE FileStores SET [Path] = Right([Path], Len([Path]) - Len('c:\Inprotech\Storage\'))
WHERE [Path] LIKE 'c:\Inprotech\Storage\%'