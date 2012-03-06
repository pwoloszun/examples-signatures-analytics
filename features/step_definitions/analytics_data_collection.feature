Feature: Analytics data collection
  In order create sent signatures statistics
  As a system
  I want to track signatures impressions and interactions

  Background:
    Given I have already created "free" account with login "free@test.com" and password "123456"
    And there already exists template "Keller Williams" in system, containing tokens:
      | name         |
      | facebook_url |
      | twitter_url  |
    And I have created signature "test signature" using template "Keller Williams" with links:
      | token        | text     | href                               |
      | facebook_url | facebook | http://facebook.com/kellerwilliams |
      | twitter_url  | twitter  | http://twitter.com/kellerwilliams  |
    And I have sent email with signature "test signature" to "my.client@test.com"

  Scenario: System tracks and stores every single signature impression in current month
    Then signature "test signature" impressions count in current month should be 0
    When anyone opens email with signature "test signature" 1 time
    Then signature "test signature" impressions count in current month should be 1
    When anyone opens email with signature "test signature" 3 times
    Then signature "test signature" impressions count in current month should be 4

  Scenario: System sum ups signature impressions for each day within current month
    Given today is "2011-01-13"
    Then signature "test signature" impressions count in current month should be 0
    When anyone opens email with signature "test signature" 2 times
    Then signature "test signature" impressions count in current month should be 2
    Given today is "2011-01-22"
    When anyone opens email with signature "test signature" 5 times
    Then signature "test signature" impressions count in current month should be 7
    Given today is "2011-02-02"
    When anyone opens email with signature "test signature" 1 time
    Then signature "test signature" impressions count in 1st month of 2011 should be 7

  Scenario: System tracks signature impressions for each month
    Given today is "2011-02-13"
    Then signature "test signature" impressions count in current month should be 0
    When anyone opens email with signature "test signature" 2 times
    Then signature "test signature" impressions count in current month should be 2
    Given today is "2011-09-24"
    Then signature "test signature" impressions count in current month should be 0
    When anyone opens email with signature "test signature" 7 times
    Then signature "test signature" impressions count in current month should be 7
    Given today is "2012-03-03"
    Then signature "test signature" impressions count in current month should be 0
    When anyone opens email with signature "test signature" 1 time
    Then signature "test signature" impressions count in 3rd month of 2012 should be 1

  Scenario: System redirects to original site
    When recipient opens email with signature "test signature" and clicks links:
      | token        | clicks_count |
      | facebook_url | 1            |
    Then someone should be redirected to "http://facebook.com/kellerwilliams"

  Scenario: System tracks and stores every single click on signature link within single month
    Given today is "2012-03-03"
    Then signatures "test signature" links clicks should be:
      | token        | current_month | all_time |
      | facebook_url | 0             | 0        |
      | twitter_url  | 0             | 0        |
    Given today is "2012-03-09"
    When recipient opens email with signature "test signature" and clicks links:
      | token        | clicks_count |
      | facebook_url | 1            |
    Then signatures "test signature" links clicks should be:
      | token        | current_month | all_time |
      | facebook_url | 1             | 1        |
      | twitter_url  | 0             | 0        |
    Given today is "2012-03-23"
    When recipient opens email with signature "test signature" and clicks links:
      | token        | clicks_count |
      | facebook_url | 11           |
      | twitter_url  | 9            |
    Then signatures "test signature" links clicks should be:
      | token        | current_month | all_time |
      | facebook_url | 12            | 12       |
      | twitter_url  | 9             | 9        |

  Scenario: System tracks signature link clicks for each month
    Given today is "2012-01-02"
    Then signatures "test signature" links clicks should be:
      | token        | current_month | all_time |
      | facebook_url | 0             | 0        |
      | twitter_url  | 0             | 0        |
    Given today is "2012-03-09"
    When recipient opens email with signature "test signature" and clicks links:
      | token        | clicks_count |
      | facebook_url | 23           |
    Then signatures "test signature" links clicks should be:
      | token        | current_month | all_time |
      | facebook_url | 23            | 23       |
      | twitter_url  | 0             | 0        |
    Given today is "2012-09-23"
    When recipient opens email with signature "test signature" and clicks links:
      | token        | clicks_count |
      | facebook_url | 11           |
      | twitter_url  | 64           |
    Then signatures "test signature" links clicks should be:
      | token        | current_month | all_time |
      | facebook_url | 11            | 34       |
      | twitter_url  | 64            | 64       |
