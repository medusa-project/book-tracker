require 'test_helper'

class BookStoreTest < ActiveSupport::TestCase

  setup do
    @store = BookStore.instance
    setup_s3
  end

  teardown do
    teardown_s3
  end

  # bucket_exists?()

  test "bucket_exists?() works" do
    assert @store.bucket_exists?
    @store.delete_bucket(bucket: BookStore::BUCKET)
    assert !@store.bucket_exists?
  end

  # delete_objects()

  test "delete_objects() works" do
    filename = "sample.xml"
    File.open(file_fixture(filename), "r") do |file|
      @store.put_object(bucket: BookStore::BUCKET,
                        key:    filename,
                        body:   file)
    end

    assert @store.object_exists?(key: filename)

    @store.delete_objects

    assert !@store.object_exists?(key: filename)
  end

  # object_exists?()

  test "object_exists?() works" do
    filename = "sample.xml"
    File.open(file_fixture(filename), "r") do |file|
      @store.put_object(bucket: BookStore::BUCKET,
                        key:    filename,
                        body:   file)
    end

    assert @store.object_exists?(key: filename)
  end


end
