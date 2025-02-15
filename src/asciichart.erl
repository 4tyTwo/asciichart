-module(asciichart).

-export([plot/1]).
-export([plot/2]).
-export([print/1]).
-export([plot_and_print/1]).
-export([plot_and_print/2]).

-define(OFFSET, 3).
-define(PADDING, <<" ">>).


-type config() :: #{
    padding => binary(),
    height  => integer(),
    offset  => integer()
}.

-type series() :: [integer()].


-spec plot(series()) -> {ok, binary()} | {error, no_data}.

plot(Series) ->
    plot(Series, #{}).

-spec plot(series(), config()) -> {ok, binary()} | {error, no_data}.

plot([], _) ->
    {error, no_data};
plot(Series, Config) when is_list(Series), is_map(Config) ->
    Min = lists:min(Series),
    Max = lists:max(Series),
    Interval = abs(Max - Min),
    Offset = maps:get(offset, Config, ?OFFSET),
    Height = case maps:get(height, Config, undefined) of
        undefined -> Interval;
        H -> H - 1
    end,
    Padding = maps:get(padding, Config, ?PADDING),
    Ratio = Height / Interval,
    Min2 = math:floor(Min * Ratio),
    Max2 = math:ceil(Max * Ratio),
    IntMin2 = trunc(Min2),
    IntMax2 = trunc(Max2),
    Rows = abs(IntMax2 - IntMin2),
    Width = length(Series) + Offset,

    %%%%%%%%%%%%%%

    Range0 = lists:seq(0, Rows + 1),
    Result0 = maps:from_list(
        lists:map(
            fun(X) ->
                {X, maps:from_list(lists:map(fun(Y) -> {Y, <<" "/utf8>>} end, lists:seq(0, Width)))}
            end,
            Range0
        )
    ),

    %%%%%%%%%%%%%%

    MaxLabelSize = get_label_size(Max),
    MinLabelSize = get_label_size(Min),
    LabelSize    = max(MaxLabelSize, MinLabelSize),

    %%%%%%%%%%%%%%

    Range1 = lists:seq(IntMin2, IntMax2),
    Result1 = lists:foldl(
        fun(Y, Map) ->
            LabelLength0 = Max - (Y - IntMin2) * Interval / Rows,
            LabelLength1 = round(LabelLength0, 2),
            Label = case string:pad(float_to_binary(LabelLength1, [{decimals, 2}]), LabelSize, leading, Padding) of 
                [[], UnpaddedLabel]    ->
                    UnpaddedLabel;
                [Pad, UnpaddedLabel]   ->
                    FormattedPad = list_to_binary(lists:join("", Pad)), <<FormattedPad/binary, UnpaddedLabel/binary>>
            end,
            Key1 = Y - IntMin2,
            Key2 = max(Offset - string:length(Label), 0),
            UpdatedMap = put_in(Map, [Key1, Key2], Label),
            put_in(UpdatedMap, [Key1, Offset - 1], case Y of 0 -> <<"┼"/utf8>>; _ -> <<"┤"/utf8>> end)
        end,
        Result0,
        Range1
    ),

    %%%%%%%%%%%%%%

    Y = trunc(lists:nth(1, Series) * Ratio - Min2),
    Result2 = put_in(Result1, [Rows - Y, Offset - 1], <<"┼"/utf8>>),
    Range2 = lists:seq(0, length(Series) - 2),
    Result3 = lists:foldl(
        fun(X, Map) ->
            Y0 = trunc(lists:nth(X + 1, Series) * Ratio - IntMin2),
            Y1 = trunc(lists:nth(X + 2, Series) * Ratio - IntMin2),
            case Y0 == Y1 of
                true ->
                    put_in(Map, [Rows - Y0, X + Offset], <<"─"/utf8>>);
                false ->
                    Upd1 = put_in(Map, [Rows - Y1, X + Offset], case Y0 > Y1 of true -> <<"╰"/utf8>>; _ -> <<"╭"/utf8>> end),
                    Upd2 = put_in(Upd1, [Rows - Y0, X + Offset], case Y0 > Y1 of true -> <<"╮"/utf8>>; _ -> <<"╯"/utf8>> end),
                    Range3 = lists:seq(min(Y0, Y1) + 1, max(Y0, Y1)),
                    Range4 = lists:sublist(Range3, length(Range3) - 1),
                    lists:foldl(fun(Z, M) -> put_in(M, [Rows - Z, X + Offset], <<"│"/utf8>>) end, Upd2, Range4)
            end
        end,
        Result2,
        Range2
    ),
    Prepared = to_list_and_sort(Result3),
    Result4 = lists:map(
        fun({_, Sublist}) ->
            List2 = lists:map(fun({_, V}) -> V end, Sublist),
            list_to_binary(lists:join("", List2))
        end,
        Prepared
    ),
   {ok, list_to_binary(lists:join("\n", Result4))}.

-spec print(binary()) -> ok.

print(Chart) when is_binary(Chart) ->
    ok = io:put_chars(standard_io, Chart).

-spec plot_and_print(series()) -> ok | {error, no_data}.

plot_and_print(Series) ->
    plot_and_print(Series, #{}).

-spec plot_and_print(series(), config()) -> ok | {error, no_data}.

plot_and_print(Series, Config) ->
    case plot(Series, Config) of
        {ok, Chart} -> print(Chart);
        Error -> Error
    end.

%%

to_list_and_sort(MapOfMaps) ->
    lists:keysort(
        1,
        maps:fold(
            fun(K, V, Acc) -> [{K, lists:keysort(1, maps:to_list(V)) } | Acc] end,
            [],
            MapOfMaps
        )
    ).

% works only for maps
put_in(_, [], _) -> error(empty_list_of_keys);
put_in(Map, [Key], Value) -> Map#{Key => Value};
put_in(Map, [Key | Rest], Value) -> Map#{Key => put_in(maps:get(Key, Map), Rest, Value)}.


get_label_size(Size) ->
    string:length(float_to_binary(round(Size / 1, 2), [{decimals, 2}])).

round(Num, Precision) ->
    erlang:list_to_float(io_lib:format("~.*f", [Precision, Num])).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-define(CHART_123, <<51,46,48,48,32,226,148,164,32,226,149,173,32,32,10,50,46,48,48,32,226,148,
  164,226,149,173,226,149,175,32,32,10,49,46,48,48,32,226,148,188,226,149,175,
  32,32,32,10,32,32,32,32,32,32,32>>).

-spec test() -> _.

-spec no_data_plot_error_test() -> _.

no_data_plot_error_test() ->
    {error, no_data} = plot([]).

-spec no_data_plot_and_print_error_test() -> _.

no_data_plot_and_print_error_test() ->
    {error, no_data} = plot_and_print([]).

-spec plot_ok_test() -> _.

plot_ok_test() ->
    {ok, ?CHART_123} = plot([1,2,3]).

-endif.
