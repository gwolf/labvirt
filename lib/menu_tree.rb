# = MenuTree
# 
# Represents the application menu as an array of MenuItem elements,
# and outputs it as its HTML representation.
# 
# As MenuItems can hold MenuTrees in them, this allows for arbitrarily
# deep nested MenuTrees.
class MenuTree  < Array
  attr_accessor :menu_id, :entry_class, :elem_tag, :menu_tag

  # A MenuTree can be initialized empty or with any number of MenuItem
  # elements
  def initialize *items
    options = ( ! items.empty? and 
                items[-1].is_a?(Hash) ) ? items.delete_at(-1) : {}

    self.concat items

    @menu_id = options.delete(:menu_id) || 'menu'
    @entry_class = options.delete(:entry_class) || 'menu-element'
    @menu_tag = options.delete(:menu_tag) || 'ul'
    @elem_tag = options.delete(:elem_tag) || 'li'

    options.empty? or raise(ArgumentError, 
                            _("Unexpected arguments received: ") <<
                            options.keys.sort.join(', '))
  end

  # Outputs the generated menu to HTML
  def to_s
    [menu_start, 
     self.map {|elem|  elem_start << elem.to_s << elem_end}.join("\n"),
     menu_end].join("\n")
  end

  # Adds a MenuItem with the specified label (and optional link and
  # subtrees) to the current menu.
  def add(label, link=nil, tree=nil)
    mi = MenuItem.new(label, link, tree)
    self << mi
    mi
  end

  private
  def menu_start
    @menu_id ? %Q(<#{menu_tag} class="#{@menu_id}">) : "<#{menu_tag}>"
  end
  def menu_end; "</#{menu_tag}>";  end

  def elem_start
    @entry_class ? %Q(<#{elem_tag} class="#{@entry_class}">) : '<#{elem_tag}>'
  end
  def elem_end; "</#{elem_tag}>"; end
end

# = MenuItem
#
# Each of the items in a MenuTree.
#
# Each MenuItem represents a node in the tree. Each MenuItem can also
# point to a MenuTree, nested beneath it.
#
# === Attributes
# 
# [label] Required attribute. The label (string) that should be
#         printed at this element's node.
#
# [link] Optional attribute. The URL this MenuItem links to. If link
#        is not present or nil, only a static label will be
#        printed. The link should be given in a way that can be passed
#        over to ActionView::Helpers::UrlHelper#link_to
#
# [tree] A MenuTree that will appear as nested under this MenuItem
class MenuItem
  include ActionView::Helpers::UrlHelper

  attr_accessor :label, :link, :tree
  def initialize(label, link=nil, tree=nil)
    @label = label.to_s
    @link = link
    @tree = tree
  end

  # Produces the HTML representation of this MenuItem and (if any) of
  # the MenuTree it has.
  def to_s
    ret = build_link
    ret << tree.to_s if tree

    ret
  end

  private
  # Produce either the label by itself or, if we have a link, the
  # the corresponding HTML tag (with the adequate label)
  def build_link
    @label ||= ''
    return label if link.nil?
    return link_to(label, link)
  end
end
