%% author: Yin Huang
%% date: 5-3-2014
%%
%% This module handles the update and retrieve requests so that no mutual exlcusion mechanism needed because everytime, if you have a read/write request, just spawn this process to handle the request, so anytime, only read or write is executed.
%%
%% read(filename, processid) 
%%     input: the filename you want to read
%%     processid: the id of process who wants to read the file 
%% 
%% write(filename, values)
%% input: 1. file name to update
%%        2. values to be written to the file
%%    optional write mode: append, overwrite (right now default as overwrite)
%% Assume there is a data directory under all nodes, where the files are stored
%% First check if the data directory has the file to be updated, if yes, go ahead and write the file with the values and in one of the modes(append, or overwrite).
%% if no, just return true and stop.
%% 
-module(update).
-export([read/2,write/2]).

read(F,Pid)->
    {ok,Filenames} = file:list_dir_all(data),
    case lists:member(F,Filenames) of
	true ->
	     {ok,Binary} = file:read_file(string:concat("data/",F)),
	    Lines = string:tokens(erlang:binary_to_list(Binary),"\n"),
	    file:close(Binary),
	    io:format("~p has content: ~n~p~n",[F,Lines]),
	    Pid ! Lines;
	false ->
	    io:format("Nothing needs to be done!")
		
end.
	 

write(File, Values) ->
    {ok, Filenames} = file:list_dir_all(data),
    case lists:member(File,Filenames) of
	true ->
	    {ok,Binary} = file:read_file(string:concat("data/",File)),
	    Lines = string:tokens(erlang:binary_to_list(Binary),"\n"),
	    file:close(Binary),
	    io:format("Before update ~p has content: ~n~p~n",[File,Lines]),
	    io:format("Now updating the file!"),
	    ValueLists = string:tokens(Values, ","),
	    io:format("~p~n",[ValueLists]),
	    filewrite(string:concat("data/",File), ValueLists),
	     {ok,MyBinary} = file:read_file(string:concat("data/",File)),
	   MyLines = string:tokens(erlang:binary_to_list(MyBinary),"\n"),
	    io:format("After update ~p has content: ~n~p~n",[File,MyLines]),
	    io:format("Requested updates Done!");
	false ->
	    io:format("No updates!")
end.

  
filewrite(File, L) ->
   case file:open(File, [write]) of
      {ok, Device} ->
         lists:foreach(fun(Line) -> writeline(Device, Line) end, L),
         file:close(Device)
   end.
writeline(Device, Line) -> writeline(Device, Line, os:type()).

writeline(Device, Line, {win32,_}) -> io:fwrite(Device, "~s\r\n", [Line]);
writeline(Device, Line, _) -> io:fwrite(Device, "~s\n", [Line]).
