module ApplicationHelper

  ##
  # @return [String] Bootstrap alerts for each flash message.
  #
  def flashes
    html = StringIO.new
    flash.each do |type, message|
      html << "<div class=\"alert alert-dismissable #{bootstrap_class_for(type)}\" role=\"alert\">
          <button type=\"button\" class=\"close\" data-dismiss=\"alert\"
                  aria-label=\"Close\">
            <span aria-hidden=\"true\">&times;</span>
          </button>
          #{message}
        </div>"
    end
    raw(html.string)
  end

  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
    when :success
      'alert-success'
    when :error
      'alert-danger'
    when :alert
      'alert-block'
    when :notice
      'alert-info'
    else
      flash_type.to_s
    end
  end

end
