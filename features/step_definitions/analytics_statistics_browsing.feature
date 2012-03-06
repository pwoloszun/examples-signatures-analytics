Feature: Analytics statistics browsing
  In order analyze and measure my email signatures efficiency
  As a user
  I want to browse my sent signatures statistics

  Background:
    Given I have already created "free" account with login "free@test.com" and password "123456"
    And there already exists template "Keller Williams" in system, containing tokens:
      | name         |
      | facebook_url |
      | twitter_url  |
    And I have created signature "test signature" using template "Keller Williams" with links:
      | name     | token        | text               | href                               |
      | facebook | facebook_url | my facebook page   | http://facebook.com/kellerwilliams |
      | twitter  | twitter_url  | my twitter account | http://twitter.com/kellerwilliams  |
    And I have sent email with signature "test signature" to "my.client@test.com"
    When I login as "free@test.com" with password "123456"

  Scenario: Entering signature statistics screen
    When I follow "signatures" in main menu
    And I click signature "test signature" statistics button
    Then I should be on signature "test signature" statistics page
    And I should see signatures statistics title
    And I should see back button

  Scenario: Browsing current month signatures statistics
    Given email with signature "test signature" has been opened 9 times in 9th month of 2010
    And email with signature "test signature" has been opened 1 time in 1st month of 2011
    And email with signature "test signature" has been opened 12 times in 3rd month of 2011
    And today is "2011-03-21"
    Then signature "test signature" impressions count should be:
      | current_month | 12 |
      | all_time      | 22 |

  Scenario: Browsing each month signatures statistics
    Given email with signature "test signature" has been opened 12 times in 8th month of 2010
    And today is "2010-08-03"
    Then signature "test signature" impressions count should be:
      | current_month | 12 |
      | all_time      | 12 |
    Given email with signature "test signature" has been opened 99 times in 3rd month of 2011
    And today is "2011-03-21"
    Then signature "test signature" impressions count should be:
      | current_month | 99  |
      | all_time      | 111 |
    Given today is "2011-06-01"
    Then signature "test signature" impressions count should be:
      | current_month | 0   |
      | all_time      | 111 |

  Scenario: Browsing current month links statistics
    Given link "facebook_url" signature "test signature" links, has been clicked:
      | clicks_count | year | month |
      | 22           | 2010 | 9     |
      | 99           | 2011 | 1     |
      | 9            | 2011 | 3     |
    Given link "twitter_url" signature "test signature" links, has been clicked:
      | clicks_count | on_date    |
      | 1            | 2010-09-01 |
      | 22           | 2011-01-01 |
      | 33           | 2011-03-01 |
    And today is "2011-03-21"
    When I enter signature "test signature" statistics page
    Then I should see links statistics table containing:
      | link_name    | current_month_clicks_count | all_time_clicks_count |
      | facebook_url | 9                          | 130                   |
      | twitter_url  | 33                         | 56                    |
