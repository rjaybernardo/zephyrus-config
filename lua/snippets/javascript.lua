-- ==========================================================================
-- CUSTOM JS / TS / REACT SNIPPETS
-- ==========================================================================
-- Bodies use LSP snippet syntax (expanded natively by vim.snippet):
--   $1, $2   tabstops       ${1:text}   tabstop with placeholder
--   $0       final cursor   repeating $1 mirrors the same text

return {
	af = { desc = "Arrow function", body = "(${1:args}) => {\n  $0\n}" },
	caf = { desc = "Const arrow function", body = "const ${1:fnName} = (${2:args}) => {\n  $0\n};" },
	afc = {
		desc = "Async arrow function with try/catch",
		body = "const ${1:fnName} = async (${2:args}) => {\n  try {\n    $0\n  } catch (error) {\n    console.error(error);\n  }\n};",
	},

	ef = { desc = "Export function", body = "export function ${1:functionName}(${2:args}) {\n  $0\n}" },
	eaf = { desc = "Export const arrow function", body = "export const ${1:functionName} = (${2:args}) => {\n  $0\n};" },
	ec = { desc = "Export const", body = "export const ${1:name} = ${2:value};$0" },
	edf = { desc = "Export default function", body = "export default function ${1:functionName}(${2:args}) {\n  $0\n}" },

	clg = { desc = "console.log labelled", body = 'console.log("${1:variable}", $1);$0' },
	cle = { desc = "console.error labelled", body = 'console.error("${1:variable}", $1);$0' },

	us = { desc = "useState", body = "const [${1:state}, set${2:State}] = useState(${3:null});$0" },
	ue = { desc = "useEffect", body = "useEffect(() => {\n  $1\n}, [$2]);$0" },
	ur = { desc = "useRef", body = "const ${1:refName} = useRef(${2:null});$0" },

	rafce = {
		desc = "React arrow function component",
		body = "const ${1:ComponentName} = () => {\n  return (\n    <div>\n      $0\n    </div>\n  );\n};\n\nexport default $1;",
	},
}
