" File:         plugin/autocwd.vim
" Description:  Auto current working directory update system
" Author:       yssl <http://github.com/yssl>
" License:      

if exists("g:loaded_autocwd") || &cp
	finish
endif
let g:loaded_autocwd	= 1
let s:keepcpo           = &cpo
set cpo&vim
"""""""""""""""""""""""""""""""""""""""""""""

" global variables
if !exists('g:autocwd_patternwd_pairs')
	let g:autocwd_patternwd_pairs = []
endif
if !exists('g:autocwd_not_update_defaultwd_for')
	let g:autocwd_not_update_defaultwd_for = ['ControlP']
endif
if !exists('g:autocwd_defaultwd')
	let g:autocwd_defaultwd = getcwd()
endif
if !exists('g:autocwd_repodirs')
	let g:autocwd_repodirs = ['.git', '.hg', '.svn']
endif

" commands
command! AutoCWDPrint call autocwd#PrintWorkDirs()

" autocmd
augroup AutoCWDAutoCmds
	autocmd!
	autocmd BufEnter * call s:OnEnterBuf() 
	autocmd BufLeave * call s:OnLeaveBuf() 
augroup END

" initialize python 
python << EOF
import vim
import os, fnmatch

def getWinName(bufname, buftype):
	if bufname==None:
		if len(buftype)>0:
			winname = '[%s]'%buftype
		else:
			winname = '[No Name]'
	else:
		if len(buftype)>0:
			winname = os.path.basename(bufname)
			winname = '[%s] %s'%(buftype, winname)
		else:
			winname = bufname
	return winname

def findRepoDirFrom(firstdir):
	repodirs = vim.eval('g:autocwd_repodirs')
	dir = firstdir
	while True:
		exist = False
		for repodir in repodirs:
			if os.path.exists(os.path.join(dir, repodir)):
				return dir

		prevdir = dir
		dir = os.path.dirname(dir)
		if dir==prevdir:
			#print 'no repo dir in ancestors of %s'%firstdir
			return ''
EOF


" functions
function! s:OnEnterBuf()
	let bufname = expand('<afile>')
	if filereadable(getcwd().'/'.bufname)
		let bufname = getcwd().'/'.bufname
	endif

	let buftype = getbufvar(winbufnr(winnr()), '&buftype')

	let wd = s:ExistPattern(bufname, buftype)[1]
	execute 'cd' fnameescape(wd)
endfunction

function! s:OnLeaveBuf()
	let bufname = expand('<afile>')
	if filereadable(getcwd().'/'.bufname)
		let bufname = getcwd().'/'.bufname
	endif

	for noupdatename in g:autocwd_not_update_defaultwd_for
		if match(bufname, noupdatename) >= 0
			return
		endif
	endfor

	let buftype = getbufvar(winbufnr(winnr()), '&buftype')

	let exist = s:ExistPattern(bufname, buftype)[0]
	if exist==0
		let g:autocwd_defaultwd = getcwd()
	endif
endfunction

function! s:ExistPattern(bufname, buftype)
python << EOF
bufname = vim.eval('a:bufname')
buftype = vim.eval('a:buftype')
filepath = getWinName(bufname, buftype)
patternwd_pairs = vim.eval('g:autocwd_patternwd_pairs')
inpatternwd = False
for pattern, wd in patternwd_pairs:
	wd = vim.eval('expand(\'%s\')'%wd)
	if fnmatch.fnmatch(filepath, pattern):
		if '*REPO*' in wd:
			wd = wd.replace('*REPO*', findRepoDirFrom(filepath))
	   	if os.path.isdir(wd):
			inpatternwd = True
			vim.command('return [1, \'%s\']'%wd)
			break
if inpatternwd==False:
	vim.command('return [0, g:autocwd_defaultwd]')
EOF
endfunction

"""""""""""""""""""""""""""""""""""""""""""""
let &cpo= s:keepcpo
unlet s:keepcpo
