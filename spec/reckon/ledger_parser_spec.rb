#!/usr/bin/env ruby
#encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'
require 'pp'

describe Reckon::LedgerParser do
  before do
    @ledger = Reckon::LedgerParser.new(EXAMPLE_LEDGER)
  end

  describe "parse" do
    it "should ignore non-standard entries" do
      @ledger.entries.length.should == 7
    end

    it "should parse entries correctly" do
      @ledger.entries.first.should == {
        desc: "* Checking balance",
        date: "2004-05-01",
        accounts: [
          {name: "Assets:Bank:Checking", amount: 1000.0, unit: "$"},
          {name: "Equity:Opening Balances", amount: -1000.0, unit: "$"}
        ]}
      @ledger.entries.last.should == {
        date: "2004/05/27",
        desc: "(100) Credit card company",
        accounts: [
          {name: "Liabilities:MasterCard", amount: 20.24, unit: "$"},
          {name: "Assets:Bank:Checking", amount: -20.24, unit: "$"}
        ]}
    end
  end

  describe "balance" do
    it "it should balance out missing account values" do
      @ledger.balance([
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => nil }
      ]).should == [ { :name => "Account1", :amount => 1000 }, { :name => "Account2", :amount => -1000 } ]
    end

    it "it should balance out missing account values" do
      @ledger.balance([
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => 100 },
          { :name => "Account3", :amount => -200 },
          { :name => "Account4", :amount => nil }
      ]).should == [
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => 100 },
          { :name => "Account3", :amount => -200 },
          { :name => "Account4", :amount => -900 }
      ]
    end

    it "it should work on normal values too" do
      @ledger.balance([
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => -1000 }
      ]).should == [ { :name => "Account1", :amount => 1000 }, { :name => "Account2", :amount => -1000 } ]
    end
  end

  # Data

  EXAMPLE_LEDGER = (<<-LEDGER).strip
= /^Expenses:Books/
  (Liabilities:Taxes)             -0.10

~ Monthly
  Assets:Bank:Checking          $500.00
  Income:Salary

2004-05-01 * Checking balance
  Assets:Bank:Checking        $1,000.00
  Equity:Opening Balances

2004-05-01 * Checking balance
  Assets:Bank:Checking        €1,000.00
  Equity:Opening Balances

2004-05-01 * Checking balance
  Assets:Bank:Checking        1,000.00 SEK
  Equity:Opening Balances

2004/05/01 * Investment balance
  Assets:Brokerage              50 AAPL @ $30.00
  Equity:Opening Balances

; blah
!account blah

!end

D $1,000

2004/05/14 * Pay day
  Assets:Bank:Checking          $500.00
  Income:Salary

2004/05/27 Book Store
  Expenses:Books                 $20.00
  Liabilities:MasterCard
2004/05/27 (100) Credit card company
  Liabilities:MasterCard         $20.24
  Assets:Bank:Checking
  LEDGER
end
