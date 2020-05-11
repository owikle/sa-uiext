
require 'csv'
require 'optparse'

require 'json'


$collection_name_to_index_name = ->(s) { s.downcase.split(" ").join("_") }


def main options
  metadata_table = CSV.parse(File.read(options[:"metadata-path"]), headers: true)

  # Create a search config <fieldName> => <configDict> map.
  field_config_map = {}
  CSV.parse(File.read(options[:"search-config-path"]), headers: true).each do |row|
    field_config_map[row["field"]] = row
  end

  num_items = 0
  output_file = File.open(options[:"output-file"], {mode: "w"})
  metadata_table.each do |item|
    # Remove any fields with an empty value.
    item.delete_if { |k, v| v.nil? }

    # Split each multi-valued field value into a list of values.
    item.each do |k, v|
      if field_config_map.has_key? k and field_config_map[k]["multi-valued"] == "true"
        item[k] = (v or "").split(";").map { |s| s.strip }
      end
    end

    item_text_path = "#{options[:"extracted-text-dir"].chomp("/")}/#{item["filename"]}.text"
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

  puts "Wrote #{num_items} items to: #{options[:"output-file"]}"

end


if __FILE__ == $0
  options = {}
  _parser = nil
  OptionParser.new do |parser|
    parser.banner = "Usage: #{$0} [options]"
    parser.on("--metadata-path METADATA_PATH", "The path to your collection metadata file")
    parser.on("--search-config-path SEARCH_CONFIG_PATH", "The path to your search configuration file")
    parser.on("--extracted-text-dir EXTRACTED_TEXT_DIR", "The path to the directory containing your extracted PDF text files")
    parser.on("--output-file OUTPUT_FILE", "The path of the output file to create")
    _parser = parser
  end.parse!(into: options)

  if options.length != 4
    abort(_parser.help)
  end

  main options
end
