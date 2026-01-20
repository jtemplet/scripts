# frozen_string_literal: true

# Sorts Tailwind CSS classes in HAML files according to Tailwind's official order
# Based on https://github.com/tailwindlabs/prettier-plugin-tailwindcss
class HamlTailwindSorter
  # Official Tailwind class order - matches prettier-plugin-tailwindcss
  # Lower numbers come first in the sorted output
  CLASS_ORDER = {
    # 1. Position, Inset, Isolation, Z-index
    "static" => 10, "fixed" => 10, "absolute" => 10, "relative" => 10, "sticky" => 10,
    "inset" => 10, "top" => 10, "right" => 10, "bottom" => 10, "left" => 10, "start" => 10, "end" => 10,
    "isolate" => 10, "isolation" => 10, "z" => 10,

    # 2. Visibility
    "visible" => 12, "invisible" => 12, "collapse" => 12,

    # 3. Layout - Container, Display, Box Sizing
    "container" => 15,
    "box-border" => 15, "box-content" => 15,
    "block" => 15, "inline-block" => 15, "inline" => 15, "flex" => 15, "inline-flex" => 15,
    "table" => 15, "inline-table" => 15, "table-caption" => 15, "table-cell" => 15,
    "table-column" => 15, "table-row" => 15, "flow-root" => 15, "grid" => 15, "inline-grid" => 15,
    "contents" => 15, "list-item" => 15, "hidden" => 15,

    # 4. Floats, Clear, Object Fit/Position
    "float" => 18, "clear" => 18, "object" => 18,

    # 5. Overflow
    "overflow" => 20, "overscroll" => 20,

    # 6. Flexbox & Grid - Direction, Wrap, Flow
    "basis" => 25, "flex-row" => 25, "flex-col" => 25, "flex-wrap" => 25, "flex-nowrap" => 25,
    "flex-1" => 25, "flex-auto" => 25, "flex-initial" => 25, "flex-none" => 25,
    "shrink" => 25, "grow" => 25,
    "grid-cols" => 25, "grid-rows" => 25, "grid-flow" => 25,
    "auto-cols" => 25, "auto-rows" => 25,
    "col" => 25, "row" => 25,

    # 7. Justify, Align, Place
    "justify-start" => 30, "justify-end" => 30, "justify-center" => 30, "justify-between" => 30,
    "justify-around" => 30, "justify-evenly" => 30, "justify-stretch" => 30, "justify-normal" => 30,
    "justify-items" => 30, "justify-self" => 30,
    "items-start" => 30, "items-end" => 30, "items-center" => 30, "items-baseline" => 30,
    "items-stretch" => 30, "content" => 30, "self" => 30, "place" => 30,

    # 8. Gap, Space
    "gap" => 35, "space" => 35,

    # 9. Order
    "order" => 40,

    # 10. Padding, Margin
    "p" => 45, "px" => 45, "py" => 45, "ps" => 45, "pe" => 45, "pt" => 45, "pr" => 45, "pb" => 45, "pl" => 45,
    "m" => 45, "mx" => 45, "my" => 45, "ms" => 45, "me" => 45, "mt" => 45, "mr" => 45, "mb" => 45, "ml" => 45,

    # 11. Width, Height, Size
    "w" => 50, "min-w" => 50, "max-w" => 50, "h" => 50, "min-h" => 50, "max-h" => 50, "size" => 50,

    # 12. Typography - Font Family, Size, Weight, Variant
    "font" => 60, "text" => 60, "antialiased" => 60, "subpixel-antialiased" => 60,
    "italic" => 60, "not-italic" => 60, "normal-nums" => 60, "ordinal" => 60,
    "slashed-zero" => 60, "lining-nums" => 60, "oldstyle-nums" => 60,
    "proportional-nums" => 60, "tabular-nums" => 60, "diagonal-fractions" => 60, "stacked-fractions" => 60,

    # 13. Leading, Tracking, Line Clamp
    "leading" => 65, "tracking" => 65, "line-clamp" => 65,

    # 14. Text Alignment, Decoration, Transform, Overflow, Whitespace, Break
    "align" => 70, "underline" => 70, "overline" => 70, "line-through" => 70, "no-underline" => 70,
    "decoration" => 70, "underline-offset" => 70,
    "uppercase" => 70, "lowercase" => 70, "capitalize" => 70, "normal-case" => 70,
    "truncate" => 70, "text-ellipsis" => 70, "text-clip" => 70,
    "whitespace" => 70, "break" => 70, "hyphens" => 70,

    # 15. Text Indent, Vertical Align, List Style
    "indent" => 75, "vertical" => 75, "list" => 75,

    # 16. Columns
    "columns" => 80,

    # 17. Background - Attachment, Clip, Origin, Position, Repeat, Size
    "bg" => 85, "from" => 85, "via" => 85, "to" => 85,

    # 18. Border - Width, Color, Style, Radius, Divide
    "border" => 90, "divide" => 90, "outline" => 90, "ring" => 90, "rounded" => 90,

    # 19. Effects - Shadow, Opacity, Mix Blend, Background Blend
    "shadow" => 95, "opacity" => 95, "mix" => 95, "bg-blend" => 95,

    # 20. Filters, Backdrop
    "blur" => 100, "brightness" => 100, "contrast" => 100, "drop-shadow" => 100,
    "grayscale" => 100, "hue-rotate" => 100, "invert" => 100, "saturate" => 100, "sepia" => 100,
    "backdrop" => 100, "filter" => 100,

    # 21. Tables - Layout, Caption
    "table-auto" => 105, "table-fixed" => 105, "caption" => 105, "border-collapse" => 105, "border-separate" => 105,

    # 22. Transitions & Animation
    "transition" => 110, "duration" => 110, "ease" => 110, "delay" => 110, "animate" => 110,

    # 23. Transforms - Scale, Rotate, Translate, Skew, Transform Origin
    "scale" => 115, "rotate" => 115, "translate" => 115, "skew" => 115, "transform" => 115, "origin" => 115,

    # 24. Interactivity - Accent, Appearance, Cursor, Caret, Pointer Events, Resize, Scroll, Select, Will Change
    "accent" => 120, "appearance" => 120, "cursor" => 120, "caret" => 120,
    "pointer-events" => 120, "resize" => 120, "scroll" => 120, "snap" => 120,
    "touch" => 120, "select" => 120, "will-change" => 120, "user-select" => 120,

    # 25. SVG - Fill, Stroke
    "fill" => 125, "stroke" => 125,

    # 26. Accessibility - Screen Readers
    "sr-only" => 130, "not-sr-only" => 130,

    # 27. Forced Color Adjust
    "forced-color-adjust" => 135
  }.freeze

  def self.sort_file(file_path)
    content = File.read(file_path)
    sorted_content = sort_content(content)

    if content != sorted_content
      File.write(file_path, sorted_content)
      puts "✓ Sorted: #{file_path}"
      true
    else
      false
    end
  end

  def self.sort_content(content)
    content.gsub(/^(\s*)\.([a-z0-9\-.]+)/i) do |match|
      indent = ::Regexp.last_match(1)
      classes_string = ::Regexp.last_match(2)
      classes = classes_string.split(".")
      sorted_classes = sort_classes(classes)
      "#{indent}.#{sorted_classes.join(".")}"
    end
  end

  def self.sort_classes(classes)
    classes.sort_by { |cls| [class_priority(cls), cls] }
  end

  def self.class_priority(class_name)
    # Check for exact matches first
    return CLASS_ORDER[class_name] if CLASS_ORDER.key?(class_name)

    # Check for prefix matches (e.g., "gap-4" matches "gap")
    CLASS_ORDER.each do |prefix, priority|
      return priority if class_name.start_with?("#{prefix}-")
    end

    # Default to high number to put unknown classes at the end
    999
  end
end

if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby lib/haml_tailwind_sorter.rb <file1.haml> [file2.haml ...]"
    puts "Example: ruby lib/haml_tailwind_sorter.rb app/views/documentation/deals/index.html.haml"
    exit 1
  end

  sorted_count = 0
  ARGV.each do |file_path|
    if File.exist?(file_path)
      sorted_count += 1 if HamlTailwindSorter.sort_file(file_path)
    else
      puts "✗ File not found: #{file_path}"
    end
  end

  puts "\nProcessed #{ARGV.length} file(s), #{sorted_count} modified"
end
