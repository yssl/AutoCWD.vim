" wrappers
function! PatternCWD#PrintWorkDirs()
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
function! s:GetWorkDir(filepath)
python << EOF
filepath = vim.eval('a:filepath')
patternwd_pairs = vim.eval('g:patterncwd_patternwd_pairs')
inpatternwd = False
for pattern, wd in patternwd_pairs:
	if fnmatch.fnmatch(filepath, pattern):
		inpatternwd = True
		vim.command('return expand(\'%s\')'%wd)
		break
if inpatternwd==False:
	vim.command('return g:patterncwd_defaultwd')
EOF
endfunction

function! s:GetWorkDirPattern(filepath)
python << EOF
import fnmatch
filepath = vim.eval('a:filepath')
patternwd_pairs = vim.eval('g:patterncwd_patternwd_pairs')
inpatternwd = False
for pattern, wd in patternwd_pairs:
	if fnmatch.fnmatch(filepath, pattern):
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
vim.command('let propTypes = ["iscurwin", "winnr", "winname", a:type."_pattern", a:type]')
wpMat = vim.eval('s:BuildAllWinPropMat(propTypes)')

# build width info
totalWidth = int(vim.eval('&columns'))
widthColMat = toWidthColMat(wpMat)

accWidth = 0
widths = []
len_labels = int(vim.eval('len(propTypes)'))
for c in range(len_labels):
	if c < len_labels-1:
		if c==0:	gapWidth = 0
		else:		gapWidth = 2
		maxColWidth = max(widthColMat[c]) + gapWidth
		accWidth += maxColWidth
		widths.append(maxColWidth)
	else:
		widths.append(totalWidth - accWidth-1)

# print
for r in range(len(wpMat)):
	if r==0:	vim.command('echohl Title')
	s = ''
	for c in range(len(wpMat[0])):
		if len(wpMat[r][c])<widths[c]:
			s += wpMat[r][c].ljust(widths[c])
		else:
			s += wpMat[r][c]
	vim.command('echo \'%s\''%s)
	if r==0:	vim.command('echohl None')
EOF
endfunction
