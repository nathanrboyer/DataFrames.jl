# First Steps with DataFrames.jl

## Manipulation Functions

*The manipulation functions also have methods for applying multiple operations.
See the later sections [Applying Multiple Operations per Manipulation](@ref)
and [Broadcasting Operation Pairs](@ref) for more information.*

#### `source_column_selector`
Inside an `operation`, `source_column_selector` is usually a column name
or column index which identifies a data frame column.

`source_column_selector` may be used as the entire `operation`
with `select` or `select!` to isolate or reorder columns.

```julia
julia> df = DataFrame(a = [1, 2, 3], b = [4, 5, 6], c = [7, 8, 9])
3×3 DataFrame
 Row │ a      b      c
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      7
   2 │     2      5      8
   3 │     3      6      9

julia> select(df, :b)
3×1 DataFrame
 Row │ b
     │ Int64
─────┼───────
   1 │     4
   2 │     5
   3 │     6

julia> select(df, "b")
3×1 DataFrame
 Row │ b
     │ Int64
─────┼───────
   1 │     4
   2 │     5
   3 │     6

julia> select(df, 2)
3×1 DataFrame
 Row │ b
     │ Int64
─────┼───────
   1 │     4
   2 │     5
   3 │     6
```

`source_column_selector` may also be used as the entire `operation`
with `subset` or `subset!` if the source column contains `Bool` values.

```julia
julia> df = DataFrame(
           name = ["Scott", "Jill", "Erica", "Jimmy"],
           minor = [false, true, false, true],
       )
4×2 DataFrame
 Row │ name    minor
     │ String  Bool
─────┼───────────────
   1 │ Scott   false
   2 │ Jill     true
   3 │ Erica   false
   4 │ Jimmy    true

julia> subset(df, :minor)
2×2 DataFrame
 Row │ name    minor
     │ String  Bool
─────┼───────────────
   1 │ Jill     true
   2 │ Jimmy    true
```

`source_column_selector` may instead be a collection of columns such as a vector,
a [regular expression](https://docs.julialang.org/en/v1/manual/strings/#Regular-Expressions),
a `Not`, `Between`, `All`, or `Cols` expression,
or a `:`.
See the [Indexing](@ref) API for the full list of possible values with references.

!!! Note
      The Julia parser sometimes prevents `:` from being used by itself.
      If you get
      `ERROR: syntax: whitespace not allowed after ":" used for quoting`,
      try using `All()`, `Cols(:)`, or `(:)` instead to select all columns.

```julia
julia> df = DataFrame(
           id = [1, 2, 3],
           first_name = ["José", "Emma", "Nathan"],
           last_name = ["Garcia", "Marino", "Boyer"],
           age = [61, 24, 33]
       )
3×4 DataFrame
 Row │ id     first_name  last_name  age
     │ Int64  String      String     Int64
─────┼─────────────────────────────────────
   1 │     1  José        Garcia        61
   2 │     2  Emma        Marino        24
   3 │     3  Nathan      Boyer         33

julia> select(df, [:last_name, :first_name])
3×2 DataFrame
 Row │ last_name  first_name
     │ String     String
─────┼───────────────────────
   1 │ Garcia     José
   2 │ Marino     Emma
   3 │ Boyer      Nathan

julia> select(df, r"name")
3×2 DataFrame
 Row │ first_name  last_name
     │ String      String
─────┼───────────────────────
   1 │ José        Garcia
   2 │ Emma        Marino
   3 │ Nathan      Boyer

julia> select(df, Not(:id))
3×3 DataFrame
 Row │ first_name  last_name  age
     │ String      String     Int64
─────┼──────────────────────────────
   1 │ José        Garcia        61
   2 │ Emma        Marino        24
   3 │ Nathan      Boyer         33

julia> select(df, Between(2,4))
3×3 DataFrame
 Row │ first_name  last_name  age
     │ String      String     Int64
─────┼──────────────────────────────
   1 │ José        Garcia        61
   2 │ Emma        Marino        24
   3 │ Nathan      Boyer         33

julia> df2 = DataFrame(
           name = ["Scott", "Jill", "Erica", "Jimmy"],
           minor = [false, true, false, true],
           male = [true, false, false, true],
       )
4×3 DataFrame
 Row │ name    minor  male
     │ String  Bool   Bool
─────┼──────────────────────
   1 │ Scott   false   true
   2 │ Jill     true  false
   3 │ Erica   false  false
   4 │ Jimmy    true   true

julia> subset(df2, [:minor, :male])
1×3 DataFrame
 Row │ name    minor  male
     │ String  Bool   Bool
─────┼─────────────────────
   1 │ Jimmy    true  true
```

!!! Note
      Using `Symbol` in `source_column_selector` will perform slightly faster than using `String`.
      However, `String` is convenient when column names contain spaces.

      All elements of `source_column_selector` must be the same type
      (unless wrapped in `Cols`),
      e.g. `subset(df2, [:minor, "male"])` will error
      since `Symbol` and `String` are used simultaneously.)

