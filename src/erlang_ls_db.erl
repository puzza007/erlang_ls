-module(erlang_ls_db).

%% API
-export([ add/2
        , find/2
        , install/0
        , install/1
        , store/3
        , delete/2
        , start_link/0
        , wait_for_tables/0
        ]).

%% gen_server callbacks
-export([ init/1
        , handle_call/3
        , handle_cast/2
        ]).

-define(SERVER, ?MODULE).
%% TODO: Get table names via provider callbacks
-define(TABLES, [ completion_index
                , documents
                , references_index
                ]).
-define(TIMEOUT, 5000).

-record(poi, { uri   :: erlang_ls_uri:uri()
             , value :: erlang_ls_poi:poi()
             }).

-type state() :: #{}.
-type table() :: atom().
-type key()   :: any().

%%==============================================================================
%% Exported functions
%%==============================================================================

-spec install() -> ok.
install() ->
  {ok, [[Home]]} = init:get_argument(home),
  Dir = filename:join([Home, ".cache", "erlang_ls", "db"]),
  ok = filelib:ensure_dir(filename:join([Dir, "dummy"])),
  install(Dir).

-spec install(string()) -> ok.
install(Dir) ->
  lager:info("Creating DB. [dir=~s]", [Dir]),
  ok = application:set_env(mnesia, dir, Dir),
  mnesia:create_schema([node()]),
  application:start(mnesia),
  mnesia:create_table( poi
                     , [ {attributes, record_info(fields, poi)}
                       , {disc_copies, []}
                       ]),
  application:stop(mnesia).

-spec start_link() -> {ok, pid()}.
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, {}, []).

-spec find(table(), key()) -> {ok, any()} | not_found.
find(Table, Key) ->
  case ets:lookup(Table, Key) of
    [] -> not_found;
    [{Key, Value}] -> {ok, Value}
  end.

-spec store(table(), key(), any()) -> ok.
store(Table, Key, Value) ->
  true = ets:insert(Table, {Key, Value}),
  ok.

%% TODO: Rename into store when ready
-spec add(erlang_ls_uri:uri(), erlang_ls_poi:poi()) -> ok.
add(Uri, POI) ->
  F = fun() -> mnesia:write(#poi{uri = Uri, value = POI}) end,
  %% TODO: We probably do not need a transactions per each poi
  mnesia:activity(transaction, F).

-spec delete(table(), key()) -> ok.
delete(Table, Key) ->
  true = ets:delete(Table, Key),
  ok.

-spec wait_for_tables() -> ok.
wait_for_tables() ->
  wait_for_tables(?TIMEOUT).

-spec wait_for_tables(pos_integer()) -> ok.
wait_for_tables(Timeout) ->
  %% TODO: Macro for table names
  ok = mnesia:wait_for_tables([poi], Timeout).

%%==============================================================================
%% gen_server Callback Functions
%%==============================================================================

-spec init({}) -> {ok, state()}.
init({}) ->
  [create_table(Name) || Name <- ?TABLES],
  {ok, #{}}.

-spec handle_call(any(), any(), state()) -> {reply, ok, state()}.
handle_call(_Msg, _From, State) -> {reply, ok, State}.

-spec handle_cast(any(), state()) -> {noreply, state()}.
handle_cast(_Msg, State) -> {noreply, State}.

%%==============================================================================
%% Internal functions
%%==============================================================================

-spec create_table(atom()) -> ok.
create_table(Name) ->
  ets:new(Name, [named_table, set, public]),
  ok.
