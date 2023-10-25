require 'test_helper'

class TempStoreTest < ActiveSupport::TestCase

  setup do
    @store = TempStore.instance
    setup_s3
  end

  teardown do
    teardown_s3
  end

  # bucket_exists?()

  test "bucket_exists?() works" do
    assert @store.bucket_exists?
    @store.delete_bucket(bucket: TempStore::BUCKET)
    assert !@store.bucket_exists?
  end

  # delete_objects()

  test "delete_objects() works" do
    filename = "sample.xml"
    File.open(file_fixture(filename), "r") do |file|
      @store.put_object(bucket: TempStore::BUCKET,
                        key:    filename,
                        body:   file)
    end

    assert @store.object_exists?(key: filename)

    @store.delete_objects

    assert !@store.object_exists?(key: filename)
  end

  # object_exists?()

  test "object_exists?() works" do
    bucket   = ::Configuration.instance.storage.dig(:temp, :bucket)
    filename = "sample.xml"

    File.open(file_fixture(filename), "r") do |file|
      @store.put_object(bucket: bucket,
                        key:    filename,
                        body:   file)
    end

    assert @store.object_exists?(key: filename)
  end


end
