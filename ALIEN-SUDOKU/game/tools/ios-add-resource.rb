# Adds a file (e.g. GoogleService-Info.plist) to the iOS app's bundle resources.
# Used by codemagic.yaml when Firebase is set up; run on a Mac with the xcodeproj gem.
#   ruby tools/ios-add-resource.rb ios/App/App.xcodeproj App/GoogleService-Info.plist
require 'xcodeproj'

project_path, file_path = ARGV
abort 'usage: ruby ios-add-resource.rb <App.xcodeproj> <path relative to ios/App>' unless project_path && file_path

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'App' } or abort 'App target not found'
group = project.main_group.find_subpath(File.dirname(file_path), false) || project.main_group
name = File.basename(file_path)
ref = group.files.find { |f| f.path == name } || group.new_reference(name)
unless target.resources_build_phase.files_references.include?(ref)
  target.resources_build_phase.add_file_reference(ref, true)
end
project.save
puts "Added #{name} to the App target's resources"
