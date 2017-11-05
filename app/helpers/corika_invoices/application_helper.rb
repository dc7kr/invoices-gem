module CorikaInvoices
  module ApplicationHelper
    def entity_row(entity, field,type=nil)
      sym = entity.class.name.underscore.to_sym
      content_tag :div, :class => "row" do
        concat(content_tag(:div, label(sym, field), :class => "col-md-3 text-right"))

        tmp_data = entity[field]

        if tmp_data.nil? then
          return ""
        end
        data = nil
        if type.nil?
          data = tmp_data
        elsif type == :date
          data = l tmp_data
        elsif type == :mailto
          data = mail_to tmp_data,tmp_data
        elsif type == :currency
          data = format_currency tmp_data,"EUR"
        end
        concat(content_tag(:div, data,:class => "col-md-9"))
      end
    end
  end

 def method_missing method, *args, &block
      if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
        if main_app.respond_to?(method)
          main_app.send(method, *args)
        else
          super
        end
      else
        super
      end
    end

    def respond_to?(method)
      if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
        if main_app.respond_to?(method)
          true
        else
          super
        end
      else
        super
      end
    end
end
