# = HtmlTable
#
# Builds an HTML table out of a simple (although limited) array
#
# This module allows you to build a simple HTML table, and to set the
# most common HTML classes (for the whole table, the heading row, and
# even/odd rows). 
class HtmlTable < Array
  class InvalidClass < Exception #:nodoc:
  end
  DefaultClasses = { 
    :table => 'table',
    :head => 'table-head',
    :even => 'table-even',
    :odd => 'table-odd'
  }

  # Initializes a new #HtmlTable object. If any parameters are
  # received, they are made into the table's rows - Note that they
  # should all be #Array containing printable elements.
  #
  # A HtmlTable object is a regular array, and each of its elements
  # must also be an array:
  #
  #   t = HtmlTable.new([1,2,3], [2,3,4], [4,5,6])
  def initialize(*rows)
    @classes = DefaultClasses
    @empty_msg = nil
    @head = nil
    @processed_rows = 0

    super()
    rows.each {|r| self << r}
  end

  # Sets the HTML class for a given element. The allowed elements are
  # +table+ (for the whole table), +head+ (for the heading row),
  # +even+ (for even rows) and +odd+ (for odd rows). 
  #
  # We will only generate the HTML table with the classes indicated -
  # you should define them in your CSS to be visible. A sample CSS
  # definition can be:
  #
  #     .table { border-collapse: collapse; margin 0.5em; }
  #     .table-head { background: #fff7e2; }
  #     .table-even { background: #ccc5b0; }
  #     .table-odd { background: #eee6d1; }
  def set_class_for(name, value)
    raise InvalidClass, "You can only redefine the following classes: %s" % 
      @classes.keys.join(', ') unless @classes.keys.include?(name.to_sym)
    @classes[name.to_sym] = value
  end

  # HtmlTable will not render an empty table. If you want an empty
  # HtmlTable to display a message (i.e. "No data to display"), you
  # can set it through this method:
  #
  #     t = HtmlTable.new
  #     puts t.to_s
  #     =>  nil
  #
  #     t.set_empty_msg "No data to display"
  #     puts t.to_s
  #
  #     =>  "No data to display"
  def set_empty_msg(msg)
    @empty_msg = msg
  end

  # Defines a heading row. This row is not counted as part of the
  # table's rows (this means, if no actual data rows are defined, this
  # row will not be printed either - see #set_empty_msg). This row's
  # elements will be enclosed in HTML table heading (th) elements
  # instead of table data (td), and the whole row will be set with the
  # defined +table-head+ class (see #set_class_for).
  #
  #     t = HtmlTable.new [1,2,3]
  #     t.head 'a', 'b', 'c'
  #     puts t.to_s
  #
  #     => <table class="table">
  #        <tr class="table-head"><th>a</th> <th>b</th> <th>c</th> </tr>
  #        <tr class="table-odd"><td>1</td> <td>2</td> <td>3</td> </tr>
  #        </table>
  def head(*cols)
    raise ArgumentError unless cols.is_a? Array
    @head = cols
  end

  # Adds a row to an existing HtmlTable. This row must be an array.
  # 
  #     t = HtmlTable.new
  #     t << [1,2,3]
  #     t << ['this', 'that', 'those']
  #     puts t.to_s
  #
  #     => <table class="table">
  #        <tr class="table-even"><td>1</td> <td>2</td> <td>3</td> </tr>
  #        <tr class="table-odd"><td>this</td> <td>that</td> <td>those</td> </tr>
  #        </table>
  def <<(data)
    raise ArgumentError unless data.is_a? Array
    super(data)
  end

  # Outputs the object's contents in HTML format.
  def to_s
    return @empty_msg if self.empty?

    ret = [%Q(<table class="#{@classes[:table]}">)]
    @head && ret << row(@classes[:head], @head.map {|item| "<th>#{item}</th> "}) 
    self.each do |r|
      ret << row(get_row_class, r.map {|item| "<td>#{item}</td> "})
    end

    ret << '</table>'

    ret.join("\n")
  end

  private
  # Builds the HTML row for a given element, using the HTML class
  # specified as the first parameter
  def row(klass, *items)
    @processed_rows += 1
    [ '', %Q(<tr class="#{klass}">), items, '</tr>' ].flatten.join
    
  end

  # Gets the right row class for the row to be processed (i.e. even or
  # odd)
  def get_row_class
    return @classes[:even] if @processed_rows % 2 == 0
    @classes[:odd]
  end
end
