# Netbeez Bash Style Guide
created by [Joshua Sarver](https://github.com/joshS314159)



# Environment Settings
Always use the following to evaluate your script more strictly:

```
set -e                      # exit all shells if script fails
set -u                      # exit script if uninitialized variable is used
set -o pipefail             # exit script if anything fails in pipe
# set -x;                   # debug mode
```


# Variables
### Quoting and Brackets
Always quote variables in double quotes and brackets (unless it breaks something).

Brackets: Don't let bash determine what part of a string needs expanded into a variable.

```
# okay
echo "$my_foo"
echo "using file: my_$a_var_file"


# good
echo "${my_var}"
echo "using file: my_${a_var}_file"

```

```
# bad
echo $my_var

```

### Creating Variables
Variables should *always* be explictly declared.

```
# good
declare -r MY_BAR="bizzbazz"
```

```
# bad
MY_BAR="bizzbooz"
```

### Naming

* Use snake_case
* Use lower-case inside functions
* Use upper-case (all caps) outside function / for global variables

### Globals
Limit the use of globals. Most variables should be declared as `local`.

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

echo "${MY_FOO}" # output: "hello world!"
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

#### when to use each declaration type

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

declare -r PROGRAM="$0"

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
```

```
# bad
bad_foo(){
	echo "bar"
}

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

Use many, small, well-named functions. Even putting "simple" logic inside a named-function makes the code easier to read.

Example:

```
# good

function kernel_name(){
	echo $(uname)
}

function print_kernel(){
	echo $(kernel_name)
}
```

```
# bad

function print_kernel(){
	echo $(uname)
}
```

## Parameters
Function signatures cannot be set inside a function's parentheses. Variables should be passed and set inside a function explicitly as follows:

```
# good
function foo(){
	local -r bar="$1"
	local -r bizz="$2"
	
	echo "$bar $bizz"
}
```

```
# bad
function bad_foo(){
	echo "$1 $2"
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
Create an `initialize` function where applicable. Use this function to initialize the script. For example, function to parse user input should be called from `initialize`


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


# Conditional Statements

Use double brackets (`[[ ]]`) where possible over single brakets.

```
# good 

function is_macos(){
	if [[ $(kernel_name) == "Darwin" ]]; then
		echo "is macos!"
	fi
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

## relative paths
When navigating by relative path, always being the path with `.` to indicate the current directory.

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


# Linting

[Use shellcheck for linting](https://github.com/koalaman/shellcheck). 

*Always* lint your scripts.

If lint warnings conflict with any rules here, the lint suggestions should take precedence. However, the linter suggestions can usually be brought to consistency with these rules.

The linter takes precedence because it fixes common mistakes and prevents common problems. This is just a style-guide.


# More?

Remember, bash is hard enough to read. Don't make it harder to read.

This guide isn't meant to cover everything. See more here:

* [Google Bash Style Guide](https://google.github.io/styleguide/shell.xml)

* [Bash FAQ](http://mywiki.wooledge.org/BashFAQ#BashFAQ.2F084.How_do_I_return_a_string_.28or_large_number.2C_or_negative_number.29_from_a_function.3F__.22return.22_only_lets_me_give_a_number_from_0_to_255.)

* [Defensive Bash Programming](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/)

