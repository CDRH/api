require "rails_helper"

RSpec.describe SearchItemRes do
  before do
    file = file_fixture("es_response.json").read
    @res = SearchItemRes.new(JSON.parse(file))
  end

  describe "#combine_highlights" do
    it "smushes highlights into an array by field type" do
      hl = @res.combine_highlights.dig(0, "highlight")
      expect(hl).to match({"text" => ["View of the <em>water</em> from S. Lucia street in Naples. Napoli - Strada S. Lucia 35 Ediz Artistica RICTER"], "annotations" => ["This is a fake one that I made up to match <em>water</em> changes to highlighting"]})
    end
  end

  describe "#reformat_facets" do
    it "arranges nested fields and date fields for standard facet response across the board" do
      facet = @res.reformat_facets
      expect(facet).to match({"date.year" => {"1896" => 4, "1920" => 4, "1934" => 4, "1908" => 3, "1938" => 3, "1942" => 3, "1916" => 2, "1929" => 2, "1933" => 2, "1936" => 2, "1941" => 2, "1899" => 1, "1905" => 1, "1909" => 1, "1911" => 1, "1917" => 1, "1918" => 1, "1925" => 1, "1930" => 1, "1931" => 1, "1935" => 1, "1940" => 1, "1944" => 1}, "person.name" => {"Cather, Elsie" => 30, "Cather, Mary Virginia 'Jennie' Boak" => 22, "Cather, Roscoe" => 17, "" => 16, "Lewis, Edith" => 16, "Shannon, Margaret Cather" => 16, "Cather, Charles F." => 11, "Cather, Meta Schaper" => 8, "Gere, Mariel" => 8, "Auld, Jessica Cather" => 7, "Hambourg, Isabelle McClung" => 7, "Cather, Charles Douglass 'Douglass'" => 6, "Greenslet, Ferris" => 6, "Mellen, Mary Virginia Auld" => 6, "Sherwood, Carrie Miner" => 6, "Auld, William Thomas 'Tom, Will'" => 5, "Brockway, Virginia Cather" => 5, "Creighton, Mary Miner" => 5, "Hambourg, Jan" => 5, "Cather, James Donald" => 4}, "format" => {"letter" => 50}})
    end
  end
end
