#!/usr/bin/env ruby
require "yaml"
require "date"

# Regex to grab YAML frontmatter block at the top
FRONTMATTER_RE = /\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m
FIND_TOKEN = "created_at"
REPLACE_TOKEN = "created"

Dir.glob("**/*.md").each do |file|
  puts "Reading #{file}"
  content = File.read(file, encoding: "UTF-8")

  # Strip UTF-8 BOM if present
  content.sub!(/\A\xEF\xBB\xBF/, "")

  m = content.match(FRONTMATTER_RE)
  unless m
    #puts "No frontmatter in #{file}"
    next
  end

  fm_text = m[1]                    # the captured YAML block
  body = content.sub(FRONTMATTER_RE, "")  # file without frontmatter

  # Parse YAML, allowing Date/Time so 2025-06-30 works
  data = YAML.safe_load(fm_text, permitted_classes: [Date, Time], aliases: true) || {}
  unless data.is_a?(Hash)
    puts "Frontmatter in #{file} is not a mapping; skipping"
    next
  end

  unless data.key?(FIND_TOKEN)
    #puts "No change in #{file}"
    next
  end

  puts "Updating #{file}…"
  data[REPLACE_TOKEN] = data.delete(FIND_TOKEN)

  # Dump YAML back without Psych's leading '---'
  yaml_out = YAML.dump(data)
  yaml_out.sub!(/\A---[^\n]*\n/, "")
  yaml_out = yaml_out.rstrip + "\n"

  new_content = +"---\n#{yaml_out}---\n#{body}"

  # Write back to file (make a .bak backup first if you like)
  #File.binwrite(file, new_content)
  File.write(file + ".bak", content, mode: "w", encoding: "UTF-8")
  File.write(file, new_content, mode: "w", encoding: "UTF-8")

  puts "Updated #{file}"
end
