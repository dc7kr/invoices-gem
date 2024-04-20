module Hashify
  # Classes that include this module can exclude certain
  # instance variable from its hash representation by overriding
  # this method
  def ivars_excluded_from_hash
    []
  end
  
  def to_hash
    hash = {}
    excluded_ivars = ivars_excluded_from_hash

    # Iterate over all the instance variables and store their
    # names and values in a hash
    instance_variables.each do |var|
      next if excluded_ivars.include? var.to_s

      value = instance_variable_get(var)
      value = value.map(&:to_hash) if value.is_a? Array

      hash[var.to_s.delete("@")] = value
    end

    return hash
  end
end