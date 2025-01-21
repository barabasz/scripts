// startAtLevel - highest level to be included in TOC
// tocTitle - 
const startAtLevel = 2
const tocTitle = 'Table of contents'

const content = await dv.io.load(dv.current().file.path)
const toc = content.match(new RegExp(`^#{${startAtLevel},} \\S.*`, 'mg'))
  .map(heading => {
    const [_, level, text] = heading.match(/^(#+) (.+)$/)
    const link = dv.current().file.path + '#' + text
    return '\t'.repeat(level.length - startAtLevel) + `1. [[${link}|${text}]]`
  })
dv.header(2, tocTitle)
dv.paragraph(toc.join('\n'))
