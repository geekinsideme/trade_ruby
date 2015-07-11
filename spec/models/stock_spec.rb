require 'bundler'
Bundler.require
require_relative "../../models/stock.rb"

describe Stock do
  describe 'オペレーション' do
    before do
      @stock = Stock.new open: 5000,high: 6000,low: 4000,close: 5500
    end
    describe '買いオペレーション' do
      context '成り行き' do
        it '寄り付き' do
          expect(Stock.buy(nil,nil,@stock)).to eq [5000,"market/open"]
        end
      end
      context '指値が安値以下の時' do
        it '約定せず' do
          expect(Stock.buy(3000,nil,@stock)).to eq [nil,nil]
        end
      end
      context '指値が安値〜寄り付きの時' do
        it '指値' do
          expect(Stock.buy(4500,nil,@stock)).to eq [4500,"limit/limit"]
        end
      end
      context '指値が寄り付き〜高値の時' do
        it '寄り付き' do
          expect(Stock.buy(5500,nil,@stock)).to eq [5000,"limit/open"]
        end
      end
      context '指値が高値以上の時' do
        it '寄り付き' do
          expect(Stock.buy(7000,nil,@stock)).to eq [5000,"limit/open"]
        end
      end
      context '逆指値が安値以下の時' do
        it '高値' do
          expect(Stock.buy(nil,3000,@stock)).to eq [6000,"stop/high"]
        end
      end
      context '逆指値が安値〜寄り付きの時' do
        it '高値' do
          expect(Stock.buy(nil,4500,@stock)).to eq [6000,"stop/high"]
        end
      end
      context '逆指値が寄り付き〜高値の時' do
        it '高値' do
          expect(Stock.buy(nil,5500,@stock)).to eq [6000,"stop/high"]
        end
      end
      context '逆指値が高値以上の時' do
        it '約定せず' do
          expect(Stock.buy(nil,7000,@stock)).to eq [nil,nil]
        end
      end
    end
    describe '売りオペレーション' do
      context '成り行き' do
        it '寄り付き' do
          expect(Stock.sell(nil,nil,@stock)).to eq [5000,"market/open"]
        end
      end
      context '指値が安値以下の時' do
        it '寄り付き' do
          expect(Stock.sell(3000,nil,@stock)).to eq [5000,"limit/open"]
        end
      end
      context '指値が安値〜寄り付きの時' do
        it '寄り付き' do
          expect(Stock.sell(4500,nil,@stock)).to eq [5000,"limit/open"]
        end
      end
      context '指値が寄り付き〜高値の時' do
        it '指値' do
          expect(Stock.sell(5500,nil,@stock)).to eq [5500,"limit/limit"]
        end
      end
      context '指値が高値以上の時' do
        it '約定せず' do
          expect(Stock.sell(7000,nil,@stock)).to eq [nil,nil]
        end
      end
      context '逆指値が安値以下の時' do
        it '約定せず' do
          expect(Stock.sell(nil,3000,@stock)).to eq [nil,nil]
        end
      end
      context '逆指値が安値〜寄り付きの時' do
        it '安値' do
          expect(Stock.sell(nil,4500,@stock)).to eq [4000,"stop/low"]
        end
      end
      context '逆指値が寄り付き〜高値の時' do
        it '安値' do
          expect(Stock.sell(nil,5500,@stock)).to eq [4000,"stop/low"]
        end
      end
      context '逆指値が高値以上の時' do
        it '安値' do
          expect(Stock.sell(nil,7000,@stock)).to eq [4000,"stop/low"]
        end
      end
    end
  end
end
