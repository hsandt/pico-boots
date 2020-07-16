require("engine/test/bustedhelper")
local codetuner = require("engine/debug/codetuner")

local wtk = require("wtk/pico8wtk")

describe('codetuner', function ()

  describe('position utils', function ()

    -- simulate widget child with position and size via duck-typing
    local mock_widget = {x = 5, y = 6, w = 8, h = 9}

    describe('next_to', function ()

      it('should return a new position on the right of a widget with a default margin of 2', function ()
        assert.are_same({15, 6}, {codetuner.next_to(mock_widget)})
      end)

      it('should return a new position on the right of a widget with the passed margin', function ()
        assert.are_same({17, 6}, {codetuner.next_to(mock_widget, 4)})
      end)

    end)

    describe('below', function ()

      it('should return a new position below a widget with a default margin of 2', function ()
        assert.are_same({5, 17}, {codetuner.below(mock_widget)})
      end)

      it('should return a new position below a widget with the passed margin', function ()
        assert.are_same({5, 19}, {codetuner.below(mock_widget, 4)})
      end)

    end)

  end)

  describe('tuned_variable', function ()

    describe('_init', function ()
      it('should create a new tile vector with the right coordinates', function ()
        local tuned_var = codetuner.tuned_variable("offset", 6)
        assert.are_same({"offset", 6}, {tuned_var.name, tuned_var.default_value})
      end)
    end)

    describe('_tostring', function ()
      it('should return a string representation with the name and default value', function ()
        local tuned_var = codetuner.tuned_variable("offset", 6)
        assert.are_equal("tuned_variable \"offset\" (default: 6)", tuned_var:_tostring())
      end)
    end)

  end)

  describe('init', function ()

    it('should set some default values', function ()
      assert.is_false(codetuner.active)
      assert.are_equal(0, #codetuner.tuned_vars)
      -- we don't test .gui and .main_panel since they are set to nil at first,
      --  then immediately constructed in init_window anyway
    end)

    it('should construct gui and main_panel with init_window', function ()
      -- unfortunately, due to our tricky construct, we cannot spy on the real local function init_window
      --  even if we bind codetuner.init_window = init_window after singleton definition
      --  (codetuner.init_window call count would be 0 as it would be considered a different function)
      -- so we just consider that init_window is inlined and test its content directly
      -- of course we could really inline it, but I prefer keeping it a separate function for now,
      --  as later we may eventually be able to test it separately
      --  (by eitheir not using a singleton anymore, or using lazy init like visual logger)
      assert.is_not_nil(codetuner.gui)
      assert.is_false(codetuner.gui.visible)
      -- don't test gui details, just check that some panel has been added
      assert.are_equal(1, #codetuner.gui.children)
      assert.are_equal(codetuner.main_panel, codetuner.gui.children[1])
    end)

  end)

  describe('(codetuner active)', function ()

    setup(function ()
      stub(_G, "warn")
    end)

    teardown(function ()
      warn:revert()
    end)

    before_each(function ()
      codetuner.active = true  -- needed to create tuned vars
    end)

    after_each(function ()
      codetuner:init()
      warn:clear()
    end)

    describe('get_spinner_callback', function ()

      it('should return a function that sets an existing tuned var', function ()
        tuned("tuned_var", 17)
        local f = codetuner:get_spinner_callback("tuned_var")
        -- simulate spinner via duck-typing
        local fake_spinnner = {value = 11}
        f(fake_spinnner)
        assert.are_equal(11, codetuner.tuned_vars["tuned_var"])
      end)

    end)

    describe('get_or_create_tuned_var', function ()

      setup(function ()
        stub(codetuner, "create_tuned_var", function (self, name, default_value)
          -- get_or_create_tuned_var will only use the tuned var, not widgets,
          --  so we only simulate the creation of the tuned var itself
          self.tuned_vars[name] = default_value
        end)
      end)

      teardown(function ()
        codetuner.create_tuned_var:revert()
      end)

      after_each(function ()
        codetuner.create_tuned_var:clear()
      end)

      it('when name doesn\'t exist it should call create_tuned_var(name, default_value) and return the created var', function ()
        -- local result = tuned("new var", 14)
        local result = codetuner:get_or_create_tuned_var("new var", 14)

        assert.spy(codetuner.create_tuned_var).was_called(1)
        assert.spy(codetuner.create_tuned_var).was_called_with(match.ref(codetuner), "new var", 14)
        assert.are_equal(14, result)
      end)

      it('when name exists it should return the current tuned value', function ()
        -- tuned("tuned_var", 20)
        codetuner.tuned_vars["tuned_var"] = 20

        -- we normally avoid conflicting default values,
        -- but this example is to show we use the actual current value
        local tuned_var_before_set = codetuner:get_or_create_tuned_var("tuned_var", -20)
        codetuner.tuned_vars["tuned_var"] = 170
        local tuned_var_after_set = codetuner:get_or_create_tuned_var("tuned_var", -25)
        assert.are_same({20, 170}, {tuned_var_before_set, tuned_var_after_set})
      end)

    end)

    describe('create_tuned_var', function ()

      it('should set tuned var at name to default value, whether existing or new', function ()
        codetuner:create_tuned_var("tuned var", 14)
        assert.are_equal(14, codetuner.tuned_vars["tuned var"])
      end)

      it('should add corresponding children to the panel', function ()
        codetuner:create_tuned_var("tuned_var1", 1)
        codetuner:create_tuned_var("tuned_var2", 2)
        assert.is_not_nil(codetuner.main_panel)
        assert.are_equal(4, #codetuner.main_panel.children)
        -- don't check details, just check we have labels with correct texts and spinners with correct initial values
        assert.are_equal("tuned_var1", codetuner.main_panel.children[1].text)
        assert.are_equal(1, codetuner.main_panel.children[2].value)
        assert.are_equal("tuned_var2", codetuner.main_panel.children[3].text)
        assert.are_equal(2, codetuner.main_panel.children[4].value)
      end)

    end)

    describe('set_tuned_var', function ()

      it('should set tuned value if it exists', function ()
        tuned("tuned_var", 24)
        codetuner:set_tuned_var("tuned_var", 26)
        assert.are_equal(26, codetuner.tuned_vars["tuned_var"])
      end)

      it('should do nothing if the passed tuned var doesn\'t exist', function ()
        codetuner:set_tuned_var("unknown", 28)
        assert.is_nil(codetuner.tuned_vars["unknown"])
        assert.spy(warn).was_called(1)
        assert.spy(warn).was_called_with(match.matches('codetuner:set_tuned_var: no tuned var found with name: .*'), 'codetuner')
      end)

    end)

  end)

  describe('(codetuner inactive)', function ()

    setup(function ()
      stub(codetuner, "create_tuned_var")
    end)

    teardown(function ()
      codetuner.create_tuned_var:revert()
    end)

    after_each(function ()
      codetuner.create_tuned_var:clear()
    end)

    describe('get_or_create_tuned_var', function ()

      it('should not call create_tuned_var, not return any existing tuned var and return default value', function ()
        -- avoid conflicting default values, but this example is to show we use the passed one
        codetuner.active = false

        local inactive_tuned_var1 = codetuner:get_or_create_tuned_var("tuned_var", 12)
        local inactive_tuned_var2 = codetuner:get_or_create_tuned_var("tuned_var", 18)
        -- if a new default is provided, it is used whatever
        assert.spy(codetuner.create_tuned_var).was_not_called()
        assert.are_same({inactive_tuned_var1, inactive_tuned_var2},
          {12, 18})
      end)

    end)

  end)

  describe('tuned', function ()

    setup(function ()
      stub(codetuner, "get_or_create_tuned_var")
    end)

    teardown(function ()
      codetuner.get_or_create_tuned_var:revert()
    end)

    after_each(function ()
      codetuner.get_or_create_tuned_var:clear()
    end)

    it('should call get_or_create_tuned_var', function ()
      tuned("tuned_var", 12)
      assert.spy(codetuner.get_or_create_tuned_var).was_called(1)
      assert.spy(codetuner.get_or_create_tuned_var).was_called_with(match.ref(codetuner), "tuned_var", 12)
    end)

  end)

  describe('(gui invisible)', function ()

    before_each(function ()
      codetuner.gui.visible = false
    end)

    after_each(function ()
      codetuner.gui.visible = false
    end)

    describe('show', function ()

      it('should make the gui visible', function ()
        codetuner:show()
        assert.is_true(codetuner.gui.visible)
      end)

    end)

    describe('hide', function ()

      it('should make the gui invisible', function ()
        codetuner.gui.visible = true
        codetuner:hide()
        assert.is_false(codetuner.gui.visible)
      end)

    end)

  end)

  describe('codetuner:update_window', function ()

    setup(function ()
      stub(wtk.gui_root, "update")
    end)

    teardown(function ()
      wtk.gui_root.update:revert()
    end)

    it('should call gui:update', function ()
      codetuner:update_window()
      assert.spy( wtk.gui_root.update).was_called()
      assert.spy( wtk.gui_root.update).was_called_with(match.ref(codetuner.gui))
    end)

  end)

  describe('codetuner:render_window', function ()

    setup(function ()
      stub(wtk.gui_root, "draw")
    end)

    teardown(function ()
      wtk.gui_root.draw:revert()
    end)

    it('should call gui:draw', function ()
      codetuner:render_window()
      assert.spy(wtk.gui_root.draw).was_called()
      assert.spy(wtk.gui_root.draw).was_called_with(match.ref(codetuner.gui))
    end)

  end)

end)
