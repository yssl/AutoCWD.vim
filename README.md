# autocwd.vim

autocwd.vim automatically changes the current working directory (CWD) of vim when you change the current buffer.
You can define patterns that be may included in a name or file path of a buffer, and their working directories in your .vimrc. 
The predefined working directories can be the directory of the current buffer's file, absolute paths of specific directories, and so on.

This plugin requires a version of vim with python support.
You can check your vim with `:echo has('python')`.

Screenshot:
![cwdpattern](https://cloud.githubusercontent.com/assets/5915359/3622432/de3ce5c8-0e33-11e4-8a78-ff5d8bc33d92.png)

## Usage

You can define patterns and working directories in your .vimrc as follows:

```
let g:autocwd_patternwd_pairs = [
	\[pattern1, working_directory1],
	\[pattern2, working_directory2],
	...
	\]
```

- *pattern* is a substring of a file path or buffer name with Unix shell-style wildcards.  
For example, '\*.vim' matches files with .vim extension and '\*/project1/\*' matches files that contains 'project1' in their absolute file paths.  
(Please refer https://docs.python.org/2/library/fnmatch.html for more information.
*patterns* are processed by python's *fnmatch* function internally.)

- *working_directory* will be the CWD when the corresponding *pattern* matches the current buffer.  
It can be one of following types:

	type | example:<br> working_directory | example:<br> CWD to be changed
	--- | --- | ---
	absolute path | '~/test' | ~/test
	vim's file name modifier<sup>1</sup> | '%:p:h' | current file's directory
	special keyword: \*REPO\* | '\*REPO\*/bin' | ~/code/bin<sup>2</sup>

	- <sup>1</sup>Please refer http://vimdoc.sourceforge.net/htmldoc/cmdline.html#filename-modifiers for more information.  
	- <sup>2</sup>\*REPO\* is replaced with the repository root directory that contains current file.  
	The example directory structure is:
	```
	+-- ~/code 
	|	+-- .git
	|	+-- bin
	|	+-- examples
	|	|	+-- ex1
	| 	|	|	+-- current file
	```

- If the current buffer matches one of the defined patterns, the CWD will be changed to the corresponding working directory.
Otherwise, the default working directory that have been the CWD before applying `g:autocwd_patternwd_pairs` will be restored.  
You can change the default working directory by `:cd` or other CWD-changing commands (e.g., 'cd' of the NERDTree) when the current buffer does not match any of predefined patterns.

- The order of patterns in `g:autocwd_patternwd_pairs` is meaningful.
If the current buffer matches both first and second patterns, the working directory corresponding to the first pattern will be the CWD.

An example pattern-wd pairs for the screenshot:
```
let g:autocwd_patternwd_pairs = [
	\['*.vim', '%:p:h'],
	\['*.py', '%:p:h'],
	\['*/vim74/*', '/home/testid/vim74'],
	\['*/blender-2.68/*', '/home/testid/blender-2.68'],
	\]
```

## Commands

**:AutoCWDPrint**  
Print the buffer name or file path, matched pattern, and working directory of windows in the current tab.

There is no activation commands for autocwd.vim. 
If you install this plugin, it will starts to manage the CWD.

## Motivation

It is quite useful to set the CWD for each opened file in vim.
Vim provides `:lcd` command for this purpose. 
However, it cannot deal with opening other files in the same window because `:lcd` is applied to a specific window, not buffer.  

autocwd.vim is designed to solve this problem.
Moreover, it provides more convenient way to set CWDs with Unix shell-style patterns.
