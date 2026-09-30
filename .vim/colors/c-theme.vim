" Variables

let s:comments = 242

let s:literals = 140
let s:special = 103

let s:identifiers = 252
let s:control_flow = 111
let s:preprocessor = 109
let s:types = 146
let s:status = 245

let s:error = 203

" Comments

execute 'highlight Comment        ctermfg=' . s:comments
execute 'highlight SpecialComment ctermfg=' . s:comments


" Literals

execute 'highlight Constant  ctermfg=' . s:literals
execute 'highlight String    ctermfg=' . s:literals
execute 'highlight Character ctermfg=' . s:literals
execute 'highlight Number    ctermfg=' . s:literals
execute 'highlight Boolean   ctermfg=' . s:literals
execute 'highlight Float     ctermfg=' . s:literals


" Identifiers / Functions

execute 'highlight Identifier ctermfg=' . s:identifiers
execute 'highlight Function   ctermfg=' . s:identifiers


" Control flow

execute 'highlight Statement   ctermfg=' . s:control_flow
execute 'highlight Conditional ctermfg=' . s:control_flow
execute 'highlight Repeat      ctermfg=' . s:control_flow
execute 'highlight Label       ctermfg=' . s:control_flow
execute 'highlight Operator    ctermfg=' . s:control_flow
execute 'highlight Keyword     ctermfg=' . s:control_flow
execute 'highlight Exception   ctermfg=' . s:control_flow


" Preprocessor

execute 'highlight PreProc   ctermfg=' . s:preprocessor
execute 'highlight Include   ctermfg=' . s:preprocessor
execute 'highlight Define    ctermfg=' . s:preprocessor
execute 'highlight Macro     ctermfg=' . s:preprocessor
execute 'highlight PreCondit ctermfg=' . s:preprocessor


" Types

execute 'highlight Type         ctermfg=' . s:types
execute 'highlight StorageClass ctermfg=' . s:types
execute 'highlight Structure    ctermfg=' . s:types
execute 'highlight Typedef      ctermfg=' . s:types


" Special

execute 'highlight Special       ctermfg=' . s:special
execute 'highlight SpecialChar   ctermfg=' . s:special
execute 'highlight Tag           ctermfg=' . s:special
execute 'highlight Delimiter     ctermfg=' . s:special
execute 'highlight Debug         ctermfg=' . s:special
execute 'highlight Underlined    ctermfg=' . s:special


" Status

execute 'highlight Ignore ctermfg=' . s:status
execute 'highlight Error  ctermfg=' . s:error
execute 'highlight Todo   ctermfg=' . s:status
