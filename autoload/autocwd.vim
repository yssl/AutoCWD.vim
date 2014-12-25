" File:         autoload/autocwd.vim
" Description:  Auto current working directory update system
" Author:       yssl <http://github.com/yssl>
" License:      

" wrappers
function! autocwd#PrintWorkDirs()
	call s:PrintWorkDirs()
endfunction

" script variables

" initialize python 
python << EOF
import vim
import fnmatch

s_typeLabelsd = {
	'iscurwin':'',
	'winnr':'#',
	'winname':'Window',
	'workdir':'Working Directory',
	'workdir_pattern':'Pattern',
	}

def toWidthColMat(rowMat):
	colMat = [[None]*len(rowMat) for c in range(len(rowMat[0]))]
	for r in range(len(rowMat)):
		for c in range(len(rowMat[r])):
			colMat[c][r] = len(rowMat[r][c])
	return colMat

def ltrunc(s, width, prefix=''):
    if width >= len(s): prefix = ''
    return prefix+s[-width+len(prefix):]
    
def rtrunc(s, width, postfix=''):
    if width >= len(s): postfix = ''
    return s[:width-len(postfix)]+postfix
EOF

" functions
function! s:GetWorkDir(filepath)
python << EOF
filepath = vim.eval('a:filepath')
patternwd_pairs = vim.eval('g:autocwd_patternwd_pairs')
inpatternwd = False
for pattern, wd in patternwd_pairs:
	if fnmatch.fnmatch(filepath, pattern):
		wd = vim.eval('expand(\'%s\')'%wd)
		if '*REPO*' in wd:
			wd = wd.replace('*REPO*', findRepoDirFrom(filepath))
	   	if os.path.isdir(wd):
			inpatternwd = True
			vim.command('return \'%s\''%wd)
			break
if inpatternwd==False:
	vim.command('return g:autocwd_defaultwd')
EOF
endfunction

function! s:GetWorkDirPattern(filepath)
python << EOF
import fnmatch
filepath = vim.eval('a:filepath')
patternwd_pairs = vim.eval('g:autocwd_patternwd_pairs')
inpatternwd = False
for pattern, wd in patternwd_pairs:
	if fnmatch.fnmatch(filepath, pattern):
		wd = vim.eval('expand(\'%s\')'%wd)
		if '*REPO*' in wd:
			wd = wd.replace('*REPO*', findRepoDirFrom(filepath))
	   	if os.path.isdir(wd):
			inpatternwd = True
			vim.command('return \'%s\''%pattern)
			break
if inpatternwd==False:
	vim.command('return \'\'')
EOF
endfunction

function! s:BuildAllWinPropMat(propTypes)
python << EOF
vim.command('let mat = []')
curwin = vim.current.window
curwin_r = 0

propTypes = vim.eval('a:propTypes')
vim.command('call add(mat, %s)'%str([s_typeLabelsd[type] for type in propTypes]))

for r in range(len(vim.windows)):
	vim.command(str(r+1)+'wincmd w')
	vim.command('call add(mat, [])')

	if vim.windows[r]==curwin:
		curwin_r = r

	bufname = vim.windows[r].buffer.name
	buftype = vim.eval('getbufvar(winbufnr(winnr()), \'&buftype\')')

	for type in propTypes:
		if type=='iscurwin':
			if vim.windows[r]==curwin:	strcurwin = '* '
			else:						strcurwin = '  '
			vim.command('call add(mat[-1], \'%s\')'%strcurwin)

		elif type=='winnr':
			vim.command('call add(mat[-1], \'%s\')'%str(r+1))

		elif type=='winname':
			vim.command('call add(mat[-1], \'%s\')'%getWinName(bufname, buftype))

		elif type=='workdir':
			dir = vim.eval('s:GetWorkDir(\'%s\')'%getWinName(bufname, buftype))
			#print '|%s|%s|%s|'%(bufname,buftype,dir)
			vim.command('call add(mat[-1], \'%s\')'%dir)

		elif type=='workdir_pattern':
			pattern = vim.eval('s:GetWorkDirPattern(\'%s\')'%getWinName(bufname, buftype))
			vim.command('call add(mat[-1], \'%s\')'%pattern)

vim.command(str(curwin_r+1)+'wincmd w')
vim.command('return mat')
EOF
endfunction

function! s:PrintWorkDirs()
	let a:type = 'workdir'
python << EOF
vim.command('let propTypes = ["iscurwin", "winnr", "winname", "workdir_pattern", "workdir"]')
wpMat = vim.eval('s:BuildAllWinPropMat(propTypes)')
propTypes = vim.eval('propTypes')

# build width info
vimWidth = int(vim.eval('&columns'))
widthColMat = toWidthColMat(wpMat)

widths = []
len_labels = int(vim.eval('len(propTypes)'))
sumLongWidths = 0
for c in range(len_labels):
	if c==0:	gapWidth = 0
	else:		gapWidth = 2
	maxColWidth = max(widthColMat[c]) + gapWidth
	widths.append(maxColWidth)

	if propTypes[c]=='winname' or propTypes[c]=='workdir':
		sumLongWidths += maxColWidth

totalWidth = sum(widths)
reduceWidth = totalWidth - vimWidth
if reduceWidth > 0:
	for c in range(len_labels):
		if propTypes[c]=='winname' or propTypes[c]=='workdir':
			widths[c] -= int(reduceWidth * float(widths[c])/sumLongWidths)+1

# print
prefix = '..'
for r in range(len(wpMat)):
	if r==0:	vim.command('echohl Title')
	s = ''
	for c in range(len(wpMat[0])):
		if len(wpMat[r][c])<=widths[c]:
			s += wpMat[r][c].ljust(widths[c])
		else:
			s += ltrunc(wpMat[r][c], widths[c]-2, prefix)+'  '
	vim.command('echo \'%s\''%s)
	if r==0:	vim.command('echohl None')
EOF
endfunction
