require 'test_helper'

class SearchItemResTest < ActiveSupport::TestCase

  def setup
    this_dir = File.dirname(__FILE__)
    file = File.read("#{this_dir}/../fixtures/es_response.json")
    @es = JSON.parse(file)
  end

  def test_combine_highlights
    hl = SearchItemRes.new(@es).combine_highlights
    first = hl.dig(0, "highlight")
    assert_equal first, {"text"=>[" hardly know how we are going to raise the rest to pay off 10th of May pay roll— and no <em>water</em> to", " Sulphur creek3 George things are being done there badly or the <em>water</em> would be in Sulphur Creek now. The", " to let me know but they have not— I have about given up all hope of <em>water</em> ever getting to Sulphur"]}
  end

  def test_reformat_facets
    facets = SearchItemRes.new(@es).reformat_facets
    assert_equal facets, {"date.year"=>{"1896"=>21, "1899"=>9, "1900"=>9, "1890"=>7, "1898"=>4, "1891"=>3, "1895"=>2, "1897"=>2, "1892"=>1, "1894"=>1}, "format"=>{"letter"=>59}, "creator.name"=>{"Cody, William Frederick, 1846-1917"=>41, "Holdrege, George Ward, 1847-1926"=>2, "Helen Cody Wetmore"=>1, "Manderson, Charles F. (Charles Frederick), 1837-1911"=>1, "Morrill, Charles H., 1842 - 1928"=>1, "Wharton, Anne H."=>1}}
  end

end
