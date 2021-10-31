require "rails_helper"

RSpec.describe SearchItemReq do
  #
  # ESCAPE_CHARS
  #

  describe "#escape_chars" do
    it "escapes phrases with quotation marks" do
      query = '"fire in the fireplace"'
      expect(SearchItemReq.escape_chars(query)).to eq "\"fire in the fireplace\""
    end

    it "correctly handles (text:searches) queries" do
      query = "(text:water) OR (annotations_text:Cather)"
      expect(SearchItemReq.escape_chars(query)).to eq "(text:water) OR (annotations_text:Cather)"
    end

    it "does not escape ? character" do
      expect(SearchItemReq.escape_chars("wat?r")).to eq "wat?r"
    end

    it "does not escape * character" do
      expect(SearchItemReq.escape_chars("cat*")).to eq "cat*"
    end

    it "escapes quotation marks" do
      expect(SearchItemReq.escape_chars('"something')).to eq "\"something"
      expect(SearchItemReq.escape_chars('"phrase" plus "other phrase"'))
        .to eq "\"phrase\" plus \"other phrase\"" 
    end

    it "escapes brackets and funky stuff" do
      query = '{\\+~'
      expect(SearchItemReq.escape_chars(query)).to eq "\\{\\\\\\+\\~"
    end
  end

  #
  # FACETS
  #

  describe "#facets" do
    before do
      @facets = SearchItemReq.new(config).facets
    end

    context "no overrides" do
      let(:config) {{ "facet" => [ "title" ] }}
      it "returns defaults" do
        expect(@facets).to match({"title"=>{"terms"=>{"field"=>"title", "order"=>{"_count"=>"desc"}, "size"=>20}}})
      end
    end

    context "some overrides" do
      let(:config) {{
        "facet_num" => 10,
        "facet_sort" => "term|asc",
        "facet" => [ "title", "subcategory" ]
      }}
      it "returns defaults and overridden values" do
        expect(@facets).to match({"title"=>{"terms"=>{"field"=>"title", "order"=>{"_term"=>"asc"}, "size"=>10}}, "subcategory"=>{"terms"=>{"field"=>"subcategory", "order"=>{"_term"=>"asc"}, "size"=>10}}})
      end
    end

    context "no facets provided" do
      let(:config) {{
        "facet_num" => 1,
        "facet_sort" => "nonterm|asc",
        "facet" => []
      }}
      it "is blank" do
        expect(@facets).to eq({})
      end
    end

    context "with dates" do
      let(:config) {{"facet" => ["date.year", "date"]}}
      it "returns date histogram" do
        expect(@facets).to match({"date.year"=>{"date_histogram"=>{"field"=>"date", "interval"=>"year", "format"=>"yyyy", "min_doc_count"=>1, "order"=>{"_count"=>"desc"}}}, "date"=>{"date_histogram"=>{"field"=>"date", "interval"=>"day", "format"=>"yyyy-MM-dd", "min_doc_count"=>1, "order"=>{"_count"=>"desc"}}}})
      end
    end

    context "with nested field" do
      let(:config) {{"facet_sort" => "term|desc", "facet" => [ "creator.name" ]}}
      it "returns nested aggregations" do
        expect(@facets).to match({"creator.name"=>{"nested"=>{"path"=>"creator"}, "aggs"=>{"creator.name"=>{"terms"=>{"field"=>"creator.name", "order"=>{"_term"=>"desc"}, "size"=>20}}}}})
      end
    end

    context "with a single facet" do
      let(:config) {{ "facet" => "title" }}
      it "returns facet field and defaults" do
        expect(@facets).to match({"title"=>{"terms"=>{"field"=>"title", "order"=>{"_count"=>"desc"}, "size"=>20}}})
      end
    end

    context "with term sorting using specified order" do
      let(:config) {{ "facet" => ["title", "format"], "facet_sort" => "term|desc" }}
      it "returns descending order by term" do
        expect(@facets).to match({"title"=>{"terms"=>{"field"=>"title", "order"=>{"_term"=>"desc"}, "size"=>20}}, "format"=>{"terms"=>{"field"=>"format", "order"=>{"_term"=>"desc"}, "size"=>20}}})
      end
    end

    context "with term sorting, no specified order" do
      let(:config) {{ "facet" => ["title", "format"], "facet_sort" => "term" }}
      it "returns descending order by term" do
        expect(@facets).to match({"title"=>{"terms"=>{"field"=>"title", "order"=>{"_term"=>"desc"}, "size"=>20}}, "format"=>{"terms"=>{"field"=>"format", "order"=>{"_term"=>"desc"}, "size"=>20}}})
      end
    end

    context "with sort count but no order" do
      let(:config) {{ "facet" => ["title"], "facet_sort" => "count" }}
      it "returns descending order by count" do
        expect(@facets).to match({"title"=>{"terms"=>{"field"=>"title", "order"=>{"_count"=>"desc"}, "size"=>20}}})
      end
    end
  end

  #
  # FILTERS
  #

  describe "#filters" do
    before do
      @filters = SearchItemReq.new(config).filters
    end

    context "single filter" do
      let(:config) {{ "f" => ["category|Writings"] }}
      it "returns single filter" do
        expect(@filters).to match([{"term"=>{"category"=>"Writings"}}])
      end
    end

    context "multiple filters" do
      let(:config) {{ "f" => ["category|Writings", "author.name|Herriot, James"] }}
      it "returns multiple filters, including nested" do
        expect(@filters).to match([{"term"=>{"category"=>"Writings"}}, {"nested"=>{"path"=>"author", "query"=>{"term"=>{"author.name"=>"Herriot, James"}}}}])
      end
    end

    context "multiple filters, including one with CR present" do
      let(:config) {{ "f" => ["category|Writings", "places_written_k|Jaffrey, New Hampshire, United\r\n                           States"] }}
      it "returns multiple filters with same characters provided" do
        expect(@filters).to match([{"term"=>{"category"=>"Writings"}}, {"term"=>{"places_written_k"=>"Jaffrey, New Hampshire, United\n                           States"}}])
      end
    end

    context "single year" do
      let(:config) {{ "f" => ["date|1900"] }}
      it "returns range from Jan 1 to Dec 31 of year" do
        expect(@filters).to match([{"range"=>{"date"=>{"gte"=>"1900-01-01", "lte"=>"1900-12-31", "format"=>"yyyy-MM-dd"}}}])
      end
    end

    context "double year" do
      let(:config) {{ "f" => ["date|1900|1904"] }}
      it "returns range from Jan 1 of first year to Dec 31 of last year" do
        expect(@filters).to match([{"range"=>{"date"=>{"gte"=>"1900-01-01", "lte"=>"1904-12-31", "format"=>"yyyy-MM-dd"}}}])
      end
    end

    context "double day range" do
      let(:config) {{ "f" => ["date|1904-01-03|1908-12-10"] }}
      it "returns range from and to dates provided" do
        expect(@filters).to match([{"range"=>{"date"=>{"gte"=>"1904-01-03", "lte"=>"1908-12-10", "format"=>"yyyy-MM-dd"}}}])
      end
    end

    context "nested field" do
      let(:config) {{ "f" => ["creator.name|Willa, Cather"] }}
      it "returns nested field" do
        expect(@filters).to match([{"nested"=>{"path"=>"creator", "query"=>{"term"=>{"creator.name"=>"Willa, Cather"}}}}])
      end
    end

    context "multiple filters, including a nested field with CR present" do
      let(:config) {{ "f" => ["category|Writings", "author.name|Herriot,\r\nJames"] }}
      it "returns multiple filters with same characters provided" do
        expect(@filters).to match([{"term"=>{"category"=>"Writings"}}, {"nested"=>{"path"=>"author", "query"=>{"term"=>{"author.name"=>"Herriot,\nJames"}}}}])
      end
    end

    context "dynamic field" do
      let(:config) {{ "f" => ["publication_d|1900"] }}
      it "returns dynamic date field with range for year" do
        expect(@filters).to match([{"range"=>{"publication_d"=>{"gte"=>"1900-01-01", "lte"=>"1900-12-31", "format"=>"yyyy-MM-dd"}}}])
      end
    end

    context "with non-array" do
      let(:config) {{ "f" => "category|Writings" }}
      it "returns single term filter" do
        expect(@filters).to match([{"term"=>{"category"=>"Writings"}}])
      end
    end

    context "where empty" do
      let(:config) {{ "f" => "places|" }}
      it "returns term filter for empty string" do
        expect(@filters).to match(["term"=>{"places"=>""}])
      end
    end
  end

  #
  # HIGHLIGHTS
  #

  describe "#highlights" do
    before do
      @highlights = SearchItemReq.new(config).highlights
    end

    context "no parameters" do
      let(:config) {{}}
      it "returns defaults" do
        expect(@highlights).to match({"fields"=>{"text"=>{"fragment_size"=>100, "number_of_fragments"=>3}}})
      end
    end

    context "specifies fragment size and number" do
      let(:config) {{ "hl_chars" => 20, "hl_num" => 1 }}
      it "returns correct settings" do
        expect(@highlights).to match({"fields"=>{"text"=>{"fragment_size"=>20, "number_of_fragments"=>1}}})
      end
    end

    context "sets highlight field and highlighting false" do
      let(:config) {{ "hl_fl" => "annotations", "hl" => "false" }}
      it "should not return any highlighting" do
        expect(@highlights).to match({})
      end
    end

    context "specifies highlight field list" do
      let(:config) {{ "hl_fl" => "annotations, text" }}
      it "should return default settings for the specified fields" do
        expect(@highlights).to match({"fields"=>{"text"=>{"fragment_size"=>100, "number_of_fragments"=>3}, "annotations"=>{"fragment_size"=>100, "number_of_fragments"=>3}}})
      end
    end

    context "specifies fragment size and numbers for multiple fields" do
      let(:config) {{ "hl_chars" => 20, "hl_num" => 1, "hl_fl" => "annotations,extra" }}
      it "sets the fragment size and number on each field" do
        expect(@highlights).to match({"fields"=>{"text"=>{"fragment_size"=>20, "number_of_fragments"=>1}, "annotations"=>{"fragment_size"=>20, "number_of_fragments"=>1}, "extra"=>{"fragment_size"=>20, "number_of_fragments"=>1}}})
      end
    end
  end

  #
  # SORT
  #

  describe "#sort" do
    before do
      @filters = SearchItemReq.new(config).sort
    end

    context "single sort" do
      let(:config) {{ "sort" => ["title|asc"] }}
      it "returns sort settings plus defaults" do
        expect(@filters).to match([{"title"=>{"order"=>"asc", "mode"=>"min", "missing"=>"_last"}}])
      end
    end

    context "multiple sorts and subfield" do
      let(:config) {{ "sort" => ["title|desc", "author.name|asc"] }}
      it "returns requested sort fields in order with nested sorting" do
        expect(@filters).to match([{"title"=>{"order"=>"desc", "mode"=>"max", "missing"=>"_last"}}, {"author.name"=>{"order"=>"asc", "mode"=>"min", "missing"=>"_last", "nested"=>{"path"=>"author"}}}])
      end
    end

    context "with non-array" do
      let(:config) {{ "sort" => "title|asc" }}
      it "returns requested sort" do
        expect(@filters).to match([{"title"=>{"order"=>"asc", "mode"=>"min", "missing"=>"_last"}}])
      end
    end

    context "no sort specified, query present" do
      let(:config) {{ "q" => "water" }}
      it "returns _score sorting" do
        expect(@filters).to match(["_score"])
      end
    end

    context "no sort direction specified, query present" do
      let(:config) {{ "q" => "water", "sort" => "date" }}
      it "returns field sorted by order ascending" do
        expect(@filters).to match([{"date"=>{"order"=>"asc", "mode"=>"min", "missing"=>"_last"}}])
      end
    end

    context "sort specified, query present" do
      let(:config) {{ "q" => "water", "sort" => "date|desc" }}
      it "returns sort by field order descending" do
        expect(@filters).to match([{"date"=>{"order"=>"desc", "mode"=>"max", "missing"=>"_last"}}])
      end
    end

    context "no sort specified, no query" do
      let(:config) {{}}
      it "returns default sorting by identifier" do
        expect(@filters).to match([{"identifier"=>{"order"=>"asc", "mode"=>"min", "missing"=>"_last"}}])
      end
    end

    context "no sort direction specified, no query" do
      let(:config) {{ "sort" => "title" }}
      it "returns sort by field ascending" do
        expect(@filters).to match([{"title"=>{"order"=>"asc", "mode"=>"min", "missing"=>"_last"}}])
      end
    end
  end

  #
  # TEXT SEARCH
  #

  describe "#text_search" do
    before do
      @search = SearchItemReq.new(config).text_search
    end

    context "no text search" do
      let(:config) {{}}
      it "returns a match all clause" do
        expect(@search).to match({ "match_all" => {}})
      end
    end

    context "simple text query" do
      let(:config) {{ "q" => "water" }}
      it "returns a query string and default text field" do
        expect(@search).to match({"query_string"=>{"default_field"=>"text", "query"=>"water"}})
      end
    end

    context "with boolean" do
      let(:config) {{ "q" => "water AND college" }}
      it "returns boolean in query" do
        expect(@search).to match({"query_string"=>{"default_field"=>"text", "query"=>"water AND college"}})
      end
    end

    context "multiple text fields" do
      let(:config) {{ "q" => "(text:water) AND (annotations:water)" }}
      it "returns query string specifying multiple text fields" do
        expect(@search).to match({"query_string"=>{"query"=>"(text:water) AND (annotations:water)"}})
      end
    end

    context "multiple fields different input" do
      let(:config) {{ "q" => "(text:water) OR (annotations:balcony)" }}
      it "returns different queries for each text field" do
        expect(@search).to match({"query_string"=>{"query"=>"(text:water) OR (annotations:balcony)"}})
      end
    end

    context "multiple fields with grouped inputs" do
      let(:config) {{ "q" => '(text:water OR "fire in the fireplace") OR (annotations:water AND "fire in the fireplace")'}}
      it "returns " do
        expect(@search).to match({"query_string"=>{"query"=>"(text:water OR \"fire in the fireplace\") OR (annotations:water AND \"fire in the fireplace\")"}})
      end
    end

    context "non-text field search" do
      let(:config) {{ "q" => "transcriptions_t:wouldnt" }}
      it "returns query only for the non default text field specified" do
        expect(@search).to match({"query_string"=>{"query"=>"transcriptions_t:wouldnt"}})
      end
    end

    context "text field search with colon making it almost look like a text field search" do
      let(:config) {{ "q" => "yosemite: cool place to visit" }}
      it "returns query with the colon and everything" do
        expect(@search).to match({"query_string"=>{"default_field"=>"text", "query"=>"yosemite: cool place to visit"}})
      end
    end

    context "text field search with single quotation mark" do
      let(:config) {{ "q" => "Exploring the Text: Cather's Hand" }}
      it "returns query string with unescaped single quotation mark" do
        expect(@search).to match({"query_string"=>{"default_field"=>"text", "query"=>"Exploring the Text: Cather's Hand"}})
      end
    end
  end

  #
  # SOURCE
  #

  describe "#source" do
    before do
      @source = SearchItemReq.new(config).source
    end

    context "field list includes only" do
      let(:config) {{ "fl" => "title, creator.name" }}
      it "returns includes list" do
        expect(@source).to match({"includes"=>["title", "creator.name"]})
      end
    end

    context "field list excludes only" do
      let(:config) {{ "fl" => "!title,!creator.name" }}
      it "returns excludes list" do
        expect(@source).to match({"excludes"=>["title", "creator.name"]})
      end
    end

    context "field list both include and exclude fields with wildcards" do
      let(:config) {{ "fl" => "id, title, date, !dat*" }}
      it "returns list with both includes and excludes" do
        expect(@source).to match({"includes"=>["id", "title", "date"], "excludes"=>["dat*"]})
      end
    end
  end
end
