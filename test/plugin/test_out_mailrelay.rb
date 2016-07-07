# -*- coding: utf-8 -*-
require 'helper'

class DummyChain
  def next
  end
end

class MailRelayOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  TMP_DIR = File.dirname(__FILE__) + "/../tmp"
  DATA_DIR = File.dirname(__FILE__) + "/../data"

  CONFIG = %[
    myips ["127.0.0.1", "172.22.16.0/24"]
  ]

  def create_driver(conf = CONFIG, tag='test')
    driver = Fluent::Test::BufferedOutputTestDriver.new(Fluent::MailRelayOutput, tag)
    driver.configure(conf)
    driver
  end

  def test_configure
    #### set configurations
    # d = create_driver %[
    #   path test_path
    #   compress gz
    # ]
    #### check configurations
    # assert_equal 'test_path', d.instance.path
    # assert_equal :gz, d.instance.compress
  end

  def test_format
    driver = create_driver

    # time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    # d.emit({"a"=>1}, time)
    # d.emit({"a"=>2}, time)

    # d.expect_format %[2011-01-02T13:14:15Z\ttest\t{"a":1}\n]
    # d.expect_format %[2011-01-02T13:14:15Z\ttest\t{"a":2}\n]

    # d.run
  end

  def test_1
    data_file = "#{DATA_DIR}/data1"
    expect_file = "#{DATA_DIR}/data1_expect"
    driver = create_driver
    do_test(driver, data_file, expect_file)
  end

  def do_test(driver, data_file, expect_file)
    buffer = driver.instance.instance_eval{ @buffer }
    assert buffer
    driver.instance.start

    chain = DummyChain.new
    tag = driver.instance.instance_eval{ @tag }

    # result_expect
    expects = []
    File.open(expect_file, "r") {|expectfile|
      expectfile.each_line {|line|
        expects.push(JSON.parse(line))
      }
    }

    driver.run do
      File.open(data_file, "r") {|datafile|
        datafile.each_line {|line|
          time, tag, record = line.split(/\t/)
          time = Time.parse(time).to_i
          buffer.emit(tag, driver.instance.format(tag, time, JSON.parse(record)), chain)
          # driver.emit(JSON.parse(record), time)
        }
      }
    end

    driver.instance.instance_eval{ @next_flush_time = Time.now.to_i - 30 }
    driver.instance.try_flush

    emits = driver.emits
    emits.each_index {|i|
      assert_equal(expects[i], emits[i][2])
    }
  end
end