#### `operation_function`
Inside an `operation` pair, `operation_function` is a function
which operates on data frame columns passed as vectors.
When multiple columns are selected by `source_column_selector`,
the `operation_function` will receive the columns as separate positional arguments
in the order they were selected, e.g. `f(column1, column2, column3)`.

```julia
julia> df = DataFrame(a = [1, 2, 3], b = [4, 5, 4])
3×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      4
   2 │     2      5
   3 │     3      4

julia> combine(df, :a => sum)
1×1 DataFrame
 Row │ a_sum
     │ Int64
─────┼───────
   1 │     6

julia> transform(df, :b => maximum) # `transform` and `select` copy scalar result to all rows
3×3 DataFrame
 Row │ a      b      b_maximum
     │ Int64  Int64  Int64
─────┼─────────────────────────
   1 │     1      4          5
   2 │     2      5          5
   3 │     3      4          5

julia> transform(df, [:b, :a] => -) # vector subtraction is okay
3×3 DataFrame
 Row │ a      b      b_a_-
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      3
   2 │     2      5      3
   3 │     3      4      1

julia> transform(df, [:a, :b] => *) # vector multiplication is not defined
ERROR: MethodError: no method matching *(::Vector{Int64}, ::Vector{Int64})
```

Don't worry! There is a quick fix for the previous error.
If you want to apply a function to each element in a column
instead of to the entire column vector,
then you can wrap your element-wise function in `ByRow` like
`ByRow(my_elementwise_function)`.
This will apply `my_elementwise_function` to every element in the column
and then collect the results back into a vector.

```julia
julia> transform(df, [:a, :b] => ByRow(*))
3×3 DataFrame
 Row │ a      b      a_b_*
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      4
   2 │     2      5     10
   3 │     3      4     12

julia> transform(df, Cols(:) => ByRow(max))
3×3 DataFrame
 Row │ a      b      a_b_max
     │ Int64  Int64  Int64
─────┼───────────────────────
   1 │     1      4        4
   2 │     2      5        5
   3 │     3      4        4

julia> f(x) = x + 1
f (generic function with 1 method)

julia> transform(df, :a => ByRow(f))
3×3 DataFrame
 Row │ a      b      a_f
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      2
   2 │     2      5      3
   3 │     3      4      4
```

