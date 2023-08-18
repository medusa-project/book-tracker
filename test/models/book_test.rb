require 'test_helper'

class BookTest < ActiveSupport::TestCase

  test 'bulk_update works' do
    b1 = books(:one)
    b2 = books(:two)
    b3 = books(:three)
    assert !b1.exists_in_google and !b2.exists_in_google and !b3.exists_in_google

    batch = [b1.obj_id, b2.obj_id]
    Book.bulk_update(batch, 'exists_in_google', 'true', 'obj_id')
    b1.reload
    b2.reload
    b3.reload
    assert b1.exists_in_google and b2.exists_in_google
    assert !b3.exists_in_google
  end

  test 'bulk_upsert works' do
    Book.destroy_all
    rows = [
        {
            author: 'Dr. Seuss',
            bib_id: 123,
            date: '1974',
            exists_in_hathitrust: false,
            exists_in_internet_archive: false,
            exists_in_google: false,
            hathitrust_access: nil,
            ia_identifier: nil,
            hathitrust_rights: nil,
            language: 'English',
            obj_id: 123,
            oclc_number: 123,
            raw_marcxml: nil,
            source_path: '/dev/null',
            subject: nil,
            title: 'Green Eggs and Ham',
            volume: nil
        },
        {
            author: 'Dr. Seuss',
            bib_id: 234,
            date: '1975',
            exists_in_hathitrust: false,
            exists_in_internet_archive: false,
            exists_in_google: false,
            hathitrust_access: nil,
            ia_identifier: nil,
            hathitrust_rights: nil,
            language: 'English',
            obj_id: 234,
            oclc_number: 234,
            raw_marcxml: nil,
            source_path: '/dev/null',
            subject: nil,
            title: 'The Lorax',
            volume: nil
        },
        { # same obj_id as the first one
            author: 'Dr. Seuss',
            bib_id: 123,
            date: '1975',
            exists_in_hathitrust: false,
            exists_in_internet_archive: false,
            exists_in_google: false,
            hathitrust_access: nil,
            ia_identifier: nil,
            hathitrust_rights: nil,
            language: 'English',
            obj_id: 123,
            oclc_number: 123,
            raw_marcxml: nil,
            source_path: '/dev/null',
            subject: nil,
            title: 'The Lorax',
            volume: nil
        }
    ]
    Book.bulk_upsert(rows)
    assert_equal 2, Book.count
    assert_not_nil Book.find_by_obj_id(123)
    assert_not_nil Book.find_by_obj_id(234)
  end

  test 'internet_archive_url returns correct url based on IA identifier' do
    b1 = books(:one) #fixture data
    assert_equal "https://archive.org/details/#{b1.ia_identifier}", b1.internet_archive_url

  end

  test 'hathitrust_handle works only if book exists in hathitrust' do 
    b1 = books(:one)
    b4 = books(:four)

    assert !b1.exists_in_hathitrust
    assert_equal "", b1.hathitrust_handle

    assert b4.exists_in_hathitrust
    assert_equal "https://hdl.handle.net/2027/uiuc.#{b4.obj_id}", b4.hathitrust_handle
  end

  test 'service returns which type of record the book is from' do 
    skip()
  end

  test 'uiuc_catalog_url returns the bib_id with prefix 99 and suffix 12205899' do 
    b1 = books(:one)
    bibid = b1.bib_id.to_s
    base_url = 'https://i-share-uiu.primo.exlibrisgroup.com/permalink/01CARLI_UIU/gpjosq/alma'
    prefix   = '99'
    suffix   = '12205899'

    assert bibid.present?
    assert_equal "#{base_url}" + '99' + "#{bibid}" + '12205899', b1.uiuc_catalog_url
  end
end
