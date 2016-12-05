class Database
  def self.where(table_name)
    fail "Database:nope"
  end
end

class Analytics
  def self.tag(event)
    fail "Analytics:nope"
  end
end

class StatusUpdate
  def self.find(id)
    fail "StatusUpdate:nope"
  end
end

class User
  def table_reader
    @table_reader ||= Database
  end

  def event_tagger
    @event_tagger ||= Analytics
  end

  def user_finder
    @user_finder || User
  end

  def status_update_finder
    @status_update_finder || StatusUpdate
  end

  def with_table_reader(table_reader)
    @table_reader = table_reader
    self
  end

  def with_event_tagger(event_tagger)
    @event_tagger = event_tagger
    self
  end

  def with_user_finder(user_finder)
    @user_finder = user_finder
    self
  end

  def with_status_update_finder(status_update_finder)
    @status_update_finder = status_update_finder
    self
  end

  def self.find(id)
    fail "User:nope"
  end

  attr_reader :id
  def initialize(id)
    @id = id
  end

  def notifications
    notifications = table_reader
      .where("notifications") do |x|
        (x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
            (x[1][0] == "favorited_notification" && status_update_finder.find(x[1][2].to_i).owner_id == id) ||
            (x[1][0] == "replied_notification" && status_update_finder.find(x[1][2].to_i).owner_id == id) ||
            (x[1][0] == "reposted_notification" && status_update_finder.find(x[1][2].to_i).owner_id == id)
      end.map do |row|
        id, values = row
        kind = values[0]

        if kind == "followed_notification"
          {
              kind: kind,
              follower: user_finder.find(values[1].to_i),
              user: user_finder.find(values[2].to_i),
          }
        elsif kind == "favorited_notification"
          {
              kind: kind,
              favoriter: user_finder.find(values[1].to_i),
              status_update: status_update_finder.find(values[2].to_i),
          }
        elsif kind == "replied_notification"
          {
              kind: kind,
              sender: user_finder.find(values[1].to_i),
              status_update: status_update_finder.find(values[2].to_i),
              reply: status_update_finder.find(values[3].to_i),
          }
        elsif kind == "reposted_notification"
          {
              kind: kind,
              reposter: user_finder.find(values[1].to_i),
              status_update: status_update_finder.find(values[2].to_i),
          }
        end
      end

    event_tagger.tag({name: "fetch_notifications", count: notifications.count})
    notifications
  end
end

require_relative "./spec_helper"

class FakeTableReader
  def where(table_name, &filter)
    tables(table_name).select(&filter)
  end

  def insert(table_name, row)
    tables(table_name) << row
  end

  def tables(table_name)
    @tables ||= {}
    @tables[table_name] ||= []
  end
end

class FakeEventTagger
  def tag(event)

  end
end

class FakeUserFinder
  def find(id)
    User.new(id)
  end
end

class FakeStatusUpdateFinder
  def find(id)
    StatusUpdate.new
  end
end

RSpec.describe User do
  let(:fake_table_reader) { FakeTableReader.new }
  let(:fake_event_tagger) { FakeEventTagger.new }
  let(:fake_user_finder) { FakeUserFinder.new }
  let(:fake_status_update_finder) { FakeStatusUpdateFinder.new }

  it "obtains followed notifications for the user" do
    user = create_user_with_fakes

    fake_table_reader
        .insert("notifications",
                [1001, ["followed_notification", 2001, "567"]])

    expect(user.notifications.count).to eq(1)
  end

  it "ignores notifications of invalid kind" do
    user = create_user_with_fakes

    fake_table_reader
        .insert("notifications",
                [1001, ["invalid", 2001, "567"]])

    expect(user.notifications.count).to eq(0)
  end

  it "ignores notifications of different user" do
    user = create_user_with_fakes

    fake_table_reader
        .insert("notifications",
                [1001, ["followed_notification", 2001, "other user"]])

    expect(user.notifications.count).to eq(0)
  end

  it "constructs correct followed notification" do
    user = create_user_with_fakes

    fake_table_reader
        .insert("notifications",
                [1001, ["followed_notification", 2001, "567"]])

    expect(user.notifications[0][:kind]).to eq("followed_notification")
  end

  def create_user_with_fakes
    User.new(567)
        .with_table_reader(fake_table_reader)
        .with_event_tagger(fake_event_tagger)
        .with_user_finder(fake_user_finder)
        .with_status_update_finder(fake_status_update_finder)
  end
end