# Author:: Mike Evans <mike@urlgonomics.com>
# Copyright:: 2013 Urlgonomics LLC.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.join(File.dirname(__FILE__), 'setup')

class TestView < MiniTest::Test

  def setup
    @mock = start_mock
    @path = '_design/users/_view/by_age'
    @cb = Couchbase.new(:hostname => @mock.host, :port => @mock.port)
    @cb.save_design_doc(design_doc)
    { bob: 32, frank: 25, sam: 42, fred: 21 }.each_pair do |name, age|
      @cb.set(name, { type: 'user', name: name, age: age })
    end
    @view = Couchbase::View.new(@cb, @path)
  end

  def teardown
    stop_mock(@mock)
    @cb.disconnect
  end

  def test_initialize
    assert_equal 'users',  @view.design_doc
    assert_equal 'by_age', @view.name
  end

  def test_simple_fetch
    assert results = @view.fetch
    assert results.is_a?(Couchbase::View::ArrayWithTotalRows)
  end

  def test_fetch_without_stale
    assert results = @view.fetch(stale: false)
    assert results.first.is_a?(Couchbase::ViewRow)
    assert results.first.doc.nil?
    assert_equal 4, results.total_rows
    results.each do |result|
      %w(bob frank sam fred).include?(result.key)
    end
  end

  def test_fetch_with_docs
    assert results = @view.fetch(stale: false, include_docs: true)
    assert results.is_a?(Array)
    assert results.first.doc.is_a?(Hash)
  end

  def test_fetch_with_block
    refute @view.fetch(stale: false, include_docs: true) { |row|
      assert row.is_a?(Couchbase::ViewRow)
      assert row.doc['name'].is_a?(String)
      assert row.doc['age'].is_a?(Fixnum)
    }
  end

  def test_design_doc_access
    assert results = @cb.design_docs['users'].by_age.to_a
    assert results.first.is_a?(Couchbase::ViewRow)
  end

  def design_doc
    {
      '_id'      => '_design/users',
      'language' => 'javascript',
      'views' => {
        'by_age' => {
          'map' => <<-JS
            function (doc, meta) {
              if (doc.type && doc.type == 'user')
                emit(meta.id, doc.age);
            }
          JS
        }
      }
    }
  end

end
