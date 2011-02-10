module ActsAsTaggableOn
  module Taggable
    def taggable?
      false
    end

    ##
    # This is an alias for calling <tt>acts_as_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_taggable
    #   end
    def acts_as_taggable
      acts_as_taggable_on :tags
    end

    ##
    # Make a model taggable on specified contexts.
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_taggable_on :languages, :skills, :scope => :community
    #   end    
    #
    def acts_as_taggable_on(*tag_types)
      tag_types = tag_types.to_a.flatten.compact
      
      options = tag_types[-1].kind_of?(Hash) ? tag_types.slice!(-1) : {}
      
      tag_types = tag_types.map(&:to_sym)
      
      if taggable?
        write_inheritable_attribute(:tag_types, (self.tag_types + tag_types).uniq)        
        write_inheritable_attribute(:tag_scope, options[:scope])
      else
        write_inheritable_attribute(:tag_types, tag_types)
        class_inheritable_reader(:tag_types)
        
        write_inheritable_attribute(:tag_scope, options[:scope])
        class_inheritable_reader(:tag_scope)
        
        class_eval do
          has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag, :class_name => "ActsAsTaggableOn::Tagging"
          has_many :base_tags, :through => :taggings, :source => :tag, :class_name => "ActsAsTaggableOn::Tag"
            # :conditions => '#{ActsAsTaggableOn::Tag.table_name}.scoped_type = \'#{self.send(:tag_scope).table_name}\' AND #{ActsAsTaggableOn::Tag.table_name}.scoped_id = \'#{self.send(:tag_scope).id}\''

          def self.taggable?
            true
          end
        
          include ActsAsTaggableOn::Taggable::Core
          include ActsAsTaggableOn::Taggable::Collection
          include ActsAsTaggableOn::Taggable::Cache
          include ActsAsTaggableOn::Taggable::Ownership
          include ActsAsTaggableOn::Taggable::Related
        end
      end
    end
  end
end
