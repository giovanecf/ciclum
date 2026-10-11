User.find_each do |user|
  cycle = user.study_cycles.find_or_initialize_by(seed_key: "initial-default")
  if cycle.new_record?
    cycle.assign_attributes(name: "Default", weekly_reference_minutes: 1440, active: user.study_cycles.where(active: true).none?)
    cycle.save!
  elsif user.study_cycles.where(active: true).none?
    cycle.activate!
  end
end
