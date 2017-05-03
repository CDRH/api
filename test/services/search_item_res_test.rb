require 'test_helper'

class SearchItemResTest < ActiveSupport::TestCase

  def setup
    # test json generated with
    # items?facet[]=person.name&facet[]=format&facet[]=date.year&debug=true&q=water
    this_dir = File.dirname(__FILE__)
    file = File.read("#{this_dir}/../fixtures/es_response.json")
    @es = JSON.parse(file)
  end

  def test_combine_highlights
    hl = SearchItemRes.new(@es).combine_highlights
    first = hl.dig(0, "highlight")
    assert_equal first, {"text"=>["View of the <em>water</em> from S. Lucia street in Naples. Napoli - Strada S. Lucia 35 Ediz Artistica RICTER"]}
  end

  def test_reformat_facets
    facets = SearchItemRes.new(@es).reformat_facets
    assert_equal facets, {"date.year"=>{"1896"=>4, "1920"=>4, "1934"=>4, "1908"=>3, "1938"=>3, "1942"=>3, "1916"=>2, "1929"=>2, "1933"=>2, "1936"=>2, "1941"=>2, "1899"=>1, "1905"=>1, "1909"=>1, "1911"=>1, "1917"=>1, "1918"=>1, "1925"=>1, "1930"=>1, "1931"=>1, "1935"=>1, "1940"=>1, "1944"=>1}, "person.name"=>{"Cather, Elsie"=>30, "Cather, Mary Virginia 'Jennie' Boak"=>22, "Cather, Roscoe"=>17, ""=>16, "Lewis, Edith"=>16, "Shannon, Margaret Cather"=>16, "Cather, Charles F."=>11, "Cather, Meta Schaper"=>8, "Gere, Mariel"=>8, "Auld, Jessica Cather"=>7, "Hambourg, Isabelle McClung"=>7, "Cather, Charles Douglass 'Douglass'"=>6, "Greenslet, Ferris"=>6, "Mellen, Mary Virginia Auld"=>6, "Sherwood, Carrie Miner"=>6, "Auld, William Thomas 'Tom, Will'"=>5, "Brockway, Virginia Cather"=>5, "Creighton, Mary Miner"=>5, "Hambourg, Jan"=>5, "Cather, James Donald"=>4}, "format"=>{"letter"=>50}}
  end

end
