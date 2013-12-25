" File:         plugin/PatternCWD.vim
" Description:  
" Author:       yssl <http://github.com/yssl>
" License:      

if exists("g:loaded_patterncwd") || &cp
	finish
endif
let g:loaded_patterncwd	= 1
let s:keepcpo           = &cpo
set cpo&vim
"""""""""""""""""""""""""""""""""""""""""""""

" global variables
if !exists('g:patterncwd_defaultwd')
	let g:patterncwd_defaultwd = getcwd()
endif
if !exists('g:patterncwd_repodirs')
	let g:patterncwd_repodirs = ['.git', '.hg', '.svn']
endif
if !exists('g:patterncwd_patternwd_pairs')
	let g:patterncwd_patternwd_pairs = []
endif
if !exists('g:patterncwd_noupdate_defaultwd_for')
	let g:patterncwd_noupdate_defaultwd_for = ['ControlP']
endif

" commands
command! PatternCWDPrintWorkDirs call PatternCWD#PrintWorkDirs()
command! PCprint call PatternCWD#PrintWorkDirs()

" autocmd
augroup PatternCWDAutoCmds
	autocmd!
	autocmd BufEnter * call s:OnEnterBuf() 
	autocmd BufLeave * call s:OnLeaveBuf() 
augroup END

" initialize python 
python << EOF
import vim
import fnmatch

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
EOF

" functions
function! s:OnEnterBuf()
	let bufname = expand('<afile>')
	if filereadable(getcwd().'/'.bufname)
		let bufname = getcwd().'/'.bufname
	endif

	let buftype = getbufvar(winbufnr(winnr()), '&buftype')

	let wd = s:ExistPattern(bufname, buftype)[1]
	execute 'cd' wd
endfunction

function! s:OnLeaveBuf()
	let bufname = expand('<afile>')
	if filereadable(getcwd().'/'.bufname)
		let bufname = getcwd().'/'.bufname
	endif

	for noupdatename in g:patterncwd_noupdate_defaultwd_for
		if match(bufname, noupdatename) >= 0
			return
		endif
	endfor

	let buftype = getbufvar(winbufnr(winnr()), '&buftype')

	let exist = s:ExistPattern(bufname, buftype)[0]
	if exist==0
		let g:patterncwd_defaultwd = getcwd()
	endif
endfunction

function! s:ExistPattern(bufname, buftype)
python << EOF
bufname = vim.eval('a:bufname')
buftype = vim.eval('a:buftype')
filepath = getWinName(bufname, buftype)
patternwd_pairs = vim.eval('g:patterncwd_patternwd_pairs')
inpatternwd = False
for pattern, wd in patternwd_pairs:
	wd = vim.eval('expand(\'%s\')'%wd)
	if fnmatch.fnmatch(filepath, pattern) and os.path.isdir(wd):
		inpatternwd = True
		vim.command('return [1, \'%s\']'%wd)
		break
if inpatternwd==False:
	vim.command('return [0, g:patterncwd_defaultwd]')
EOF
endfunction

"""""""""""""""""""""""""""""""""""""""""""""
let &cpo= s:keepcpo
unlet s:keepcpo
