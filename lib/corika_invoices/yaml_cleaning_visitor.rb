module CorikaInvoices
  class YamlCleaningVisitor < Psych::Visitors::YAMLTree
    def visit_Symbol(sym)
      visit_String(sym.to_s)
    end

    def self.clean(obj, io = nil, **options)
      visitor = YamlCleaningVisitor.create(**options)
      visitor << obj
      visitor.tree.yaml(io, **options)
    end
  end
end
