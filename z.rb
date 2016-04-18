def callback param
  result = "god#{param}"
  yield result
end

callback '1' do |item|
 puts "thanks, #{item}"
end
