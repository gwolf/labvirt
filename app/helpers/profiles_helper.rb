module ProfilesHelper
  def list_row(item)
    @fields[:list].map { |fld|
      case fld
      when 'laboratory'
        link_to(item.laboratory.name,
                :controller => 'laboratories', 
                :action => 'edit', 
                :id => item.laboratory.id
                )
      else
        item.send(fld)
      end
    }.map {|col| "<td>#{col}</td>"}.join "\n"
  end
end
