# asciichart

Terminal ASCII line charts in Erlang.

<img width="789" alt="Terminal ASCII line charts in Elixir" src="https://cloud.githubusercontent.com/assets/1294454/22818709/9f14e1c2-ef7f-11e6-978f-34b5b595fb63.png">

Ported to Erlang from [kroitor/asciichart](https://github.com/kroitor/asciichart)
based on [Elixir port](https://github.com/sndnv/asciichart), made by [sndnv](https://github.com/sndnv).

## Install

Add `asciichart` to the list of dependencies in `rebar.config`:

```erlang
{deps, [
    {asciichart,
        {git, "https://github.com/4tyTwo/asciichart.git",
            {branch, master}
        }
    }
]}.
```

## Usage

```erlang
{:ok, Chart} = asciichart:plot([1, 2, 3, 3, 2, 1]),
asciichart:print(Chart).

# should render as

3.00 ┤ ╭─╮
2.00 ┤╭╯ ╰╮
1.00 ┼╯   ╰
```

## Options
One or more of the following settings can be provided:
- `offset` - number of characters to set as the chart's (left) offset
- `height` - adjusts the height of the chart
- `padding` - one or more characters to use for the label's (left) padding

```erlang
{ok, Chart} = asciichart:plot([1, 2, 5, 5, 4, 3, 2, 100, 0], #{height => 3, offset => 10, padding: <<"_">>}).
asciichart:print(Chart).

# should render as

       ╭─> label
    ------
    100.00    ┼      ╭╮
    _50.00    ┤      ││
    __0.00    ┼──────╯╰
    --
---- ╰─> label padding
 ╰─> remaining offset (without the label)

# Rendering of empty charts is not supported

asciichart:plot([])
{error, no_data}

```
