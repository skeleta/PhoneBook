# module GUI
class Gui
require "./main"
require "green_shoes"


  def initialize(app)
    @app = app
    @menagers = {}
    @current_phone_book
    navigation_bar
  end

  def navigation_bar
    @nav = @app.flow do

      @app.button "Create" do
        @app.alert @e.text
      end

      @e = @app.edit_line :width => 350, :height => 25

      @app.button "Load" do

        if @e.text == ""
          @app.alert "Enter name for phone book please"
        elsif @menagers[@e.text] != nil
          @app.alert "Phone book #{@e.text} is already loaded"
        else
          @menagers[@e.text] = Save.load_phone_book @e.text
          @current_phone_book = @menagers[@e.text]
          @app.append do
            add_book(@current_phone_book)
          end
        end

      end
    end
  end

  def add_book(phone_book)
    @contact_list = @app.stack

    @adding_button = @app.button "Add new record" do
      @contact_list.prepend do
        @adding_field = @app.stack
        @adding_field.append do
          add_new_record
        end
      end
    end

    @app.para "Phone book #{@e.text}:"
    phone_book.phone_book.each do |contact|
      @contact_list.append do
        @app.button(
                    contact.headline,
                    :width => 400,
                    :height => 30,
                    margin: 4
                    ) do

          open_new_app(phone_book, contact)
        end
      end
    end

    @contact_list.append do
      @app.button "Clear" do
        @contact_list.clear do add_book(phone_book) end
      end
    end

  end

  def add_new_record
    @new_contact_records = {}

    @current_phone_book.parameters.each do |parameter|
      @app.para parameter.to_s
      value = @app.edit_line do
        @new_contact_records[parameter] = value.text == "" ? nil : value.text
      end
    end

    3.times do
      @app.flow do
        @app.para "Custom record:"
        param_value = ""
        old_param_value = ""
        param = @app.edit_line do
          old_param_value = param_value
          param_value = param.text
          @new_contact_records.delete(old_param_value.to_sym) if @new_contact_records[old_param_value.to_sym]
        end
        value = @app.edit_line do
          unless param_value == "" or value.text == ""
            @new_contact_records[param_value.to_sym] = value.text == "" ? nil : value.text
          end
        end
      end

    end
    @app.button "Preview" do
      @app.alert @new_contact_records.inspect
    end
    @app.button "Add to phone book" do
      if @new_contact_records[:first_name] == nil or @new_contact_records[:mobile] == nil or @new_contact_records[:email] == nil
        @app.alert "first_name, mobile and email are required fields"
      else
        message = @current_phone_book.add_contact @new_contact_records
        if message == "Contact added succsessfuly"
          @app.alert message
          @contact_list.clear do add_book(@current_phone_book) end
        else
          @app.alert message
        end
      end
    end
  end

  def open_new_app(phone_book, contact)
    new_app = Shoes.app do
      Editer.new self, phone_book, contact
    end
  end

end

class Editer
  def initialize(app, phone_book, contact)
      @app = app
      @phone_book = phone_book
      @contact = contact
      load_info
  end

  def load_info
    @phone_book.select mobile: @contact.record[:mobile].first
    @selected = @phone_book.selected

    @info = @app.stack
    @info.append do
      load_records
    end
  end

  def load_records
    @contact.parameters.each do |parameter|
      param_record = @app.flow
      @info.append do
        param_record.append do
        if [:email, :mobile].include? parameter
          @app.para parameter
          @selected.record[parameter].each do |record_value|
            value = @app.edit_line record_value
            old_value = value.text
            option = :insert
            option_chooser = @app.list_box(
                          items: ["insert", "delete", "replace"],
                          width: 60,
                          choose: "insert"
                          ) do |list|
              option = list.text.to_sym
            end
            @app.button "Edit" do
              if option == :replace
                message = @phone_book.edit parameter, old_value, option, new_value: value.text
                @info.clear do load_records end
              else
                message = @phone_book.edit parameter, value.text, option
                @info.clear do load_records end
              end
              if message.is_a? String
                @app.alert message
              end
            end

          end
        else
          @app.para parameter
          value = @app.edit_line "#{@selected.record[parameter].to_s}"
          old_value = value.text
          @app.button "Edit" do
            message = @phone_book.edit(parameter, value.text == "" ? nil : value.text)
            if message != value.text and parameter == :first_name
              @app.alert message
              value.text = old_value
            end
          end
        end
      end
      end
    end #contact.parameters.each

    (13 - @selected.parameters.length).times do
      custom = @app.flow
      @info.append do
        custom.append do
          param = @app.edit_line "new_param"
          value = @app.edit_line "set_value"
          @app.button "Edit" do
            message = @phone_book.edit(param.text.to_sym, value.text == "" ? nil : value.text)
            if message.is_a? String
              @app.alert message
              value.text = "set_value"
              param.text = "new_param"
            end
            @info.clear do load_records end
          end
        end
      end
    end

    @app.button "close" do
      @contact_list.clear
      @app.close
    end
  end
end
# end #module

Shoes.app do
  Gui.new self
end