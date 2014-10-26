{$, ScrollView} = require 'atom'

module.exports =
class TodoListView extends ScrollView
  @content: ->
    @div class: 'todo-list-panel tool-panel', 'data-show-on-right-side': atom.config.get('todo-list.showOnRightSide'), =>
      @div class: 'todo-list-scroller', outlet: 'scroller', =>
        @ol class: 'todo-list full-menu list-tree focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'todo-list-resize-handle', outlet: 'resizeHandle'

  initialize: (serializeState) ->
    atom.workspaceView.command 'todo-list:toggle', => @toggle()
    atom.workspaceView.command 'todo-list:toggle-side', => @toggleSide()
    @on 'mousedown', '.todo-list-resize-handle', (e) => @resizeStarted(e)
    @on 'core:close core:cancel', => @detach()
    @subscribe atom.config.observe 'todo-list.showOnRightSide', callNow: false, (newValue) =>
      @detach()
      @attach()
      @element.dataset.showOnRightSide = newValue

    editor = atom.workspace.getActiveTextEditor()
    if editor isnt ''
      editor.onDidChange =>
        # Clear previous list first!
        @list[0].innerHTML = ''
        @createReminderList()

  createReminderList: ->
    numTodo = 0
    numFixme = 0
    todoList = []
    fixmeList = []

    editor = atom.workspace.getActiveTextEditor()
    if editor isnt ''
      editor.scan /todo:\s*(.*)/gi, (match) =>
        return if match.match[1] is ''
        numTodo++
        todoList.push {
          text: match.match[1],
          line: match.range.start.row + 1,
          point: [match.range.start.row, match.range.start.column]
        }

    todoHead = document.createElement('li')
    todoHead.className = if numTodo > 0 then 'head incomplete' else 'head complete'
    todoHead.innerHTML = "TODO (#{ numTodo })"
    @list.append(todoHead)

    if numTodo > 0
      for todo in todoList
        todoElement = document.createElement('li')
        todoElement.innerHTML = @createReminderElement(todo.text, todo.line)
        do (todo) ->
          todoElement.addEventListener 'dblclick', =>
            editor.setCursorBufferPosition(todo.point)
        @list.append(todoElement)

    if editor isnt ''
      editor.scan /fixme:\s*(.*)/gi, (match) =>
        return if match.match[1] is ''
        numFixme++
        fixmeList.push {
          text: match.match[1],
          line: match.range.start.row + 1,
          point: [match.range.start.row, match.range.start.column]
        }

    fixmeHead = document.createElement('li')
    fixmeHead.className = if numFixme > 0 then 'head incomplete' else 'head complete'
    fixmeHead.innerHTML = "FIXME (#{ numFixme })"
    @list.append(fixmeHead)

    if numFixme > 0
      for fixme in fixmeList
        fixmeElement = document.createElement('li')
        fixmeElement.innerHTML = @createReminderElement(fixme.text, fixme.line)
        do (fixme) ->
          fixmeElement.addEventListener 'dblclick', =>
            editor.setCursorBufferPosition(fixme.point)
        @list.append(fixmeElement)

  createReminderElement: (text, line) ->
    text = @shortenReminderMsg(text)
    "<span class=\"msg\">#{ text }</span><hr /><span>on line #{ line }</span>"

  shortenReminderMsg: (text, maxLength = 30) ->
    if text.length >= maxLength
      return text.substring(0, maxLength - 2) + '...'
    else
      return text

  resizeStarted: =>
    $(document).on('mousemove', @resizeTodoList)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeTodoList)
    $(document).off('mouseup', @resizeStopped)

  resizeTodoList: ({pageX, which}) =>
    return @resizeStopped() unless which is 1
    if atom.config.get('todo-list.showOnRightSide')
      width = $(document.body).width() - pageX
    else
      width = pageX

    @width(width)

  toggleSide: ->
    atom.config.toggle('todo-list.showOnRightSide')

  detach: ->
    # Clear list for next time.
    @list[0].innerHTML = ''
    super

  # Returns an object that can be retrieved when package is activated.
  serialize: ->

  # Tear down any state and detach.
  destroy: ->
    @detach()

  attach: ->
    @createReminderList()
    if atom.config.get('todo-list.showOnRightSide')
      @element.classList.remove('panel-left')
      @element.classList.add('panel-right')
      atom.workspaceView.appendToRight(this)
    else
      @element.classList.remove('panel-right')
      @element.classList.add('panel-left')
      atom.workspaceView.appendToLeft(this)

  toggle: ->
    if @hasParent()
      @detach()
    else
      @attach()
