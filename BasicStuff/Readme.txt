update.erl implements both read and write methods.
The reason is to eliminate the mutual exclusion. If we handle write and read request in the same process, no concern about read/write
conflict needed. 
To test this two methods, you need a data directory with say filename : F_1

to test read:
 Pid = spawn(update, read, ["F_1", self()]).    This is read the file F_1 if F_1 is in the data direcotry, otherwise nothing happens.
 
to test write: (note: the second argument is values separated by comma, and should be quoted by ").
 Pid = spawn(update, write, ["F_1", "0.1,0.2,0.3"]) If current node has F_1 file, it will be overwritten with 0.1 0.2 0.3, otherwise nothing happens.
 
 This module should be called when a request received from your neighbors. 
 Please feel free to test and comment. 
 Thanks,
 Yin
 
