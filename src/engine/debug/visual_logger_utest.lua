require("engine/test/bustedhelper")
local vlogger = require("engine/debug/visual_logger")

require("engine/core/datastruct")
local logging = require("engine/debug/logging")
local wtk = require("wtk/pico8wtk")

describe('vlogger', function ()

  local log_msg = logging.log_msg
  local logger = logging.logger
  local window = vlogger.window

  describe('window (with buffer size 3)', function ()

    after_each(function ()
      window:init()
    end)

    describe('init', function ()

      it('should create a vertical layout to put the messages in', function ()
        assert.are_equal(1, #window.gui.children)
        assert.are_equal(wtk.vertical_layout, getmetatable(window.gui.children[1]))
      end)

    end)

    describe('initialize_msg_queue', function ()

      it('should initialize a message queue as a circular_buffer of max length 3', function ()
        window:initialize_msg_queue(3)

        assert.are_equal(circular_buffer(3), window._msg_queue)
      end)

      it('should initialize a message queue as a circular_buffer of default max length: 5 if not passed', function ()
        window:initialize_msg_queue()

        assert.are_equal(circular_buffer(5), window._msg_queue)
      end)

    end)

    describe('show', function ()

      setup(function ()
        stub(window, "initialize_msg_queue")
        stub(debug_window, "show")
      end)

      teardown(function ()
        window.initialize_msg_queue:revert()
        debug_window.show:revert()
      end)

      after_each(function ()
        window.initialize_msg_queue:clear()
        debug_window.show:clear()
      end)

      describe('(not initialized yet)', function ()

        it('should initialize message queue with passed buffer size', function ()
          window:show(3)

          local s = assert.spy(window.initialize_msg_queue)
          s.was_called(1)
          s.was_called_with(match.ref(window), 3)
        end)

      end)

      describe('(already initialized)', function ()

        before_each(function ()
          -- fake initialization
          window._initialized_msg_queue = true
        end)

        it('should not fill stats', function ()
          window:show()

          local s = assert.spy(window.initialize_msg_queue)
          s.was_not_called()
        end)

      end)

      it('should call base show', function ()
        window:show()

        local s = assert.spy(debug_window.show)
        s.was_called(1)
        s.was_called_with(match.ref(window))
      end)

    end)

    describe('push_msg', function ()

      local msg_queue

      setup(function ()
        spy.on(circular_buffer, "push")
        spy.on(window, "_on_msg_pushed")
        spy.on(window, "_on_msg_popped")
      end)

      teardown(function ()
        circular_buffer.push:revert()
        window._on_msg_pushed:revert()
        window._on_msg_popped:revert()
      end)

      before_each(function ()
        window:initialize_msg_queue()
      end)

      after_each(function ()
        circular_buffer.push:clear()
        window._on_msg_pushed:clear()
        window._on_msg_popped:clear()
      end)

      describe('(when queue is empty)', function ()

        it('should push a message to queue and vertical layout', function ()
          local lm = log_msg(logging.level.info, "flow", "enter stage state")
          window:push_msg(lm)
          assert.spy(window._msg_queue.push).was_called(1)
          assert.spy(window._msg_queue.push).was_called_with(match.ref(window._msg_queue), lm)
          assert.spy(window._on_msg_pushed).was_called(1)
          assert.spy(window._on_msg_pushed).was_called_with(match.ref(window), lm)
          assert.spy(window._on_msg_popped).was_not_called()
        end)

      end)

      describe('(when queue has 2 entries (not full))', function ()

        before_each(function ()
          window:push_msg(log_msg(logging.level.info, "flow", "enter stage state"))
          window:push_msg(log_msg(logging.level.warning, "player", "player character spawner"))
          window._msg_queue.push:clear()
          window._on_msg_pushed:clear()
          window._on_msg_popped:clear()
        end)

        it('should push a message to queue and vertical layout', function ()
          local lm = log_msg(logging.level.warning, "default", "danger")
          window:push_msg(lm)

          assert.spy(window._msg_queue.push).was_called(1)
          assert.spy(window._msg_queue.push).was_called_with(match.ref(window._msg_queue), lm)
          assert.spy(window._on_msg_pushed).was_called(1)
          assert.spy(window._on_msg_pushed).was_called_with(match.ref(window), lm)
          assert.spy(window._on_msg_popped).was_not_called()
        end)

      end)

      describe('(when queue has 3 entries (full))', function ()

        before_each(function ()
          for i = 1, window._msg_queue.max_length do
            window:push_msg(log_msg(logging.level.info, "flow", "enter stage state"))
          end
          window._msg_queue.push:clear()
          window._on_msg_pushed:clear()
          window._on_msg_popped:clear()
        end)

        it('should push a message to queue and vertical layout, detect overwriting and pop the oldest label', function ()
          local lm = log_msg(logging.level.warning, "default", "danger")
          window:push_msg(lm)

          assert.spy(window._msg_queue.push).was_called(1)
          assert.spy(window._msg_queue.push).was_called_with(match.ref(window._msg_queue), lm)
          assert.spy(window._on_msg_pushed).was_called(1)
          assert.spy(window._on_msg_pushed).was_called_with(match.ref(window), lm)
          assert.spy(window._on_msg_popped).was_called(1)
          assert.spy(window._on_msg_popped).was_called_with(match.ref(window))
        end)

      end)

    end)

    describe('_on_msg_pushed', function ()

      local add_child_stub = stub(window.v_layout, "add_child")

      setup(function ()
        add_child_stub = stub(window.v_layout, "add_child")
      end)

      teardown(function ()
        add_child_stub:revert()
      end)

      it('should call add_child with a white label({msg})', function ()
        window:_on_msg_pushed(log_msg(logging.level.info, "flow", "enter stage state"))

        local log_label = wtk.label.new("enter stage state", colors.white)
        assert.spy(add_child_stub).was_called(1)
        assert.spy(add_child_stub).was_called_with(match.ref(window.v_layout), log_label)
      end)

    end)

    describe('_on_msg_popped', function ()

      local remove_child_stub

      setup(function ()
        -- add a message to avoid assertion in _on_msg_popped
        window:_on_msg_pushed(log_msg(logging.level.info, "flow", "enter stage state"))

        remove_child_stub = stub(window.v_layout, "remove_child")
      end)

      teardown(function ()
        remove_child_stub:revert()
      end)

      it('should call remove_child on the first child', function ()
        window:_on_msg_popped()
        assert.spy(remove_child_stub).was_called(1)
        assert.spy(remove_child_stub).was_called_with(match.ref(window.v_layout), window.v_layout.children[1])
      end)

    end)

  end)

  describe('vlog_stream', function ()

    local push_msg_stub

    setup(function ()
      push_msg_stub = stub(window, "push_msg")
    end)

    teardown(function ()
      push_msg_stub:revert()
    end)

    it('should call window.push_msg', function ()
      local lm = log_msg(logging.level.info, "flow", "enter stage state")
      vlogger.vlog_stream:on_log(lm)
      assert.spy(push_msg_stub).was_called(1)
      assert.spy(push_msg_stub).was_called_with(match.ref(window), lm)
    end)

  end)

end)
