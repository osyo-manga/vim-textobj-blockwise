scriptencoding utf-8
if exists('g:loaded_textobj_blockwise')
  finish
endif
let g:loaded_textobj_blockwise = 1

let s:save_cpo = &cpo
set cpo&vim


let g:textobj_blockwise_enable_default_key_mapping = get(g:, "textobj_blockwise_enable_default_key_mapping", 1)

if g:textobj_blockwise_enable_default_key_mapping
	function! s:mapping(lhs, rhs, mode)
		if mapcheck(a:lhs, a:mode) == ""
			execute a:mode . "map <expr> " . a:lhs . " textobj#blockwise#mapexpr(" . string(a:rhs) . ")"
		endif
	endfunction

	function! s:v_mapping(lhs, rhs)
		if mapcheck(a:lhs, "v") == ""
			execute "vmap <expr> " . a:lhs . " textobj#blockwise#C_v_mapexpr(" . string(a:rhs) . ")"
		endif
	endfunction

	function! s:map(key)
		call s:mapping("I" . a:key, "i" . a:key, "o")
		call s:mapping("A" . a:key, "a" . a:key, "o")
" 		call s:v_mapping("I" . a:key, "i" . a:key)
" 		call s:v_mapping("A" . a:key, "a" . a:key)
		call s:v_mapping("i" . a:key, "i" . a:key)
		call s:v_mapping("a" . a:key, "a" . a:key)
	endfunction
	let s:textobjs = ['w', 'W', 's', 'p', 'b', 'B', 't', '<', '>', '[', ']', '(', ')', '{', '}', '"', "'", '`']
	call map(s:textobjs, "s:map(v:val)")
endif



let &cpo = s:save_cpo
unlet s:save_cpo
