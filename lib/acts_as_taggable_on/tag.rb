module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableOn::ActiveRecord::Backports if ::ActiveRecord::VERSION::MAJOR < 3
  
    attr_accessible :name

    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'
    belongs_to :scoped, :polymorphic => true

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name, :scope => [:scoped_id, :scoped_type]

    ### SCOPES:
    
    scope :with_tag_scope, lambda{|tag_scope| tag_scope ? where(:scoped_id => tag_scope.id, :scoped_type => tag_scope.class.name) : nil}
    
    def self.using_postgresql?
      connection.adapter_name == 'PostgreSQL'
    end

    def self.named(name, tag_scope = nil)
      s = where(["name #{like_operator} ?", name])
      tag_scope ? s.with_tag_scope(tag_scope) : s
    end
  
    def self.named_any(list, tag_scope = nil)
      s = where(list.map { |tag| sanitize_sql(["name #{like_operator} ?", tag.to_s]) }.join(" OR "))
      tag_scope ? s.with_tag_scope(tag_scope) : s
    end

    def self.named_any_equals(list, tag_scope = nil)
      s = where(list.map { |tag| sanitize_sql(["name = ?", tag.to_s]) }.join(" OR "))
      tag_scope ? s.with_tag_scope(tag_scope) : s
    end
  
    def self.named_like(name, tag_scope = nil)
      s = where(["name #{like_operator} ?", "%#{name}%"])
      tag_scope ? s.with_tag_scope(tag_scope) : s
    end

    def self.named_like_any(list, tag_scope = nil)
      s = where(list.map { |tag| sanitize_sql(["name #{like_operator} ?", "%#{tag.to_s}%"]) }.join(" OR "))
      tag_scope ? s.with_tag_scope(tag_scope) : s
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name, tag_scope = nil)
      named_like(name, tag_scope).first || create_scoped_tag(name, tag_scope)
    end

    def self.find_or_create_all_with_like_by_name(list, tag_scope = nil)
      list = [list].flatten

      return [] if list.empty?

      existing_tags = Tag.named_any_equals(list, tag_scope).all
      
      new_tag_names = list.reject do |name| 
        name = comparable_name(name)
        existing_tags.any? { |tag| comparable_name(tag.name) == name }
      end
      
      created_tags  = new_tag_names.map do |name| 
        create_scoped_tag(name, tag_scope)
      end

      existing_tags + created_tags
    end
    
    def self.create_scoped_tag(name, tag_scope = nil)
      tag = Tag.new(:name => name.strip)
      tag.scoped = tag_scope unless tag_scope.blank?
      tag.save
      tag
    end
    
    ### INSTANCE METHODS:

    def ==(object)
      super || (object.is_a?(Tag) && name == object.name)
    end

    def to_s
      name
    end

    def count
      read_attribute(:count).to_i
    end

    class << self
      private
        def like_operator
          using_postgresql? ? 'ILIKE' : 'LIKE'
        end
        
        def comparable_name(str)
          RUBY_VERSION >= "1.9" ? str.downcase : str.mb_chars.downcase
        end
    end
  end
end