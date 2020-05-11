"""
Generate a file that comprises the Mapping settings for the Elasticsearch index
from the configuration specified in _data/config.search.yml

https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html
"""

require 'optparse'
require 'csv'
require 'json'


TEXT_FIELD_DEF_KEYS = [ 'field' ]
BOOL_FIELD_DEF_KEYS = [ 'index', 'display', 'facet', 'multi-valued' ]
VALID_FIELD_DEF_KEYS = TEXT_FIELD_DEF_KEYS.dup.concat BOOL_FIELD_DEF_KEYS


INDEX_SETTINGS_TEMPLATE = {
  mappings: {
    dynamic_templates: [
      {
        store_as_unindexed_text: {
          match_mapping_type: "*",
          mapping: {
            type: "text",
            index: false
          }
        }
      }
    ],
    properties: {
      # Always include objectid.
      objectid: {
        type: "text",
        index: false
      }
    }
  }
}


def assert_field_def_is_valid field_def
  """Assert that the field definition is valid.
  """
  keys = field_def.to_hash.keys

  missing_keys = VALID_FIELD_DEF_KEYS.reject { |k| keys.include? k }
  extra_keys = keys.reject { |k| VALID_FIELD_DEF_KEYS.include? k }
  if !missing_keys.empty? or !extra_keys.empty?
    msg = "The field definition: #{field_def}"
    if !missing_keys.empty?
      msg = "#{msg}\nis missing the required keys: #{missing_keys}"
    end
    if !extra_keys.empty?
      msg = "#{msg}\nincludes the unexpected keys: #{extra_keys}"
    end
    raise msg
  end

  invalid_bool_value_keys = BOOL_FIELD_DEF_KEYS.reject { |k| ["true", "false"].include? field_def[k] }
  if !invalid_bool_value_keys.empty?
    raise "Expected true/false value for: #{invalid_bool_value_keys.join(", ")}"
  end

  if field_def["index"] == "false" and
    (field_def["facet"] == "true" or field_def['multi-valued'] == "true")
    raise "Field (#{field_def["field"]}) has index=false but other index-related "\
          "fields (e.g. facet, multi-valued) specified as true"
  end

  if field_def['multi-valued'] == "true" and field_def['facet'] != "true"
    raise "If field (#{field_def["field"]}) specifies multi-valued=true, it "\
          "also needs to specify facet=true"
  end
end


def convert_field_def_bools field_def
  """Do an in-place conversion of the bool strings to python bool values.
  """
  BOOL_FIELD_DEF_KEYS.each do |k|
    field_def[k] = field_def[k] == "true"
  end
end


def get_mapping field_def
  """Return an ES mapping configuration object for the specified field
  definition.
  """
  mapping = {
    type: "text"
  }
  if field_def["facet"]
    mapping["fields"] = {
      raw: {
        type: "keyword"
      }
    }
  end
  return mapping
end


def main options
  search_config_csv = CSV.parse(File.read(options[:"search-config-path"]), headers: true)

  index_settings = INDEX_SETTINGS_TEMPLATE.dup
  search_config_csv.each do |field_def|
    assert_field_def_is_valid(field_def)
    convert_field_def_bools(field_def)
    if field_def["index"]
      index_settings[:mappings][:properties][field_def["field"]] = get_mapping(field_def)
    end
  end

  output_file = File.open(options[:"output-file"], {mode: "w"})
  output_file.write(JSON.pretty_generate(index_settings))
  puts "Wrote: #{options[:"output-file"]}"
end


if __FILE__ == $0
  options = {}
  _parser = nil
  OptionParser.new do |parser|
    parser.banner = "Usage: #{$0} [options]"
    parser.on("--search-config-path SEARCH_CONFIG_PATH", "The path to your search configuration file")
    parser.on("--output-file OUTPUT_FILE", "The path of the output file to create")
    _parser = parser
  end.parse!(into: options)

  if options.length != 2
    abort(_parser.help)
  end

  main options
end
