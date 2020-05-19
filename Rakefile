
require 'csv'
require 'json'
require 'optparse'
require 'yaml'


###############################################################################
# Helper Functions
###############################################################################

$collection_name_to_index_name = ->(s) { s.downcase.split(" ").join("_") }

def load_config
  # Read the config file and validate and return the values required by rake tasks.
  config = YAML.load_file('_config.yml')

  # Read and (if necessary) create the scratch_path.
  scratch_path = config['scratch-dir']
  if !scratch_path
    raise "scratch-dir must be defined in _config.yml"
  end
  # Trim any trailing slash.
  scratch_path = scratch_path.chomp('/')
  # Maybe create the directory.
  if !File.exists? scratch_path
    Dir.mkdir scratch_path
  end

  # Read the metadata_path.
  metadata = config['metadata']
  if !metadata
    raise "metadata must be defined in _config.yml"
  end
  metadata_path = File.join(['_data', "#{metadata}.csv"])

  # Read the objects path.
  objects_path = config['digital-objects']
  if !objects_path
    raise "digital-objects must be defined in _config.yml"
  end
  # Strip out any leading baseurl value.
  if objects_path.start_with? config['baseurl']
    objects_path = objects_path[config['baseurl'].length..-1]
    # Trim any leading slash from the objects directory
    if objects_path.start_with? '/'
      objects_path = objects_path[1..-1]
    end
  end
  # Strip any trailing slash.
  objects_path = objects_path.chomp('/')

  return {
    :objects_path => objects_path,
    :scratch_path => scratch_path,
    :metadata_path => metadata_path
  }
end


###############################################################################
# TASK: deploy
###############################################################################

desc "Build site with production env"
task :deploy do
  ENV["JEKYLL_ENV"] = "production"
  sh "jekyll build"
end


###############################################################################
# TASK: generate_derivatives
###############################################################################

desc "Generate derivative image files from collection objects"
task :generate_derivatives, [:thumbs_size, :small_size, :density, :missing] do |t, args|
  args.with_defaults(
    :thumbs_size => "300x300",
    :small_size => "800x800",
    :density => "300",
    :missing => "true"
  )

  config = load_config
  objects_path = config[:objects_path]

  # Ensure that the derivatives subdirectories exist within the objects_path.
  thumbs_path = File.join([objects_path, 'thumbs'])
  small_path = File.join([objects_path, 'small'])
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
  Dir.glob(File.join([objects_path, '*'])).each do |filename|
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


###############################################################################
# extract_pdf_text
###############################################################################

desc "Extract the text from PDF collection objects"
task :extract_pdf_text do

  config = load_config
  output_path = File.join([config[:scratch_path], "extracted_pdf_text"])

  # Create the output directory if necessary.
  if !File.exists? output_path
    Dir.mkdir output_path
  end

  # Extract the text.
  Dir.glob(File.join([config[:objects_path], "*.pdf"])).each do |filename|
    output_filename = File.join([output_path, "#{File.basename filename}.text"])
    system("pdftotext -enc UTF-8 -eol unix -nopgbrk #{filename} #{output_filename}")
    puts "Wrote #{output_filename}"
  end
end


###############################################################################
# generate_es_bulk_data
###############################################################################

desc "Generate the file that we'll use to populate the Elasticsearch index via the Bulk API"
task :generate_es_bulk_data do

  config = load_config

  metadata_table = CSV.parse(File.read(config[:metadata_path]), headers: true)

  # Create a search config <fieldName> => <configDict> map.
  field_config_map = {}
  CSV.parse(File.read(File.join(['_data', 'config-search.csv'])), headers: true).each do |row|
    field_config_map[row["field"]] = row
  end

  extracted_pdf_text_path = File.join([config[:scratch_path], 'extracted_pdf_text']).chomp("/")
  output_path = File.join([config[:scratch_path], "es_bulk_data.json"])
  output_file = File.open(output_path, {mode: "w"})
  num_items = 0
  metadata_table.each do |item|
    # Remove any fields with an empty value.
    item.delete_if { |k, v| v.nil? }

    # Split each multi-valued field value into a list of values.
    item.each do |k, v|
      if field_config_map.has_key? k and field_config_map[k]["multi-valued"] == "true"
        item[k] = (v or "").split(";").map { |s| s.strip }
      end
    end

    item_text_path = File.join([extracted_pdf_text_path, "#{item["filename"]}.text"])
    if File::exists? item_text_path
      full_text = File.read(item_text_path, {mode: "r", encoding: "utf-8"})
      item["full_text"] = full_text
    end

    # Write the action_and_meta_data line.
    doc_id = item["objectid"]
    index_name = $collection_name_to_index_name.call(item["digital_collection"])
    output_file.write("{\"index\": {\"_index\": \"#{index_name}\", \"_id\": \"#{doc_id}\"}}\n")

    # Write the source line.
    output_file.write("#{JSON.dump(item.to_hash)}\n")

    num_items += 1
  end

  puts "Wrote #{num_items} items to: #{output_path}"
end
