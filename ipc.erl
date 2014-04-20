-module(ipc).
-export([start/0, p1/1 , p2/1, p3/1]).





p1([Head|Rest])-> 
io:format("In p1 ~n"),
receive 
Val1 -> 
io:format("In p1 ~n ~p",[Val1])

end.





p2([Head|Rest])-> 
io:format("In p2 ~n").

p3([Head|Rest])-> 
Val1 = [1.3,Head],
Head !  Val1.



start() ->
PIDS = [er_ping,er_ping1,er_ping2],
register(er_ping, spawn(ipc, p1, [PIDS])),
register(er_ping1, spawn(ipc, p2, [PIDS])),
register(er_ping2, spawn(ipc, p3, [PIDS])).
