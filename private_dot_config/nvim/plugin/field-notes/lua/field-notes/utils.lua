local M = {}

function M.slugify(str)
  local output = str:lower()
  output = output:gsub('%W+', '-')
  output = output:gsub('^-+', '')
  output = output:gsub('-+$', '')
  return output
end

function M.get_git_dir()
  local has_git = vim.fn.system('command -v git')
  if vim.v.shell_error ~= 0 or #has_git == 0 then
    return ''
  end

  local cmd = string.format('git -C %s rev-parse --git-dir', vim.fn.expand('%:p:h'))
  local result = vim.fn.system(cmd)
  result = result:gsub('\n', '')

  if result:sub(1, 6) == 'fatal:' then
    return ''
  end

  return result
end

function M.get_note_title(...)
  local args = {...}
  local title = table.concat(args, ' ')

  if #title == 0 then
    local git_dir = M.get_git_dir()
    local project_name, branch_name

    if #git_dir > 0 then
      local project_path = vim.fn.finddir('.git/..', vim.fn.expand('%:p:h') .. ';')
      local path_parts = vim.split(project_path, '/')
      project_name = path_parts[#path_parts]

      local branch_cmd = string.format('git -C %s branch --show-current --quiet', vim.fn.expand('%:p:h'))
      branch_name = vim.fn.system(branch_cmd):gsub('\n', '')
    else
      local cwd_parts = vim.split(vim.fn.getcwd(), '/')
      project_name = cwd_parts[#cwd_parts - 1]
      branch_name = cwd_parts[#cwd_parts]
    end

    project_name = project_name:gsub('^%+', '')
    branch_name = branch_name:gsub('^%+', '')
    title = project_name .. ': ' .. branch_name
  end

  return title
end

function M.get_note_heading(...)
  local title = M.get_note_title(...)
  return '# ' .. title .. '\n\n'
end

return M
