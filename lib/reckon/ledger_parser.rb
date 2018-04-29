#!/usr/bin/env ruby

require 'rubygems'

module Reckon
  class LedgerParser

    attr_accessor :entries

    def initialize(ledger, options = {})
      @entries = []
      parse(ledger)
    end

    def parse(ledger)
      @entries = []
      date = desc = nil
      accounts = []
      ledger.strip.split("\n").each do |entry|
        next if entry =~ /^\s*$/ || entry =~ /^[^ \t\d]/
        if entry =~ /^([\d\/-]+)(\=[\d\/-]+)?(\s+[\*!]?\s*.*?)$/
          @entries << { :date => date.strip, :desc => desc.strip, :accounts => balance(accounts) } if date
          date = $1
          desc = $3
          accounts = []
        elsif date && (m = entry.match(/^\s+(?<account>.+?)(?:\s\s|\t|\s*$)(?<amount_with_unit>[^;]*)(?:; (?<comment>.+)$)?/))
          # regexp inspired by https://github.com/Tagirijus/ledger-parse/blob/master/ledgerparse.py
          if m['amount_with_unit']
            u = m['amount_with_unit'].strip.match(/(?<unit_front>[^\d,.\-+]+)?[\d,.\-+]+(?<unit_back>[^\d,.])?/)
            if u
              unit = u['unit_front'] || u['unit_back']
            end
            amount = m['amount_with_unit'].strip
          end
          accounts << { :name => m['account'].strip, :amount => clean_money(amount) }.tap do |account|
            if unit
              account[:unit] = unit.strip
            end
            if m['comment']
              account[:comment] = m['comment']
            end
          end
        else
          @entries << { :date => date.strip, :desc => desc.strip, :accounts => balance(accounts) } if date
          date = desc = nil
          accounts = []
        end
      end
      @entries << { :date => date.strip, :desc => desc.strip, :accounts => balance(accounts) } if date
    end

    def balance(accounts)
      if accounts.any? { |i| i[:amount].nil? }
        sum = accounts.inject(0) {|m, account| m + (account[:amount] || 0) }
        unit = accounts.collect{|a| a[:unit] }.compact.first
        count = 0
        accounts.each do |account|
          if unit
            account[:unit] ||= unit
          end
          if account[:amount].nil?
            count += 1
            account[:amount] = 0 - sum
          end
        end
        if count > 1
          puts "Warning: unparsable entry due to more than one missing money value."
          p accounts
          puts
        end
      end

      accounts
    end

    def clean_money(money)
      return nil if money.nil? || money.length == 0
      # test wether . or , are used for decimal dividers
      # but only does accept two decimal places
      if money.match(/\,\d\d$/)
        # remove thousands dividers first before replacing the ,
        BigDecimal.new(money.strip.gsub(/\./, '').gsub(/\,/, '.').gsub(/[^0-9.-]/, ''))
      else
        BigDecimal.new(money.strip.gsub(/[^0-9.-]/, ''))
      end
    end
  end
end
