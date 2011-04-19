require 'rdbi'
require 'oci8'

class RDBI::Driver::Oracle < RDBI::Driver
  # -- Basic RDBI initialization
  def initialize(*args)
    super(Database, *args)
  end

  class Database < RDBI::Database
    attr_accessor :handle

    def initialize(*args)
      super
      self.database_name = @connect_args[:database]
      # TODO - other arguments:
      #           Privilege (:SYSDBA / AS SYSDBA)
      #           Client Info
      #           Client Identifier
      @handle = OCI8.new(@connect_args[:user] || @connect_args[:username],
                         @connect_args[:password],
                         @connect_args[:database])
    end

    def disconnect
      super
      @handle.logoff
    end

    def rewindable_result; true end

    #def transaction(&block)
    #  super
    #end

    def commit
      @handle.commit
      super
    end

    def rollback
      @handle.rollback
      super
    end

    def ping
      @handle.ping
    end

    def schema; super end
    def table_schema; super end

    def new_statement(query)
      Statement.new(query, self)
    end

  end # -- class RDBI::Driver::Oracle::Database

  class Statement < RDBI::Statement
    OUT_TYPE_MAP = RDBI::Type.create_type_hash(RDBI::Type::Out)

    def initialize(query, dbh)
      super

      ep = Epoxy.new(query)
      @index_map = ep.indexed_binds
      placeholder = 0
      query = ep.quote(@index_map.compact.inject({}) { |x,y| x.merge({ y => nil }) }) { ':' + (placeholder += 1).to_s }
      @handle = dbh.handle.parse(query)
      prep_finalizer { @handle.close unless @handle.closed? }
    end

    def rewindable_result; true end

    def new_execution(*params)
      params = RDBI::Util.index_binds(params, @index_map)

      params.each_with_index do |p, i|
        @handle[i+1] = p
      end

      # FIXME @handle.get_col_names
      @handle.exec(*params)

      columns = @handle.column_metadata.collect do |md|
                   #puts "column: #{md.name}"
                   #puts "type name: #{md.type_name}"
                   #puts "type string: #{md.type_string}"
                   #puts "data type: #{md.data_type}"

                   RDBI::Column.new(
                     :name => md.name.to_sym,
                     :type => md.type_string.to_sym,
                     :ruby_type => md.data_type,
                     :precision => md.precision, # XXX - fsprecision? lf?
                     :scale => md.scale,
                     :nullable => md.nullable? != 0,
                     :metadata => nil, # XXX - we can get something here
                     :default => nil,
                     :table => nil,
                     :primary_key => nil,
                   )
                 end

      return Cursor.new(@handle), RDBI::Schema.new(columns), OUT_TYPE_MAP
    end

    def new_modification
      params = RDBI::Util.index_binds(params, @index_map)

      params.each_with_index do |p, i|
        @handle[i+1] = p
      end

      @handle.exec(*params)
    end

  end # -- class RDBI::Driver::Oracle::Statement

  class Cursor < RDBI::Cursor
    def initialize(handle)
      super
      @index = 0
      @data = []
      if handle.type == ::OCI8::STMT_SELECT
        while r = handle.fetch
          @data << r
        end
      end
    end

    def rewindable_result; true end
    def affected_count; 0 end # FIXME

    def result_count; @data.size end

    def empty?; @data.size == 0 end

    def first; @data.first end
    def last; @data[-1] end

    def fetch(count = 1)
      a = []
      while !last_row?
        a << next_row
      end
      a
    end

    def next_row
      r = @data[@index]
      @index += 1 if r
      r
    end

    def rest
      @data[@index, @data.size]
    end

    def last_row?
      @index >= @data.size
    end

    def rewind
      @index = 0
    end

    def finish
      @handle.close
    end
  end # -- class RDBI::Driver::Oracle::Cursor

end
