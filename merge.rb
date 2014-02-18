class Merger
  def initialize
    @options = %i(first second merge)
  end

  def merge(first, second)
    @merged = ::ContactMenager::PhoneBook.new
    first.phone_book.each { |contact| @merged.add_contact contact.record }

    second.phone_book.each do |contact|
      duplicate = @merged.find_duplicate(contact.record[:mobile], contact.record[:email])
      if duplicate.empty?
        @merged.add_contact contact.record
      else
        collision_handler_output(duplicate.first, contact)
      end
    end

    @merged
  end

  def collision_handler(duplicate, new_contact, option)
    case option
      when :first
        puts "Did't add\n#{new_contact.headline}"
      when :second
        puts "Repleced #{duplicate.headline.strip} with #{new_contact.headline}"
        @merged.phone_book.delete duplicate
        @merged.add_contact new_contact.record
      when :merge
        @merged.phone_book.delete duplicate
        join_records(duplicate, new_contact)
    end
  end

  def join_records(duplicate, new_contact)
    puts "Chouse which record from:\n"
    puts "#{new_contact.show}\nto replace in\n"
    puts "#{duplicate.show}"

    changes = gets.strip.split(" ").map { |record| record.to_sym }
    until (changes - new_contact.parameters).size == 0
      puts "Some parameters are incorrect: #{changes.join(", ").to_s}"
      changes = gets.strip.split(" ").map { |record| record.to_sym }
    end

    extract_records(duplicate, new_contact, changes)
  end

  def extract_records(duplicate, new_contact, changes)
    join_record = required_record_joiner(duplicate, new_contact, changes)

    changes.each { |key| join_record[key] = new_contact.record[key] }
    (duplicate.record.keys - changes - [:email, :mobile]).each { |key| join_record[key] = duplicate.record[key] }

    @merged.add_contact join_record
    puts "The new record is:\n#{@merged.phone_book.last.show}"
  end

  def required_record_joiner(duplicate, new_contact, changes)
    if changes.include? :email or changes.include? :mobile
      if changes.include? :email and changes.include? :mobile
        {
          email: new_contact.record[:email],
          mobile: new_contact.record[:mobile]
        }
      else
        choosen = (changes & [:email]).empty? ? :mobile : :email
        unchoosen = ([:email, :mobile] - [choosen]).first
        {
          unchoosen => (duplicate.record[unchoosen] + new_contact.record[unchoosen]).uniq,
          choosen => new_contact.record[choosen]
        }
      end
    else
      {
        email:  (duplicate.record[:email] + new_contact.record[:email]).uniq,
        mobile: (duplicate.record[:mobile] + new_contact.record[:mobile]).uniq
      }
    end
  end

  def collision_handler_output(duplicate, new_contact)
    puts "#{duplicate.headline.strip} duplicates with #{new_contact.headline}"
    puts "Select one of this options: #{@options.join(", ").to_s}\n"

    option = gets.chomp.to_sym
    until @options.include? option
       puts "Avelabal options are #{@options.join(", ").to_s}"
       option = gets.chomp.to_sym
    end

    collision_handler(duplicate, new_contact, option)
  end

end