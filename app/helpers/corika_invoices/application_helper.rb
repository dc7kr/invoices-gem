module CorikaInvoices
  module ApplicationHelper
    def link_to_show(obj,params=nil)
      
      txtmode= params[:txtmode] unless params.nil?
      txt = params[:txt] unless params.nil?

      namespace=nil
      entity = nil

      if obj.kind_of?(Array) then
        namespace=  obj[0]
        entity = obj[1]
      else 
        entity = obj
      end


      if txt.nil? then
        txt = t('common.show')
      end

      if can? :read, entity

        if txtmode then
          link_to txt, obj
        else 
            link_to txt, obj, :class => "btn btn-default btn-xs" 
        end
      end
    end

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
end
