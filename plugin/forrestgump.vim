" *vim-forrestgump*     Run code on-the-fly in vim
"
" Version: 1.0.3
" Author:  Henrik Lissner <http://henrik.io>

if exists("g:loaded_forrestgump")
    finish
endif
let g:loaded_forrestgump = 1


" Defaults

if !exists("g:forrestgumps")
    let g:forrestgumps = {}
endif

if !exists("g:forrestgump_no_mappings")
    let g:forrestgump_no_mappings = 0
endif


" Functions {

    " run() {
    func! s:runFile()
        let gump = s:findGump()
        if type(gump) != 3
            return
        endif

        " Run the file or its contents through the gump and store output in
        " a tmepfile
        let file = expand('%:p')
        if strlen(file)
            let result = system(gump[0]." ".file)
        else
            let contents = getline(1, "$")
            let result = system(gump[0], join(contents, "\n"))
        endif

        " Open tempfile in preview
        call s:preview(result)
    endfunc
    " }

    " runLines() {
    func! s:runLines() range
        let gump = s:findGump()
        if type(gump) != 3
            return
        endif

        " Grab the code. Prepend the second list item if it exists, and if it
        " isn't present in the code being run.
        let code = join(getline(a:firstline, a:lastline), "\n")
        if len(gump) == 2 && match(code, gump[1]) == -1
            let code = gump[1] . " \n " . code
        endif

        " Run code through the gump and send output to tempfile
        let result = system(gump[0], code)

        " Open tempfile in preview
        call s:preview(result)
    endfunc
    " }
    
    " preview() {
    " Open a preview window and inject output into it
    func! s:preview(content)
        " Open preview buffer
        pedit! RESULTS

        " Switch to preview window
        wincmd P
        setl buftype=nofile noswapfile syntax=none bufhidden=delete
        normal ggdG

        " Write it into the window
        call append('^', split(a:content, "\n"))
        nnoremap <buffer> <Esc> :pclose<CR>
    endfunc
    " }

    " findGump() {
    " Check to see if a gump for the current filetype exists or not
    func! s:findGump()
        " No filetype?
        if strlen(&filetype)
            let ft = split(&filetype, "\\.")[0]
            if has_key(g:forrestgumps, ft)
                let gump = g:forrestgumps[ft]
            endif
        else
            " Check for shebang line
            let firstline = getline(1)
            if firstline[0:1] !=# "#!"
                " Otherwise, no gump!
                echom "No filetype specified! (".firstline[0:1].")"
                return
            endif

            let gump = [substitute(firstline[2:], '^\s*\(.\{-}\)\s*$', '\1', '')]
            let gumplen = strlen(gump[0])
            if gumplen > 0
                let ft = split(split(firstline[2:], '/')[-1])[-1]
                if has_key(g:forrestgumps, ft)
                    let gump = g:forrestgumps[ft]
                endif
            elseif gumplen == 0
                unlet gump
            endif
        endif

        if exists("gump")
            if type(gump) != 3 || get(gump, 0) != 0
                echoe "Gump for ".&filetype." isn't set up properly"
                return
            elseif !executable(gump[0])
                echoe "Gump for ".&filetype." isn't executable (".gump[0].")"
                return
            endif
            return gump
        endif

        echom "No gump available for this filetype"
        return
    endfunc
    " }

    " defineGump {
    " For associating default filetypes to interpreters 
    func! s:defineGump(filetype, opts)
        if !has_key(g:forrestgumps, a:filetype)
            let g:forrestgumps[a:filetype] = a:opts
        endif
    endfunc
    " }

" }

""""""""""""""""""""""""""
" Bootstrap {

    " Default gumps
    call s:defineGump("php",          ["php", "<?php"])
    call s:defineGump("python",       ["python"])
    call s:defineGump("py",           ["python"])
    call s:defineGump("ruby",         ["ruby"])
    call s:defineGump("perl",         ["perl"])
    call s:defineGump("javascript",   ["node"])
    call s:defineGump("js",           ["node"])
    call s:defineGump("coffee",       ["coffee"])
    call s:defineGump("sh",           ["sh"])
    call s:defineGump("bash",         ["bash"])
    call s:defineGump("zsh",          ["zsh"])
    call s:defineGump("lua",          ["lua"])

    " Maps
    map <silent> <Plug>ForrestRunFile :call <SID>runFile()<CR>
    map <silent> <Plug>ForrestRunLines :call <SID>runLines()<CR>

    if g:forrestgump_no_mappings != 1
        nmap <leader>r <Plug>ForrestRunFile
        vmap <leader>r <Plug>ForrestRunLines
    endif

" }

" vim: set foldmarker={,} foldlevel=0 foldmethod=marker
