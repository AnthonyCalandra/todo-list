TodoListView = require './todo-list-view'

module.exports =
  todoListView: null

  activate: (state) ->
    @todoListView = new TodoListView(state.todoListViewState)

  deactivate: ->
    @todoListView.destroy()

  serialize: ->
    todoListViewState: @todoListView.serialize()
