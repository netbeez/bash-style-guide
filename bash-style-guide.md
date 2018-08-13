# Netbeez Bash Style Guide
created by [Joshua Sarver](https://github.com/joshS314159)


# Shebang

Always put `#!/bin/bash`, or whatever shell you intend to use, at the top of the script.

# Environment settings
Always use the following to evaluate your script more strictly:

```
set -e                      # exit all shells if script fails
set -u                      # exit script if uninitialized variable is used
set -o pipefail             # exit script if anything fails in pipe
# set -x;                   # debug mode
```


# Variables
### Quoting and brackets
Always quote variables in double quotes and brackets (unless it breaks something).

Brackets: Don't let bash determine what part of a string needs expanded into a variable.

```
# bad
echo $my_var
echo "$my_foo"
echo "using file: my_$a_var_file"


# good
echo "${my_var}"
echo "using file: my_${a_var}_file"

```


### Creating variables
Variables should *always* be explictly declared.

```
# good
declare -r MY_BAR="bizzbazz"
```

```
# bad
MY_BAR="bizzbooz"
```

Note: Sometimes the linter will give the following warning ([SC2155](https://github.com/koalaman/shellcheck/wiki/SC2155)) regarding masked return values. Make sure you read the documentation on this and understand it. As an example, it can stylistically written/solved as:

```
MY_BAR="a_string_$(some_cmd)"; declare -r MY_BAR
```

### Naming

* Use snake_case
* Use lower-case inside functions
* Use upper-case (all caps) outside function / for global variables
* Append `_dirname` when a variable contains the name (and only the name) of a directory
* Append `_dirpath` when a variable contains the full path to a directory
* Append `_filename` when a variable contains the name (and only the name) of a file
* Append `_filepath` when a variable contains the full path to a file
* Of course, these rules can be expanded to `sockets` etc.

### Globals
Limit the use of globals. Most variables should be declared as `local`.

Put your globals in `main` and pass them around. That's what `main` is for!

#### `declare` statement
The `declare` statement creates a variable with "normal" scoping. Use the readonly flag (`-r`) when possible. Use `-a` to indicate an array. Use `-i` to indicate an integer. `declare` should only be used in the *global* scope.

```
# good
declare MY_AWESOME_GLOBAL="hello world"
declare -ri MY_COOL_INT=5
declare -ra MY_ARRAY=("hello" "world" "!")


function foo(){
	# some code
}
```

```
# bad

function foo(){
	declare MY_AWESOME_GLOBAL="hello world"
	declare -ri MY_COOL_INT=5

	# some code
}

```


#### `readonly` statement
`readonly` creates a constant variable (cannot be changed) in the global scope. This should *only* be used when you want to create a global variable from inside a function scope.


```
# good
function foo(){
	readonly MY_FOO="hello world!"
	echo "${MY_FOO" # output: "hello world!"
}

function main(){
    foo
    echo "${MY_FOO}" # output: "hello world!"
}

```

```
# bad
readonly MY_FOO="hello world!"
function foo(){
	echo "${MY_FOO}" # output: "hello world!"
}

```


#### `local` statement
The `local` statement is an aliases of `declare`. It works the same way, except an error will be thrown if `local` is used outside of a funtion. Due to this extra strictness, `local` should always be used over `declare` inside of functions. The `-r` readonly option should always be used when possible. 

Example 0:

```
# this is the proper way to use local
function foo(){ 
	local -r msg="hello world!"
	local -ri num=5
	echo "${msg}"
	echo "${num}"
}
```

Example 1:

```
# this will throw an error
local -r MSG="hello world!"
function bar(){
	echo "${MSG}"
}
```

Example 2:

```
# don't do this with declare
function bazz(){ 
	declare -r msg="hello world!"
	echo "${msg}"
}
```

#### When to use each declaration type

* `local`
	*  Only use inside functions.
	*  When used outside a function it will throw an error.
*  `declare`
	*  Only use outside of functions (in the global scope).
	*  Although it can be used inside a function, and will keep function scoping, `local` is more clear about intentions of the variable and is stricter.
*  `readonly`
	*  Only use *inside* functions that need *globally* scoped.
	*  Although it can be used in the global scope for global declarations, `declare` is more clear about the intentions of the variable. When you see `readonly`, you know something is being declared outside of the current scope and into the global.


### Putting it all together

```
# a good example of variable use

declare -r PROGRAM="${0}"

function foo(){
	local -r str="hello world!"
	echo "$PROGRAM: ${str}"
}


```

# Functions

## Creation
There are many ways to create `functions` in bash. Always create them like so:

```
# good - this style is most clear that a function is declared
function foo(){
	echo "bar"
}

# okay (more portable)
bad_foo(){
	echo "bar"
}
```

```
# bad
function bad_foo{
	echo "bar"
}

# bad - makes a subshell
function bad_foo(
	echo "bar"
)
```

## General
Always put logic/code inside functions. The only things that should go in the global scope is the environment settings, global variables, and the call to `main`.

Never nest functions. 

Functions cannot be empty.

Use many, small, well-named functions. Even putting "simple" logic inside a named-function makes the code easier to read. Especially if the command might have a confusing name.

Example:

```
# good

function kernel_name(){
	echo "$(uname)"
}

function is_darwin(){
	local status="false"
	
   if [[ "$(kernel_name)" == "Darwin" ]]; then
   		status="true"
   	fi
	
	echo "${status}"
}
```

```
# bad

function is_darwin(){
	local status="false"
	
   if [[ "$(uname)" == "Darwin" ) ]]; then
   		status="true"
   	fi
	
	echo "${status}"
}
```

## Parameters
Function signatures cannot be set inside a function's parentheses. Variables should be passed and set inside a function explicitly as follows:

```
# good
function foo(){
	local -r bar="${1}"
	local -r bizz="${2}"
	
	echo "${bar} ${bizz}"
}
```

```
# bad
function bad_foo(){
	echo "${1} ${2}"
}
```
	

## `main` function
Always create a `main` function. The only function that should be called from the outer global scope is `main`. Then `main` should call all other functions.

Example 0:

```
function main(){
	initialize
	other_fun_function
}
main
```

## `initialize` function
Create an `initialize` function where applicable. Use this function to initialize the script. For example, the function to parse user input should be called from `initialize`


# Parameters

## read_parameters

Parameters should be read from inside a function. 

```
declare -ra ARGS=("$@") # treat as array - see more info here (https://github.com/koalaman/shellcheck/issues/380)

function read_parameters(){    
    local -r args="$@";
    
    local is_dump_data="false"

	 # get opts stuff
	 # ...
	 
    # CREATES GLOBAL VARIABLES #####################
    readonly IS_DUMP_DATA="$is_dump_data"
    # CREATES GLOBAL VARIABLES #####################
}

function initialize(){
    initialize_input "${ARGS[@]-}"
    
}

function main(){
    initialize
}
main

```


# Conditional statements

Use double brackets (`[[ ]]`) where possible over single brakets.

```
# good 

function is_macos(){
   local msg=""
   
	if [[ $(kernel_name) == "Darwin" ]]; then
		msg="is macos!"
	else
		msg="not macos"
	fi
	
	echo "${msg}"
}

```


```
# bad 

function is_macos(){
	if [ $(uname) == "Darwin" ]; then
		echo "is macos!"
	fi
}

```



# Directories

## `cd`
Change directories inside a subshell. 

* helps prevent relative paths from breaking 
* help prevents asking "where am I" when writing a script
* prevents assumptions based on current directory (which could cause breakage)
* allows directory dependent logic to not be ran if the directory doesn't exit

```
# good
function my_cd(){
	local -r my_dir="/tmp/foo/bar"
	( 	cd "$my_dir" || return
		bash "my_great_script.sh" --a-flag
		# script will not be ran if my_dir doesn't exist
	)
}
```

```
# bad
function my_cd(){
	cd "/tmp/foo/bar"
	bash "my_great_script.sh" --a-flag
}
```

## Relative paths
When navigating by relative path, always begin the path with `.` to indicate the current directory.

```
# good
(	cd "./../foo/bar/"
	# do stuff here
)

# good
a_command --some-path="./bizz/bat"
```
```
# bad
(	cd "../foo/bar/"
	# stuff
)
```


# Catch errors

Now that the script exist immediately upon an error, we need to catch and handle them when they happen. Bash doesn't have a try/catch, but we can emulate it.

```
{ # try

    command1
    command 2
    #save your output

} || { # catch
    # save log for exception 
    # handle the error
}
```

Alternatively:

```
command1 || true # continue execution without any handling
```

Remember, the following will cause the script to exit immediatly (if script is evaulated strictly):

```
command1 # returns non-zero
```

# "Importing"

## Functions/variables from scripts

If you'd like to share a function or variable across several scripts, create a script that doesn't self-execute. In this case, you probably won't need a `main` function. Using `source` pulls the data of the separate script into your current environment, it does **not** create a new environment.

"Importing" functions:

```
# file: my-great-library.sh
function foo(){
    echo "this is foo!"
}
```

```
# file: main.sh
source "./my-great-library.sh"

function bar(){
    echo "this is bar!"
}

function main(){
	foo # this is foo!
	bar # this is bar!
}

```

## Environment variables

Note that `set -u` will cause an `exit 1` when referring to an environment variable, because the environment variable was not declared in your script (even though it might/does exist).


```
#...
set -u                      # exit script if uninitialized variable is used
#...

function main(){
	echo "${MY_ENV_VAR_THAT_DEFINITELY_EXISTS}" # exit 1
}

```

How do we get around this? By declaring the variable in the file explicitly before setting restrictions. "Importing" it.

```
declare -r AN_ENV_VAR="${AN_ENV_VAR}"

#...
set -u                      # exit script if uninitialized variable is used
#...

function main(){
	echo "${AN_ENV_VAR}" # <contents of variable>
}

```

If you need to update the environment variable, just use the `export` keyword as usual.



# "Returning" data

Bash can't directly return data from functions (only exit codes). There are three recommended ways to return data: via subshell, subshell with redirection, or a global variable.

* The subshell method is more conventional but conflicts with stdout. This requires a workaround.

* The only downside of a global variable is that it's a global variable. 


###1. Subshell method (w/o work-around):

```
function foo(){
	local -r my_cool_value="hello world!"
	echo "${my_cool_value}"
}

function foo_conflict(){
	local -r my_cool_value="hello world"

	echo "You are now in foo! This is a great function."
	echo "${my_cool_value}"
}

function main(){
	local foo_val="$(foo)"
	echo "${foo_val}" # hello world!
	
	local foo_conflict_val="$(foo_conflict)"
	echo "${foo_conflict_val}" # You are now in foo! This is a great function.\nhello world!
	
}

```

As you can see, anything thrown to stdout gets "returned". If you are strictly echo'ing/logging to a file, this method is okay. However, if you plan to echo to stdout this method is not ideal. Don't break consistency by only logging from functions that aren't called as a sub-shell. If this is the predictament you're in, the global variable method is for you!

###2. Subshell method w/stderr redirection:

```
function log(){
    local -r msg="${1}"
    echo "${msg}" >&2 # redirects all data to stderr, which isn't captured 
}

function foo(){
    local -r my_cool_value="hello world!"

    log "I sure hope this text isn't 'returned'"

    echo "${my_cool_value}"
}

function main(){
    local foo_val="$(foo)"
    echo "${foo_val}" # hello world!
}
```
Anything echo'd to stdout is redirected to stderr. This will still print any logging to the console, but it won't be captured by "super"-shells.


###3. Global variable method:

```
declare _RESULT_=""

function bar(){
	local -r my_cool_value="goodbye world!"
	
	_RESULT_="${my_cool_value}"
}

function bar_no_conflict(){
	local -r my_cool_value="goodbye world!"
	echo "get back to work!"
	_RESULT_="${my_cool_value}"
}



function main(){
	bar
	local -r bar_val="${_RESULT_}"
	
	echo "${bar_val}" # goodbye world!
	
	
	bar_no_conflict
	local -r bar_no_conflict_val="${_RESULT_}"
	
	echo "${bar_no_conflict_val}" # goodbye world!
	
}

```

If you use this method, do **NOT** abuse `_RESULT_`. Treat it like a returned value. In other words, either ignore it or assign it immediately to something local directly below or beside the associated function call. Don't use it to hold a value for later. Global are bad, don't treat `_RESULT_` like one. 


### Best method?

Method 2 is generally the best method.

If you can't use Method 2, evaluate the other methods to use based on your use case.

Where wouldn't you use Method 2? If you really, really need to send data to stdout. For example, Docker handles log streams from stdout and stderr. It would be a poor decision to redirect all logging to stderr inside a container.


# Single exit rule

This doesn't always apply. Sometimes it can make the code harder to read or is near impossible to achieve. Generally, it's a good rule to follow though.

```

# bad
# ***not the best example, make a better one***
function is_foo(){
	local -r input="${1}"
	
	if [[ "${input}" == "hello" ]]; then
		echo "true" 
	elif [[ "${input}" == "world" ]]; then
		echo "true" 
	elif [[ "${input}" == "bad1" ]]; then
		echo "false" 
	elif [[ "${input}" == "bad2" ]] ; then
		echo "false" 	
	else
		echo "false"
	fi
}

# good (also has the benefit of less statements in this case)
# ***not the best example, make a better one***
function is_foo(){
	local -r input="${1}"
	
	local status="false"
	
	if [[ "${input}" == "hello" ]]; then
		status="true" 
	elif [[ "${input}" == "world" ]]; then
		status="true" 
	fi
	
	echo "${status}"
}
	
```

# One command per line & long options

Try to keep it to one command per line for easier reading.

When using arcane options, prefer long options where possible.


```
#bad
function complex_bar(){
	complex_cmd --bizz="abc" --batt="def" --open="zyx" --now
}

#bad
function unzip_me(){
	tar -zdcgtyhnjkiopwe /tmp/some_file.zip # tar feels like this
}


#good
function complex_bar(){
	complex_cmd \
		--bizz="abc" \
		--batt="def" \
		--open="zyx" \
		--now
}
```

Long options aren't always possible to use. Sometimes they might not make sense. For example, it might be okay to assume `mkdir -p /some/dir` doesn't need to use long-params, since it is commonly used. 

Look at long-parameters like named parameters in other languages. It's a good way to make your code clear, but it might also be overkill for a function that simply adds two numbers.

# Temporary files

Some scripts need to write temporary information to disk. One of the safest ways is to create a temporary directory via `mktemp -d`. This will create an empty and randomly named directory that can be written to. No more managing directories inside of `/tmp` or somewhere not suited at all for temporary files.


# Cleaning up temporary files with traps

Some scripts need to write information to disk that needs removed upon exit. Because of the environment options set at the top of the script, an unhandled exception (`exit 1`) will cause the script to exit immediately without executing any other logic. Or maybe a user decides to abort the script.

To force cleanup to occur, use an `exit trap`. An exit trap will execute a function after an abort signal is given.

Example:

```
function a_bad_foo(){
    echo "this function is bad and fails :("
    exit 1
}


function clean_up(){
    # clean up junk files
    echo "Hi! This is the really great clean_up function"
}

function initialize(){
    echo "initializing some cool stuff"
    
    #### THE EXIT TRAP
	trap clean_up EXIT # execute function upon exit
}

function main(){
    initialize
    
    a_bad_foo
}
main

# OUTPUT 
# initializing some cool stuff
# this function is bad and fails :(
# Hi! This is the really great clean_up function


```

In most cases the `trap` should be put inside of the initialization function, but before something could fail.


An example of bad placement:

```
function a_bad_foo(){
    echo "this function is bad and fails :("
    exit 1
}

function clean_up(){
    # clean up junk files
    echo "Hi! This is the really great clean_up function"
}


function main(){
    a_bad_foo
    
    trap clean_up EXIT 
    # BAD placement
    # this command is never evaluated because a_bad_foo kills the script
    
}
main
```

Don't place the `trap` outside of a function though. Remember, everything beside global variable declarations should be in a function.


# Self-logging scripts/functions

Now that we have all of these well-named and specific functions, it's really duplicate work to do the following:

```
function is_this_a_great_function(){
    log "checking if this function is great"
    echo "false"
}
```


Instead, log the dynamic function name like so:

```
function log_func(){
    local -r function_name="${1}"
    log "${function_name}()"
}


function is_this_a_great_function(){
    log_func "${FUNCNAME[0]}"
    
    echo "true"
}

```

Here's some sample output of a script. This makes debugging/tracing extremely easy:

```
agent_setup.sh: main()
agent_setup.sh: initialize()
agent_setup.sh: initialize_input()
agent_setup.sh: check_input()
agent_setup.sh: echo_count()

```

This isn't to say that functions can't have additional logging. But including `log_func "${FUNCNAME[0]}"` at the top of (most) functions makes for easily logging scripts.

If you decide to go this route, it's probably best not call `log_func` from your other logging functions.



# Linting

[Use shellcheck for linting](https://github.com/koalaman/shellcheck). 

*Always* lint your scripts.

If lint warnings conflict with any rules here, the lint suggestions should take precedence. However, the linter suggestions can usually be brought to consistency with these rules.

The linter takes precedence because it fixes common mistakes and prevents common problems. This is guide is mostly related to style.

# Summary

There are many suggestions in here. Here are a few key take-aways:

1. Put everything in small, well-defined functions
2. Use a `main`
3. Explicitly declare your variables
4. Keep global variables to a minimum, pass around local variables
5. Quote all variables when possible
6. Set environment options so common-sense errors are thrown
7. Use common sense. Most of these rules don't apply 100% of the time. But try to follow as closely as possible, and break convention when needed. Some shells (`sh`) doesn't support all these features, etc. What's important is to add structure wherever possible.



# More?

This guide isn't meant to cover everything. See more here (ranked):

1. [Bash FAQ](http://mywiki.wooledge.org/BashFAQ#BashFAQ.2F084.How_do_I_return_a_string_.28or_large_number.2C_or_negative_number.29_from_a_function.3F__.22return.22_only_lets_me_give_a_number_from_0_to_255.)

2. [Google Bash Style Guide](https://google.github.io/styleguide/shell.xml)

3. [Defensive Bash Programming](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/)



