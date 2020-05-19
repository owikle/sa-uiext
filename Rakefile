
require 'yaml'


desc "Build site with production env"
task :deploy do
  ENV["JEKYLL_ENV"] = "production"
  sh "jekyll build"
end

desc "Generate derivative image files from collection objects"
task :generate_derivatives, [:thumbs_size, :small_size, :density, :missing] do |t, args|
  args.with_defaults(
    :thumbs_size => "300x300",
    :small_size => "800x800",
    :density => "300",
    :missing => "true"
  )

  config = YAML.load_file('_config.yml')

  # Read the objects path from the config and strip out any leading baseurl value.
  objects_path = config['digital-objects']
  if objects_path.start_with? config['baseurl']
    objects_path = objects_path[config['baseurl'].length..-1]
    # Trim any leading slash from the objects directory
    if objects_path.start_with? '/'
      objects_path = objects_path[1..-1]
    end
  end

  # Trim any trailing slash from the objects directory
  if objects_path.end_with? '/'
    objects_path = objects_path[0..-2]
  end

  # Ensure that the derivatives subdirectories exist within the objects_path.
  thumbs_path = "#{objects_path}/thumbs"
  small_path = "#{objects_path}/small"
  [thumbs_path, small_path].each do |dir|
    if !Dir.exists?(dir)
      Dir.mkdir(dir)
      puts "Created #{dir}"
    end
  end

  EXTNAME_TYPE_MAP = {
    '.jpg' => :image,
    '.pdf' => :pdf
  }

  # Generate derivatives.
  Dir.glob("#{objects_path}/*").each do |filename|
    # Ignore subdirectories.
    if File.directory? filename
      next
    end

    # Determine the file type and skip if unsupported.
    extname = File.extname(filename).downcase
    file_type = EXTNAME_TYPE_MAP[extname]
    if !file_type
      puts "Skipping file with unsupported extension: #{extname}"
      next
    end

    # Define the file-type-specific magick command prefix.
    magick_cmd =
      case file_type
      when :image then "magick #{filename}"
      when :pdf then "magick -density #{args.density} #{filename}[0]"
      end

    # Get the lowercase filename without any leading path and extension.
    base_filename = File.basename(filename)[0..-(extname.length + 1)].downcase

    # Generate the thumb image.
    thumb_filename=File.join([thumbs_path, "#{base_filename}_th.jpg"])
    if args.missing == 'false' or !File.exists?(thumb_filename)
      puts "Creating: #{thumb_filename}";
      system("#{magick_cmd} -resize #{args.thumbs_size} -flatten #{thumb_filename}")
    end

    # Generate the small image.
    small_filename = File.join([small_path, "#{base_filename}_sm.jpg"])
    if args.missing == 'false' or !File.exists?(small_filename)
      puts "Creating: #{small_filename}";
      system("#{magick_cmd} -resize #{args.small_size} -flatten #{small_filename}")
    end
  end
end
