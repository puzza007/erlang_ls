%%==============================================================================
%% Application Callback Module
%%==============================================================================
-module(erlang_ls_app).

%%==============================================================================
%% Behaviours
%%==============================================================================
-behaviour(application).

%%==============================================================================
%% Exports
%%==============================================================================
%% Application Callbacks
-export([ start/2
        , stop/1
        ]).

%%==============================================================================
%% Application Callbacks
%%==============================================================================
-spec start(normal, any()) -> {ok, pid()}.
start(_StartType, _StartArgs) ->
  Transport = application:get_env(erlang_ls, transport, erlang_ls_tcp),
  ok = erlang_ls_server:start(Transport),
  erlang_ls_sup:start_link().

-spec stop(any()) -> ok.
stop(_State) ->
  ok.
