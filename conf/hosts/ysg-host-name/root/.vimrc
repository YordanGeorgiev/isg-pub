" file:~/.vimrc v1.2.0 docs at the end

" everything after a double quote is a comment.
" enable syntax hightlighting

" adjust the backspace behaviour 
set backspace=indent,eol,start

" allways show status line
set ls=2

" set the default windows height to 92
set winheight=92

" set the brightest possible colorscheme
colorscheme elflord

" set the number of spaces the tab should produce
set tabstop=3

" display always the row number on the left
set number

" ignore case when searching
set ignorecase

" show the title in the console title bar
" set title

" smooth changes
set ttyfast

" highlight the searched items
set hlsearch

" autoindent by default
set autoindent

" set the default shift width
set sw=3


" set the number of columns
set co=120

" set wrapping by default
set wrap

" start custom mappings
" =======================================================
" f4 would go to the next buffer
map <F3> :bn!<CR>

" f3 would go to the previous bugger
map <F2> :bp!<CR>

" F5 should find the next occurrence after vimgrep
map <F5> :cp!<CR>

" F6 should find the previous occurrence after vimgrep
map <F6> :cn!<CR>

" stop custom mappings
" =======================================================

" show additional info for the current buffer - line, char number
set ruler

" set the syntax by default
syntax on

" enable filetype plugin
filetype plugin on


"" enable MUI type of buffer switching
" NOK map <C-Tab> :bn!<CR>

" Purpose:
" provide the defaults for the vim on the hostname host
" credits and sources : http://phuzz.org/vimrc.html
"
" VersionHistory
"
" 1.1.3 --- 2013-04-24 14:18:12 --- ysg --- added the filetype plugin on
" 1.1.2 --- 2012-12-26 11:42:26 --- ysg --- re-formatting
" 1.1.0 --- 2012-12-25 10:56:12 --- ysg --- to vim syntax, new settings
" 1.0.0 --- 2012-12-24 14:22:52 --- ysg --- Initial creation from source

