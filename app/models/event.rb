# == Schema Information
# Schema version: 20100330111833
#
# Table name: events
#
#  id              :integer(4)      not null, primary key
#  title           :string(255)
#  starttime       :datetime
#  endtime         :datetime
#  all_day         :boolean(1)
#  created_at      :datetime
#  updated_at      :datetime
#  description     :text
#  event_series_id :integer(4)
#

class Event < ActiveRecord::Base
  
  attr_accessor :period, :frequency, :commit_button, :backgroundColor, :textColor, :organizer_id
  
  validates_presence_of :title, :description, :starttime, :endtime
  validate :validate_start_time_before_end_time
  
  belongs_to :event_series
  belongs_to :event_type
  has_many :proposals, :class_name => 'Proposal', :foreign_key => 'vote_period_id'
  has_one :meeting, :class_name => 'Meeting', :dependent => :destroy
  has_one :place, :through => :meeting, :class_name => 'Place'
  has_many :meeting_organizations, :class_name => 'MeetingOrganization', :foreign_key => 'event_id', :dependent => :destroy
  has_many :organizers, :through => :meeting_organizations, :class_name => 'Group', :source => :group
  
  has_one :election, :class_name => 'Election', :dependent => :destroy
  accepts_nested_attributes_for :meeting, :election
  
  scope :vote_period, { :conditions => ["event_type_id = ? AND starttime > ?",2,Date.today], :order => "starttime asc"}
  
  REPEATS = ["Non ripetere",
             "Ogni giorno",
             "Ogni settimana",
             "Ogni mese",
             "Ogni anno"]
  
  
  def validate_start_time_before_end_time
    if starttime && endtime
      errors.add(:starttime, "La data di inizio deve essere antecedente la data di fine") if endtime < starttime
    end
    
    if (event_type_id.to_s == "4")
      if (election.groups_end_time && election.candidates_end_time)
        if (election.groups_end_time < starttime ||
            election.groups_end_time > endtime ||
            election.candidates_end_time < starttime ||
            election.candidates_end_time > endtime)
        errors.add(:starttime, "Le date di termine iscrizioni devono essere comprese tra la data inizio e la data fine dell'evento")
        end 
      end
    end
  end
  
  def organizer_id=(id)
    if (self.meeting_organizations.empty?)
      self.meeting_organizations.build(:group_id => id)
    end
  end
  
  def organizer_id
    self.meeting_organizations.first.group_id rescue nil
  end
  
  def is_past?
    return Time.now > self.endtime
  end
  
  def is_now?
    return self.starttime < Time.now && self.endtime > Time.now
  end
  
   def is_not_started?
    return Time.now < self.starttime
  end
  
  
  def backgroundColor
    return "#DFEFFC"
  end
  
  def textColor
    return "#333333"
  end
  
  def validate
    if (starttime >= endtime) and !all_day
      errors.add_to_base("Start Time must be less than End Time")
    end
  end
  
  def update_events(events, event)
    events.each do |e|
      begin 
        st, et = e.starttime, e.endtime
        e.attributes = event
        if event_series.period.downcase == 'monthly' or event_series.period.downcase == 'yearly'
          nst = DateTime.parse("#{e.starttime.hour}:#{e.starttime.min}:#{e.starttime.sec}, #{e.starttime.day}-#{st.month}-#{st.year}")  
          net = DateTime.parse("#{e.endtime.hour}:#{e.endtime.min}:#{e.endtime.sec}, #{e.endtime.day}-#{et.month}-#{et.year}")
        else
          nst = DateTime.parse("#{e.starttime.hour}:#{e.starttime.min}:#{e.starttime.sec}, #{st.day}-#{st.month}-#{st.year}")  
          net = DateTime.parse("#{e.endtime.hour}:#{e.endtime.min}:#{e.endtime.sec}, #{et.day}-#{et.month}-#{et.year}")
        end
        #puts "#{nst}           :::::::::          #{net}"
      rescue
        nst = net = nil
      end
      if nst and net
        #          e.attributes = event
        e.starttime, e.endtime = nst, net
        e.save
      end
    end
    
    event_series.attributes = event
    event_series.save
  end
  
 
  
  
  
end
