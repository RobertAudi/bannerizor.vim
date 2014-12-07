"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''"
"'                  ____                              _                                '"
"'                 |  _ \                            (_)                               '"
"'                 | |_) | __ _ _ __  _ __   ___ _ __ _ _______  _ __                  '"
"'                 |  _ < / _` | '_ \| '_ \ / _ \ '__| |_  / _ \| '__|                 '"
"'                 | |_) | (_| | | | | | | |  __/ |  | |/ / (_) | |                    '"
"'                 |____/ \__,_|_| |_|_| |_|\___|_|  |_/___\___/|_|                    '"
"'                                                                                     '"
"'                                     Robert Audi                                     '"
"'                           <https://github.com/RobertAudi>                           '"
"'                                                                                     '"
"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''"
"'                                                                                     '"
"'   The MIT License (MIT)                                                             '"
"'                                                                                     '"
"'   Copyright (c) 2014 Robert Audi                                                    '"
"'                                                                                     '"
"'   Permission is hereby granted, free of charge, to any person obtaining a copy      '"
"'   of this software and associated documentation files (the "Software"), to deal     '"
"'   in the Software without restriction, including without limitation the rights      '"
"'   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         '"
"'   copies of the Software, and to permit persons to whom the Software is             '"
"'   furnished to do so, subject to the following conditions:                          '"
"'                                                                                     '"
"'   The above copyright notice and this permission notice shall be included in all    '"
"'   copies or substantial portions of the Software.                                   '"
"'                                                                                     '"
"'   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        '"
"'   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          '"
"'   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       '"
"'   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            '"
"'   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     '"
"'   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     '"
"'   SOFTWARE.                                                                         '"
"'                                                                                     '"
"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists("g:loaded_bannerizor") || &cp || v:version < 700
  finish
endif
let g:loaded_bannerizor = 1

if ! exists("g:bannerizor_filetype_comment_chars")
  let g:bannerizor_filetype_comment_chars = {
        \        'vim':  '"',
        \       'ruby':  '#',
        \        'zsh':  '#',
        \         'sh':  '#',
        \        'lua': '--'
        \ }
endif

let s:bannerizor_defaults = { 'char': '', 'padding': 5 }

function! s:initopt(opt, val)
  let l:bopt = "b:" . a:opt
  if ! exists(l:bopt)
    execute "let " . l:bopt . " = '" . a:val . "'"
  endif
endfunction

function! s:initopts()
  for l:opt in keys(s:bannerizor_defaults)
    let l:fullopt = "bannerizor_" . l:opt
    let l:gopt = "g:" . l:fullopt
    let l:optval = exists(l:gopt) ? eval(l:gopt) : get(s:bannerizor_defaults, l:opt)
    call s:initopt(l:fullopt, l:optval)
  endfor

  call s:initopt("bannerizor_commentchar", get(g:bannerizor_filetype_comment_chars, &filetype, ""))
endfunction

function! s:parseargs(args)
  call s:initopts()

  let l:args = {}
  let l:args.char    = b:bannerizor_char
  let l:args.padding = b:bannerizor_padding

  if ! empty(a:args)
    let l:rawargs = a:args[0]
    if type(l:rawargs) == type("")
      let l:args.char    = l:rawargs
    elseif type(l:rawargs) == type({})
      let l:args.char    = get(l:rawargs, "char",    b:bannerizor_char)
      let l:args.padding = get(l:rawargs, "padding", b:bannerizor_padding)
    else
      echoerr "Invalid arg, bitch!"
      echomsg "Using the defaults instead.."
    endif
  endif
  return l:args
endfunction

function! s:comment(line, commentchar)
  let l:commentchar_pattern = "^" . a:commentchar
  if a:line =~ l:commentchar_pattern
    return a:line
  else
    return a:commentchar . " " . a:line
  endif
endfunction

function! s:uncomment(line, commentchar)
  let l:commentchar_pattern = "^" . a:commentchar
  if a:line =~ l:commentchar_pattern
    return substitute(a:line, l:commentchar_pattern . " ", "", "")
  else
    return a:line
  endif
endfunction

function! s:doit(args, doabove)
  let l:args = s:parseargs(a:args)
  let l:bannerchar    = l:args.char
  let l:bannerpadding = l:args.padding

  let l:rawline    = getline(".")
  let l:lineparts  = matchlist(l:rawline, '^\(\s*\)\(.*\)$')
  let l:whitespace = l:lineparts[1]
  let l:line       = l:lineparts[2]

  if strlen(b:bannerizor_commentchar) > 0
    let l:line = s:uncomment(l:line, b:bannerizor_commentchar)
  endif

  let l:bannerlines  = []
  let l:bannerborder = repeat(l:bannerchar, strlen(l:line))
  if a:doabove
    let l:bannerborder .= repeat(l:bannerchar, (l:bannerpadding * 2))
    let l:paddingstring = repeat(" ", l:bannerpadding)
    let l:line = l:paddingstring . l:line
    let l:bannerlines += [l:bannerborder]
  endif
  let l:bannerlines += [l:line, l:bannerborder]

  if strlen(b:bannerizor_commentchar) > 0
    let l:lines = []
    for l:bannerline in l:bannerlines
      let l:lines += [l:whitespace . s:comment(l:bannerline, b:bannerizor_commentchar)]
    endfor
    let l:bannerlines = l:lines
  endif

  " TODO: Add the option to automatically insert
  "       a blank line under the banner
  " let l:bannerlines += [""]

  let l:curlinenbr = line(".")
  let l:linenbr = l:curlinenbr + len(l:bannerlines)
  call append(l:curlinenbr, l:bannerlines)
  execute l:curlinenbr . "delete"
  call setpos(".", [bufnr("."), l:linenbr - 1, strlen(l:whitespace) + 1, 0])
endfunction

function! bannerizor#bannerize(...)
  call s:doit(a:000, 1)
endfunction

function! bannerizor#titleize(...)
  call s:doit(a:000, 0)
endfunction