Alternatively, you may just want to define the function itself so it
[broadcasts](https://docs.julialang.org/en/v1/manual/arrays/#Broadcasting)
over vectors.

```julia
julia> g(x) = x .+ 1
g (generic function with 1 method)

julia> transform(df, :a => g)
3×3 DataFrame
 Row │ a      b      a_g
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      2
   2 │     2      5      3
   3 │     3      4      4

julia> h(x, y) = x .+ y .+ 1
h (generic function with 1 method)

julia> transform(df, [:a, :b] => h)
3×3 DataFrame
 Row │ a      b      a_b_h
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      6
   2 │     2      5      8
   3 │     3      4      8
```

[Anonymous functions](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions)
are a convenient way to define and use an `operation_function`
all within the manipulation function call.

```julia
julia> select(df, :a => ByRow(x -> x + 1))
3×1 DataFrame
 Row │ a_function
     │ Int64
─────┼────────────
   1 │          2
   2 │          3
   3 │          4

julia> transform(df, [:a, :b] => ByRow((x, y) -> 2x + y))
3×3 DataFrame
 Row │ a      b      a_b_function
     │ Int64  Int64  Int64
─────┼────────────────────────────
   1 │     1      4             6
   2 │     2      5             9
   3 │     3      4            10

julia> subset(df, :b => ByRow(x -> x < 5))
2×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      4
   2 │     3      4

julia> subset(df, :b => ByRow(<(5))) # shorter version of the previous
2×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      4
   2 │     3      4
```

!!! Note
    `operation_functions` within `subset` or `subset!` function calls
    must return a Boolean vector.
    `true` elements in the Boolean vector will determine
    which rows are retained in the resulting data frame.

As demonstrated above, `DataFrame` columns are usually passed
from `source_column_selector` to `operation_function` as one or more
vector arguments.
However, when `AsTable(source_column_selector)` is used,
the selected columns are collected and passed as a single `NamedTuple`
to `operation_function`.

This is often useful when your `operation_function` is defined to operate
on a single collection argument rather than on multiple positional arguments.
The distinction is somewhat similar to the difference between the built-in
`min` and `minimum` functions.
`min` is defined to find the minimum value among multiple positional arguments,
while `minimum` is defined to find the minimum value
among the elements of a single collection argument.

```julia
julia> df = DataFrame(a = 1:2, b = 3:4, c = 5:6, d = 2:-1:1)
2×4 DataFrame
 Row │ a      b      c      d
     │ Int64  Int64  Int64  Int64
─────┼────────────────────────────
   1 │     1      3      5      2
   2 │     2      4      6      1

julia> select(df, Cols(:) => ByRow(min)) # min operates on multiple arguments
2×1 DataFrame
 Row │ a_b_etc_min
     │ Int64
─────┼─────────────
   1 │           1
   2 │           1

julia> select(df, AsTable(:) => ByRow(minimum)) # minimum operates on a collection
2×1 DataFrame
 Row │ a_b_etc_minimum
     │ Int64
─────┼─────────────────
   1 │               1
   2 │               1

julia> select(df, [:a,:b] => ByRow(+)) # `+` operates on a multiple arguments
2×1 DataFrame
 Row │ a_b_+
     │ Int64
─────┼───────
   1 │     4
   2 │     6

julia> select(df, AsTable([:a,:b]) => ByRow(sum)) # `sum` operates on a collection
2×1 DataFrame
 Row │ a_b_sum
     │ Int64
─────┼─────────
   1 │       4
   2 │       6

julia> using Statistics # contains the `mean` function

julia> select(df, AsTable(Between(:b, :d)) => ByRow(mean)) # `mean` operates on a collection
2×1 DataFrame
 Row │ b_c_d_mean
     │ Float64
─────┼────────────
   1 │    3.33333
   2 │    3.66667
```

`AsTable` can also be used to pass columns to a function which operates
on fields of a `NamedTuple`.

```julia
julia> df = DataFrame(a = 1:2, b = 3:4, c = 5:6, d = 7:8)
2×4 DataFrame
 Row │ a      b      c      d
     │ Int64  Int64  Int64  Int64
─────┼────────────────────────────
   1 │     1      3      5      7
   2 │     2      4      6      8

julia> f(nt) = nt.a + nt.d
f (generic function with 1 method)

julia> transform(df, AsTable(:) => ByRow(f))
2×5 DataFrame
 Row │ a      b      c      d      a_b_etc_f
     │ Int64  Int64  Int64  Int64  Int64
─────┼───────────────────────────────────────
   1 │     1      3      5      7          8
   2 │     2      4      6      8         10
```

As demonstrated above,
in the `source_column_selector => operation_function` operation pair form,
the results of an operation will be placed into a new column with an
automatically-generated name based on the operation;
the new column name will be the `operation_function` name
appended to the source column name(s) with an underscore.

This automatic column naming behavior can be avoided in two ways.
First, the operation result can be placed back into the original column
with the original column name by switching the keyword argument `renamecols`
from its default value (`true`) to `renamecols=false`.
This option prevents the function name from being appended to the column name
as it usually would be.

```julia
julia> df = DataFrame(a=1:4, b=5:8)
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8

julia> transform(df, :a => ByRow(x->x+10), renamecols=false) # add 10 in-place
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │    11      5
   2 │    12      6
   3 │    13      7
   4 │    14      8
```

The second method to avoid the default manipulation column naming is to
specify your own `new_column_names`.

#### `new_column_names`

`new_column_names` can be included at the end of an `operation` pair to specify
the name of the new column(s).
`new_column_names` may be a symbol, string, function, vector of symbols, vector of strings, or `AsTable`.

```julia
julia> df = DataFrame(a=1:4, b=5:8)
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8

julia> transform(df, Cols(:) => ByRow(+) => :c)
4×3 DataFrame
 Row │ a      b      c
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5      6
   2 │     2      6      8
   3 │     3      7     10
   4 │     4      8     12

julia> transform(df, Cols(:) => ByRow(+) => "a+b")
4×3 DataFrame
 Row │ a      b      a+b
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5      6
   2 │     2      6      8
   3 │     3      7     10
   4 │     4      8     12

julia> transform(df, :a => ByRow(x->x+10) => "a+10")
4×3 DataFrame
 Row │ a      b      a+10
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5     11
   2 │     2      6     12
   3 │     3      7     13
   4 │     4      8     14
```

The `source_column_selector => new_column_names` operation form
can be used to rename columns without an intermediate function.
However, there are `rename` and `rename!` functions,
which accept similar syntax,
that tend to be more useful for this operation.

```julia
julia> df = DataFrame(a=1:4, b=5:8)
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8

julia> transform(df, :a => :apple) # adds column `apple`
4×3 DataFrame
 Row │ a      b      apple
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5      1
   2 │     2      6      2
   3 │     3      7      3
   4 │     4      8      4

julia> select(df, :a => :apple) # retains only column `apple`
4×1 DataFrame
 Row │ apple
     │ Int64
─────┼───────
   1 │     1
   2 │     2
   3 │     3
   4 │     4

julia> rename(df, :a => :apple) # renames column `a` to `apple` in-place
4×2 DataFrame
 Row │ apple  b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8
```

If `new_column_names` already exist in the source data frame,
those columns will be replaced in the existing column location
rather than being added to the end.
This can be done by manually specifying an existing column name
or by using the `renamecols=false` keyword argument.

```julia
julia> df = DataFrame(a=1:4, b=5:8)
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8

julia> transform(df, :b => (x -> x .+ 10))  # automatic new column and column name
4×3 DataFrame
 Row │ a      b      b_function
     │ Int64  Int64  Int64
─────┼──────────────────────────
   1 │     1      5          15
   2 │     2      6          16
   3 │     3      7          17
   4 │     4      8          18

julia> transform(df, :b => (x -> x .+ 10), renamecols=false)  # transform column in-place
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1     15
   2 │     2     16
   3 │     3     17
   4 │     4     18

julia> transform(df, :b => (x -> x .+ 10) => :a)  # replace column :a
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │    15      5
   2 │    16      6
   3 │    17      7
   4 │    18      8
```

Actually, `renamecols=false` just prevents the function name from being appended to the final column name such that the operation is *usually* returned to the same column.

```julia
julia> transform(df, [:a, :b] => +)  # new column name is all source columns and function name
4×3 DataFrame
 Row │ a      b      a_b_+
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5      6
   2 │     2      6      8
   3 │     3      7     10
   4 │     4      8     12

julia> transform(df, [:a, :b] => +, renamecols=false)  # same as above but with no function name
4×3 DataFrame
 Row │ a      b      a_b
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5      6
   2 │     2      6      8
   3 │     3      7     10
   4 │     4      8     12

julia> transform(df, [:a, :b] => (+) => :a)  # manually overwrite column :a (see Note below about parentheses)
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     6      5
   2 │     8      6
   3 │    10      7
   4 │    12      8
```

In the `source_column_selector => operation_function => new_column_names` operation form,
`new_column_names` may also be a renaming function which operates on a string
to create the destination column names programmatically.

```julia
julia> df = DataFrame(a=1:4, b=5:8)
4×2 DataFrame
 Row │ a      b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8

julia> add_prefix(s) = "new_" * s
add_prefix (generic function with 1 method)

julia> transform(df, :a => (x -> 10 .* x) => add_prefix) # with named renaming function
4×3 DataFrame
 Row │ a      b      new_a
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5     10
   2 │     2      6     20
   3 │     3      7     30
   4 │     4      8     40

julia> transform(df, :a => (x -> 10 .* x) => (s -> "new_" * s)) # with anonymous renaming function
4×3 DataFrame
 Row │ a      b      new_a
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5     10
   2 │     2      6     20
   3 │     3      7     30
   4 │     4      8     40
```

!!! Note
      It is a good idea to wrap anonymous functions in parentheses
      to avoid the `=>` operator accidently becoming part of the anonymous function.
      The examples above do not work correctly without the parentheses!
      ```julia
      julia> transform(df, :a => x -> 10 .* x => add_prefix)  # Not what we wanted!
      4×3 DataFrame
       Row │ a      b      a_function
           │ Int64  Int64  Pair…
      ─────┼────────────────────────────────────────────
         1 │     1      5  [10, 20, 30, 40]=>add_prefix
         2 │     2      6  [10, 20, 30, 40]=>add_prefix
         3 │     3      7  [10, 20, 30, 40]=>add_prefix
         4 │     4      8  [10, 20, 30, 40]=>add_prefix

      julia> transform(df, :a => x -> 10 .* x => s -> "new_" * s)  # Not what we wanted!
      4×3 DataFrame
       Row │ a      b      a_function
           │ Int64  Int64  Pair…
      ─────┼─────────────────────────────────────
         1 │     1      5  [10, 20, 30, 40]=>#18
         2 │     2      6  [10, 20, 30, 40]=>#18
         3 │     3      7  [10, 20, 30, 40]=>#18
         4 │     4      8  [10, 20, 30, 40]=>#18
      ```

A renaming function will not work in the
`source_column_selector => new_column_names` operation form
because a function in the second element of the operation pair is assumed to take
the `source_column_selector => operation_function` operation form.
To work around this limitation, use the
`source_column_selector => operation_function => new_column_names` operation form
with `identity` as the `operation_function`.

```julia
julia> transform(df, :a => add_prefix)
ERROR: MethodError: no method matching *(::String, ::Vector{Int64})

julia> transform(df, :a => identity => add_prefix)
4×3 DataFrame
 Row │ a      b      new_a
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      5      1
   2 │     2      6      2
   3 │     3      7      3
   4 │     4      8      4
```

In this case though,
it is probably again more useful to use the `rename` or `rename!` function
rather than one of the manipulation functions
in order to rename in-place and avoid the intermediate `operation_function`.
```julia
julia> rename(add_prefix, df)  # rename all columns with a function
4×2 DataFrame
 Row │ new_a  new_b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8

julia> rename(add_prefix, df; cols=:a)  # rename some columns with a function
4×2 DataFrame
 Row │ new_a  b
     │ Int64  Int64
─────┼──────────────
   1 │     1      5
   2 │     2      6
   3 │     3      7
   4 │     4      8
```

In the `source_column_selector => new_column_names` operation form,
only a single source column may be selected per operation,
so why is `new_column_names` plural?
It is possible to split the data contained inside a single column
into multiple new columns by supplying a vector of strings or symbols
as `new_column_names`.

```julia
julia> df = DataFrame(data = [(1,2), (3,4)]) # vector of tuples
2×1 DataFrame
 Row │ data
     │ Tuple…
─────┼────────
   1 │ (1, 2)
   2 │ (3, 4)

julia> transform(df, :data => [:first, :second]) # manual naming
2×3 DataFrame
 Row │ data    first  second
     │ Tuple…  Int64  Int64
─────┼───────────────────────
   1 │ (1, 2)      1       2
   2 │ (3, 4)      3       4
```

This kind of data splitting can even be done automatically with `AsTable`.

```julia
julia> transform(df, :data => AsTable) # default automatic naming with tuples
2×3 DataFrame
 Row │ data    x1     x2
     │ Tuple…  Int64  Int64
─────┼──────────────────────
   1 │ (1, 2)      1      2
   2 │ (3, 4)      3      4
```

If a data frame column contains `NamedTuple`s,
then `AsTable` will preserve the field names.
```julia
julia> df = DataFrame(data = [(a=1,b=2), (a=3,b=4)]) # vector of named tuples
2×1 DataFrame
 Row │ data
     │ NamedTup…
─────┼────────────────
   1 │ (a = 1, b = 2)
   2 │ (a = 3, b = 4)

julia> transform(df, :data => AsTable) # keeps names from named tuples
2×3 DataFrame
 Row │ data            a      b
     │ NamedTup…       Int64  Int64
─────┼──────────────────────────────
   1 │ (a = 1, b = 2)      1      2
   2 │ (a = 3, b = 4)      3      4
```

!!! Note
      To pack multiple columns into a single column of `NamedTuple`s
      (reverse of the above operation)
      apply the `identity` function `ByRow`, e.g.
      `transform(df, AsTable([:a, :b]) => ByRow(identity) => :data)`.

Renaming functions also work for multi-column transformations,
but they must operate on a vector of strings.

```julia
julia> df = DataFrame(data = [(1,2), (3,4)])
2×1 DataFrame
 Row │ data
     │ Tuple…
─────┼────────
   1 │ (1, 2)
   2 │ (3, 4)

julia> new_names(v) = ["primary ", "secondary "] .* v
new_names (generic function with 1 method)

julia> transform(df, :data => identity => new_names)
2×3 DataFrame
 Row │ data    primary data  secondary data
     │ Tuple…  Int64         Int64
─────┼──────────────────────────────────────
   1 │ (1, 2)             1               2
   2 │ (3, 4)             3               4
```

### Applying Multiple Operations per Manipulation

### Broadcasting Operation Pairs

## Approach Comparison

**Setup:**

```julia
julia> df = DataFrame(x = 1:3, y = 4:6)  # define a data frame
3×2 DataFrame
 Row │ x      y
     │ Int64  Int64
─────┼──────────────
   1 │     1      4
   2 │     2      5
   3 │     3      6
```

**Manipulation:**

```julia
julia> transform!(df, [:x, :y] => (+) => :z)
3×3 DataFrame
 Row │ x      y      z
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      5
   2 │     2      5      7
   3 │     3      6      9
```

**Dot Syntax:**

```julia
julia> df.z = df.x + df.y
3-element Vector{Int64}:
 5
 7
 9

julia> df  # see that the previous expression updated the data frame `df`
3×3 DataFrame
 Row │ x      y      z
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      5
   2 │     2      5      7
   3 │     3      6      9
```

Recall that the return type from a data frame manipulation function call is always a `DataFrame`.
The return type of a data frame column accessed with dot syntax is a `Vector`.
Thus the expression `df.x + df.y` gets the column data as vectors
and returns the result of the vector addition.
However, in that same line,
we assigned the resultant `Vector` to a new column `z` in the data frame `df`.
We could have instead assigned the resultant `Vector` to some other variable,
and then `df` would not have been altered.
The approach with dot syntax is very versatile
since the data getting, mathematics, and data setting can be separate steps.

```julia
julia> df.x  # dot syntax returns a vector
3-element Vector{Int64}:
 1
 2
 3

julia> v = df.x + df.y  # assign mathematical result to a vector `v`
3-element Vector{Int64}:
 5
 7
 9

julia> df.z = v  # place `v` into the data frame `df` with the column name `z`
3-element Vector{Int64}:
 5
 7
 9
```

However, one way in which dot syntax is less versatile
is that the column name must be explicitly written in the code.
Indexing syntax is a good alternative in these cases
which is only slightly longer to write than dot syntax.
Both indexing syntax and manipulation functions can operate on dynamic column names
stored in variables.

**Setup:**

Imagine this setup data was read from a file and/or entered by a user at runtime.

```julia
julia> df = DataFrame("My First Column" => 1:3, "My Second Column" => 4:6)  # define a data frame
3×2 DataFrame
 Row │ My First Column  My Second Column
     │ Int64            Int64
─────┼───────────────────────────────────
   1 │               1                 4
   2 │               2                 5
   3 │               3                 6

julia> c1 = "My First Column"; c2 = "My Second Column"; c3 = "My Third Column";  # define column names
```

**Dot Syntax:**

```julia
julia> df.c1  # dot syntax expects an explicit column name and cannot be used to access variable column name
ERROR: ArgumentError: column name :c1 not found in the data frame
```

**Indexing:**

```julia
julia> df[:, c3] = df[:, c1] + df[:, c2]  # access columns with names stored in variables
3-element Vector{Int64}:
 5
 7
 9

julia> df  # see that the previous expression updated the data frame `df`
3×3 DataFrame
 Row │ My First Column  My Second Column  My Third Column
     │ Int64            Int64             Int64
─────┼────────────────────────────────────────────────────
   1 │               1                 4                5
   2 │               2                 5                7
   3 │               3                 6                9
```

**Manipulation:**

```julia
julia> transform!(df, [c1, c2] => (+) => c3)  # access columns with names stored in variables
3×3 DataFrame
 Row │ My First Column  My Second Column  My Third Column
     │ Int64            Int64             Int64
─────┼────────────────────────────────────────────────────
   1 │               1                 4                5
   2 │               2                 5                7
   3 │               3                 6                9
```

Additionally, manipulation functions only require
the name of the data frame to be written once.
This can be helpful when dealing with long variable and column names.

**Setup:**

```julia
julia> my_very_long_data_frame_name = DataFrame(
           "My First Column" => 1:3,
           "My Second Column" => 4:6
       )  # define a data frame
3×2 DataFrame
 Row │ My First Column  My Second Column
     │ Int64            Int64
─────┼───────────────────────────────────
   1 │               1                 4
   2 │               2                 5
   3 │               3                 6

julia> c1 = "My First Column"; c2 = "My Second Column"; c3 = "My Third Column";  # define column names
```

**Manipulation:**

```julia

julia> transform!(my_very_long_data_frame_name, [c1, c2] => (+) => c3)
3×3 DataFrame
 Row │ My First Column  My Second Column  My Third Column
     │ Int64            Int64             Int64
─────┼────────────────────────────────────────────────────
   1 │               1                 4                5
   2 │               2                 5                7
   3 │               3                 6                9
```

**Indexing:**

```julia
julia> my_very_long_data_frame_name[:, c3] = my_very_long_data_frame_name[:, c1] + my_very_long_data_frame_name[:, c2]
3-element Vector{Int64}:
 5
 7
 9

julia> df  # see that the previous expression updated the data frame `df`
3×3 DataFrame
 Row │ My First Column  My Second Column  My Third Column
     │ Int64            Int64             Int64
─────┼────────────────────────────────────────────────────
   1 │               1                 4                5
   2 │               2                 5                7
   3 │               3                 6                9
```

Another benefit of manipulation functions and indexing over dot syntax is that
it is easier to operate on a subset of columns.

**Setup:**

```julia
julia> df = DataFrame(x = 1:3, y = 4:6, z = 7:9)  # define data frame
3×3 DataFrame
 Row │ x      y      z
     │ Int64  Int64  Int64
─────┼─────────────────────
   1 │     1      4      7
   2 │     2      5      8
   3 │     3      6      9
```

**Dot Syntax:**

```julia
julia> df.Not(:x)  # will not work; requires a literal column name
ERROR: ArgumentError: column name :Not not found in the data frame
```

**Indexing:**

```julia
julia> df[:, :y_z_max] = maximum.(eachrow(df[:, Not(:x)]))  # find maximum value across all rows except for column `x`
3-element Vector{Int64}:
 7
 8
 9

julia> df  # see that the previous expression updated the data frame `df`
3×4 DataFrame
 Row │ x      y      z      y_z_max
     │ Int64  Int64  Int64  Int64
─────┼──────────────────────────────
   1 │     1      4      7        7
   2 │     2      5      8        8
   3 │     3      6      9        9
```

**Manipulation:**

```julia
julia> transform!(df, Not(:x) => ByRow(max))  # find maximum value across all rows except for column `x`
3×4 DataFrame
 Row │ x      y      z      y_z_max
     │ Int64  Int64  Int64  Int64
─────┼──────────────────────────────
   1 │     1      4      7        7
   2 │     2      5      8        8
   3 │     3      6      9        9
```

Moreover, indexing can operate on a subset of columns *and* rows.

**Indexing:**

```julia
julia> y_z_max_row3 = maximum(df[3, Not(:x)])  # find maximum value across row 3 except for column `x`
9
```

Hopefully this small comparison has illustrated some of the benefits and drawbacks
of the various syntaxes available in DataFrames.jl.
The best syntax to use depends on the situation.
