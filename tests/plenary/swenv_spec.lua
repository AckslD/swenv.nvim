describe("swenv", function()
  it("pick venv", function()
    local chosen_venv = {name = 'foo', path = '~/venvs/foo'}
    require('swenv').setup({
      venvs_path = 'venvs_path',
      get_venvs = function(venvs_path)
        assert.are.equal(venvs_path, 'venvs_path')
        return {
          chosen_venv,
        }
      end,
      post_set_venv = function(venv)
        assert.are.same(venv, chosen_venv)
      end,
    })
    vim.ui.select = function(choices, opts, callback)
      assert.are.same(choices[1], chosen_venv)
      callback(choices[1])
    end
    require('swenv.api').pick_venv()
    assert.are.equal(vim.fn.getenv('VIRTUAL_ENV'), chosen_venv.path)
    assert.are.equal(vim.split(vim.fn.getenv('PATH'), ':')[1], chosen_venv.path..'/bin')
    assert.are.same(require('swenv.api').get_current_venv(), chosen_venv)
  end)
end)
