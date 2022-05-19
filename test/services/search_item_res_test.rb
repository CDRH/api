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
    assert_equal(
      {"text"=>["View of the <em>water</em> from S. Lucia street in Naples. Napoli - Strada S. Lucia 35 Ediz Artistica RICTER"], "annotations"=>["This is a fake one that I made up to match <em>water</em> changes to highlighting"]},
      first
    )
  end

  def test_reformat_facets
    facets = SearchItemRes.new(@es).reformat_facets
    assert_equal(
{"date.year"=>{"1896"=>{"num"=>4, "source"=>"1896"}, "1920"=>{"num"=>4, "source"=>"1920"}, "1934"=>{"num"=>4, "source"=>"1934"}, "1908"=>{"num"=>3, "source"=>"1908"}, "1938"=>{"num"=>3, "source"=>"1938"}, "1942"=>{"num"=>3, "source"=>"1942"}, "1916"=>{"num"=>2, "source"=>"1916"}, "1929"=>{"num"=>2, "source"=>"1929"}, "1933"=>{"num"=>2, "source"=>"1933"}, "1936"=>{"num"=>2, "source"=>"1936"}, "1941"=>{"num"=>2, "source"=>"1941"}, "1899"=>{"num"=>1, "source"=>"1899"}, "1905"=>{"num"=>1, "source"=>"1905"}, "1909"=>{"num"=>1, "source"=>"1909"}, "1911"=>{"num"=>1, "source"=>"1911"}, "1917"=>{"num"=>1, "source"=>"1917"}, "1918"=>{"num"=>1, "source"=>"1918"}, "1925"=>{"num"=>1, "source"=>"1925"}, "1930"=>{"num"=>1, "source"=>"1930"}, "1931"=>{"num"=>1, "source"=>"1931"}, "1935"=>{"num"=>1, "source"=>"1935"}, "1940"=>{"num"=>1, "source"=>"1940"}, "1944"=>{"num"=>1, "source"=>"1944"}}, "person.name"=>{"Cather, Elsie"=>{"num"=>30, "source"=>"Cather, Elsie"}, "Cather, Mary Virginia 'Jennie' Boak"=>{"num"=>22, "source"=>"Cather, Mary Virginia 'Jennie' Boak"}, "Cather, Roscoe"=>{"num"=>17, "source"=>"Cather, Roscoe"}, ""=>{"num"=>16, "source"=>""}, "Lewis, Edith"=>{"num"=>16, "source"=>"Lewis, Edith"}, "Shannon, Margaret Cather"=>{"num"=>16, "source"=>"Shannon, Margaret Cather"}, "Cather, Charles F."=>{"num"=>11, "source"=>"Cather, Charles F."}, "Cather, Meta Schaper"=>{"num"=>8, "source"=>"Cather, Meta Schaper"}, "Gere, Mariel"=>{"num"=>8, "source"=>"Gere, Mariel"}, "Auld, Jessica Cather"=>{"num"=>7, "source"=>"Auld, Jessica Cather"}, "Hambourg, Isabelle McClung"=>{"num"=>7, "source"=>"Hambourg, Isabelle McClung"}, "Cather, Charles Douglass 'Douglass'"=>{"num"=>6, "source"=>"Cather, Charles Douglass 'Douglass'"}, "Greenslet, Ferris"=>{"num"=>6, "source"=>"Greenslet, Ferris"}, "Mellen, Mary Virginia Auld"=>{"num"=>6, "source"=>"Mellen, Mary Virginia Auld"}, "Sherwood, Carrie Miner"=>{"num"=>6, "source"=>"Sherwood, Carrie Miner"}, "Auld, William Thomas 'Tom, Will'"=>{"num"=>5, "source"=>"Auld, William Thomas 'Tom, Will'"}, "Brockway, Virginia Cather"=>{"num"=>5, "source"=>"Brockway, Virginia Cather"}, "Creighton, Mary Miner"=>{"num"=>5, "source"=>"Creighton, Mary Miner"}, "Hambourg, Jan"=>{"num"=>5, "source"=>"Hambourg, Jan"}, "Cather, James Donald"=>{"num"=>4, "source"=>"Cather, James Donald"}}, "format"=>{"letter"=>{"num"=>50, "source"=>"letter"}}},      facets
    )
  end

end
