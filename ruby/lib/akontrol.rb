
%w[message controller device].each do |lib|
  require File.dirname(__FILE__) + '/akontrol/' + lib
end
