class HtmlTable < Array
  DefaultClasses = { 
    :table => 'table',
    :head => 'table-head',
    :even => 'table-even',
    :odd => 'table-odd'
  }

  def initialize(classes={}, empty_msg=nil, *rows)
    classes.reverse_merge!(DefaultClasses)
    @classes = classes
    @empty_msg = empty_msg
    @head = nil
    @processed_rows = 0

    super()
    rows.each {|r| self << r}
  end

  def head(*cols)
    raise ArgumentError unless cols.is_a? Array
    @head = cols
  end

  def <<(data)
    raise ArgumentError unless data.is_a? Array
    super(data)
  end

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
  def row(klass, *items)
    @processed_rows += 1
    [ '', %Q(<tr class="#{klass}">), items, '</tr>' ].flatten.join
    
  end

  def get_row_class
    return @classes[:even] if @processed_rows % 2 == 0
    @classes[:odd]
  end
end
