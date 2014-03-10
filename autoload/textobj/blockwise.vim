scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" a <= b
function! s:pos_less_equal(a, b)
	return a:a[0] == a:b[0] ? a:a[1] <= a:b[1] : a:a[0] <= a:b[0]
endfunction

" a == b
function! s:pos_equal(a, b)
	return a:a[0] == a:b[0] && a:a[1] == a:b[1]
endfunction

" a < b
function! s:pos_less(a, b)
	return a:a[0] == a:b[0] ? a:a[1] < a:b[1] : a:a[0] < a:b[0]
endfunction

" begin < pos && pos < end
function! s:is_in(range, pos)
	return type(a:pos) == type([]) && type(get(a:pos, 0)) == type([])
\		 ? len(a:pos) == len(filter(copy(a:pos), "s:is_in(a:range, v:val)"))
\		 : s:pos_less(a:range[0], a:pos) && s:pos_less(a:pos, a:range[1])
endfunction


function! s:as_config(config)
	let default = {
\		"textobj" : "",
\		"is_cursor_in" : 0,
\		"noremap" : 0,
\		"count" : v:count > 0 ? v:count : ''
\	}
	let config
\		= type(a:config) == type("") ? { "textobj" : a:config }
\		: type(a:config) == type({}) ? a:config
\		: {}
	return extend(default, config)
endfunction


let s:region = []
let s:wise = ""
function! textobj#blockwise#region_operator(wise)
	let reg_save = @@
	let s:wise = a:wise
	let s:region = [getpos("'[")[1:], getpos("']")[1:]]
	let @@ = reg_save
endfunction


nnoremap <silent> <Plug>(textobj-blockwise-region-operator)
\	:<C-u>set operatorfunc=textobj#blockwise#region_operator<CR>g@


function! textobj#blockwise#region_from_textobj(textobj)
	let s:region = []
	let config = s:as_config(a:textobj)

	let pos = getpos(".")
	try
		silent execute (config.noremap ? 'onoremap' : 'omap') '<expr>'
\			'<Plug>(textobj-blockwise-target)' string(config.count . config.textobj)

		let tmp = &operatorfunc
		silent execute "normal \<Plug>(textobj-blockwise-region-operator)\<Plug>(textobj-blockwise-target)"
		let &operatorfunc = tmp

		if !empty(s:region) && !s:pos_less_equal(s:region[0], s:region[1])
			return ["", []]
		endif
		if !empty(s:region) && config.is_cursor_in && (s:pos_less(pos[1:], s:region[0]) || s:pos_less(s:region[1], pos[1:]))
			return ["", []]
		endif
		return deepcopy([s:wise, s:region])
	finally
		call setpos(".", pos)
	endtry
endfunction


function! s:region(textobj)
	return get(textobj#blockwise#region_from_textobj(a:textobj), 1, [])
" 	return get(textobj#multitextobj#region_from_textobj(a:textobj), 1, [])
endfunction


function! s:as_cursorpos(pos)
	if empty(a:pos)
		return [0, 0, 0, 0]
	endif
	return [0, a:pos[0], a:pos[1], 0]
endfunction


function! s:blockwise(textobj, key)
	let textobj = s:as_config(a:textobj)

	let region = s:region(textobj)
	if empty(region)
		return
	endif
	let [topleft, bottomright] = region
	let pos = getpos(".")
	try
		while !empty(region)
\		   && region[0][1] == topleft[1]
\		   && region[1][1] == bottomright[1]
			let bottomright = region[1]
			execute "normal!" a:key
			let region = s:region(textobj)
			if empty(region) || region[0][0] == bottomright[0]
				break
			endif
		endwhile
	finally
		call cursor(pos[1], pos[2])
	endtry
	return ["\<C-v>", s:as_cursorpos(topleft), s:as_cursorpos(bottomright)]
endfunction


function! s:number_to_alpha(num)
	let alpha = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j']
	return alpha[a:num / 100 % 10] .  alpha[a:num / 10 % 10] . alpha[a:num % 10]
endfunction


let s:mappings = {}
function! textobj#blockwise#mapexpr_i(textobj)
	let key = string(a:textobj)
	if has_key(s:mappings, key)
		return s:mappings[key]
	endif

	let name = s:number_to_alpha(len(s:mappings))
	execute
\"	function! Textobj_blockwise_" . name . "()\n"
\"		return s:blockwise(" . string(a:textobj) . ", 'j')\n"
\"	endfunction"
	call textobj#user#plugin("textobjblockwise" . name, {
\		'-': {
\			'select-i': '',
\			'*select-i-function*': "Textobj_blockwise_" . name,
\		},
\	})
	let s:mappings[key] = "\<Plug>(textobj-textobjblockwise". name . "-i)"
	return s:mappings[key]
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
