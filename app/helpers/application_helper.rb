module ApplicationHelper
  def formatted_hours(minutes)
    hours = (minutes.to_f / 60).round(2)
    text = hours.to_s.sub(/\.0+\z/, "").sub(/(\.\d*[1-9])0+\z/, '\\1').tr(".", ",")
    "#{text} h"
  end
  def time_value(minutes)
    safe_join([content_tag(:strong, "#{minutes} min"), content_tag(:small, " / #{formatted_hours(minutes)}", class: "muted")])
  end
end
