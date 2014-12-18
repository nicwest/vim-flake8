"
" Python filetype plugin for running flake8
" Language:     Python (ft=python)
" Maintainer:   Vincent Driessen <vincent@3rdcloud.com>
" Version:      Vim 7 (may work with lower Vim versions, but not tested)
" URL:          http://github.com/nvie/vim-flake8

let s:save_cpo = &cpo
set cpo&vim

"" ** external ** {{{

function! flake8#Flake8()
    call s:Flake8()
    call s:Warnings()
endfunction
"" }}}

"" ** internal ** {{{

"" warnings 

let s:displayed_warnings = 0
function s:Warnings()
  if !s:displayed_warnings
    let l:show_website_url = 0

    let l:msg = "has been depreciated in favour of flake8 config files"
    for setting_name in ['g:flake8_ignore', 'g:flake8_builtins', 'g:flake8_max_line_length', 'g:flake8_max_complexity']
      if exists(setting_name)
        echohl WarningMsg | echom setting_name l:msg | echohl None
        let l:show_website_url = 1
      endif
    endfor

    if l:show_website_url
      let l:url = "http://flake8.readthedocs.org/en/latest/config.html"
      echohl WarningMsg | echom l:url | echohl None
    endif
    let s:displayed_warnings = 1
  endif
endfunction

"" config

function! s:DeclareOption(name, globalPrefix, default)  " {{{
    if !exists('g:'.a:name)
        if a:default != ''
            execute 'let s:'.a:name.'='.a:default
        else
            execute 'let s:'.a:name.'=""'
        endif
    else
        execute 'let l:global="g:".a:name'
        if l:global != ''
            execute 'let s:'.a:name.'="'.a:globalPrefix.'".g:'.a:name
        else
            execute 'let s:'.a:name.'=""'
        endif
    endif
endfunction  " }}}

function! s:Setup()  " {{{
    "" read options

    " flake8 command
    call s:DeclareOption('flake8_cmd', '', '"flake8"')
    " quickfix
    call s:DeclareOption('flake8_quickfix_location', '', '"belowright"')
    call s:DeclareOption('flake8_quickfix_height', '', 5)
    call s:DeclareOption('flake8_show_quickfix', '', 1)
endfunction  " }}}

"" do flake8

function! s:Flake8()  " {{{
    " read config
    call s:Setup()

    if !executable(s:flake8_cmd)
        echoerr "File " . s:flake8_cmd . " not found. Please install it first."
        return
    endif

    " clear old
    call s:UnplaceMarkers()
    let s:matchids = []
    let s:signids  = []

    " store old grep settings (to restore later)
    let l:old_gfm=&grepformat
    let l:old_gp=&grepprg
    let l:old_shellpipe=&shellpipe

    " write any changes before continuing
    if &readonly == 0
        update
    endif

    set lazyredraw   " delay redrawing
    cclose           " close any existing cwindows

    " set shellpipe to > instead of tee (suppressing output)
    set shellpipe=>

    " perform the grep itself
    let &grepformat="%f:%l:%c: %m\,%f:%l: %m"
    let &grepprg=s:flake8_cmd
    silent! grep! "."

    " restore grep settings
    let &grepformat=l:old_gfm
    let &grepprg=l:old_gp
    let &shellpipe=l:old_shellpipe

    " process results
    let l:results=getqflist()
    let l:has_results=results != []
    if l:has_results
        " quickfix
        if !s:flake8_show_quickfix == 0
            " open cwindow
            execute s:flake8_quickfix_location." copen".s:flake8_quickfix_height
            setlocal wrap
            nnoremap <buffer> <silent> c :cclose<CR>
            nnoremap <buffer> <silent> q :cclose<CR>
        endif
    endif

    set nolazyredraw
    redraw!

    " Show status
    if l:has_results == 0
        echon "Flake8 check OK"
    else
        echon "Flake8 found issues"
    endif
endfunction  " }}}


"" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

