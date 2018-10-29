class Person < ActiveRecord::Base
  belongs_to :location
  belongs_to :role
  belongs_to :manager, class_name: "Person", foreign_key: :manager_id
  has_many :employees, class_name: "Person", foreign_key: :manager_id

  def self.without_remote_manager
    joins(
      <<-SQL
        LEFT JOIN people managers
        ON managers.id = people.manager_id
      SQL
    ).where(
      "managers.id IS NULL OR managers.location_id = people.location_id"
    )
  end

  def self.order_by_location_name
    joins(:location).order("locations.name")
  end

  def self.with_employees
    joins(
      "INNER JOIN (" +
        Person.joins(:employees).distinct.to_sql +
      ") managers " \
      "ON people.id = managers.id"
    )
    # OR
    # from(
    #   Person.joins(:employees).distinct, "people"
    # )
  end

  def self.with_local_coworkers
    joins(
      "INNER JOIN (" +
        Person.
          joins("
            INNER JOIN locations AS people_and_locations
            ON people.location_id = people_and_locations.id
            INNER JOIN people AS people_and_locations_and_people
            ON people_and_locations.id = people_and_locations_and_people.location_id
          ").
          where("people_and_locations_and_people.id <> people.id").
          distinct.
          to_sql +
        ") people_with_local_coworkers " \
        "ON people.id = people_with_local_coworkers.id"
    )
  end
end
