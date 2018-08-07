#!/usr/bin/env ruby

require 'json'

def pick_list
  lists = Dir.glob(File.join(ENV['alfred_workflow_data'], '*'))
  script_filter_items = []

  if lists.empty?
    script_filter_items.push(title: 'You have no lists', subtitle: 'Go add some', valid: false)
  else
    Dir.glob(File.join(ENV['alfred_workflow_data'], '*')).each do |item|
      name = File.basename(item)
      script_filter_items.push(
        title: name, arg: name,
        mods: {
          alt: { variables: { action: 'delete' }, subtitle: 'Remove list', arg: name }
        }
      )
    end
  end

  puts({ items: script_filter_items }.to_json)
end

def new_list(list_text)
  Dir.mkdir(ENV['alfred_workflow_data']) unless Dir.exist?(ENV['alfred_workflow_data'])

  list_items = list_text.split("\n").reject(&:empty?)
  list_title = list_items.shift

  File.write(File.join(ENV['alfred_workflow_data'], list_title), list_items.join("\n") + "\n")
end

def add_to_list(list_name, index, item)
  File.write(
    File.join(ENV['alfred_workflow_data'], list_name),
    File.readlines(File.join(ENV['alfred_workflow_data'], list_name)).insert(index.to_i, item + "\n").join
  )
end

def delete_from_list(list_name, index)
  list_items = File.readlines(File.join(ENV['alfred_workflow_data'], list_name))
  list_items.delete_at(index.to_i)

  File.write(File.join(ENV['alfred_workflow_data'], list_name), list_items.join)
end

def view_list(list_name)
  script_filter_items = []

  File.readlines(File.join(ENV['alfred_workflow_data'], list_name)).each_with_index { |text, index| script_filter_items.push(
    title: text, valid: false,
    mods: {
      alt: { variables: { list_name: list_name,  action: 'delete' }, subtitle: 'Remove item from list', arg: index, valid: true },
      fn: { variables: { list_name: list_name, position: index }, subtitle: 'Add above this item', valid: true },
      ctrl: { variables: { list_name: list_name, position: index + 1 }, subtitle: 'Add below this item', valid: true }
    }
  )}

  puts({ items: script_filter_items }.to_json)
end

def trash_list(list_name)
  system('/usr/bin/osascript', '-l', 'JavaScript', '-e', %Q{Application('Finder').delete(Path("#{File.join(ENV['alfred_workflow_data'], list_name)}"))})
end
