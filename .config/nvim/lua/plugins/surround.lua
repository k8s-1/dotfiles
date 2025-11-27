return {
  "echasnovski/mini.surround",
  name = "mini-surround",
  config = function()
    require('mini.surround').setup({ -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        add = 'sa',                  -- Add surrounding in Normal and Visual modes
        delete = 'sd',               -- Delete surrounding
        find = 'sf',                 -- Find surrounding (to the right)
        find_left = '',            -- Find surrounding (to the left)
        highlight = '',            -- Highlight surrounding
        replace = 'sr',              -- Replace surrounding
        update_n_lines = '',       -- Update `n_lines`

        suffix_last = '',           -- Suffix to search with "prev" method
        suffix_next = '',           -- Suffx to search wth "next" method
      }
    })
  end
}

-- Usage README
-- ADD SURROUNDING - sa
-- sa"iw -> surround word with quotes, brackets etc...
-- v-select > sa[ -> surround paragraph wn brackets 
-- DELETE SURROUNDING - sd (normal mode only)
-- sd" 
-- SURROUND REPLACE " with [, go to char and...
-- sr"[

