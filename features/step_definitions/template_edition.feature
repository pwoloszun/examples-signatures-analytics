Feature: Template edition
  In order to modify existing email template
  As an admin
  I want to make some changes in html template

  Background:
    Given there already exist templates:
      | name            | width | height | body                                                                        |
      | Keller Williams | 320   | 240    | <p>Keller Williams</p><img src='http://placehold.it/300x200'/>              |
      | Google          | 640   | 480    | <p>Google</p><img src='http://placehold.it/300x200'/>                       |
      | RocketMind      | 800   | 600    | <p>Rocket Mind</p><img src='http://placehold.it/300x200'/>                  |
      | Cameo           | 400   | 300    | <p>Cameo</p><img src='cameo_logo'/><img src='http://placehold.it/300x200'/> |
    And there already exist 5 signatures using "RocketMind" template
    And I'm logged in as admin
    And I enter admins email templates list page

  Scenario: Entering on existing template page
    When I click Edit "Cameo" template button
    Then I should be on "Cameo" template edit page
    And I should see template fields filled with:
      | label  | value                                                                       |
      | name   | Cameo                                                                       |
      | width  | 400                                                                         |
      | height | 300                                                                         |
      | body   | <p>Cameo</p><img src='cameo_logo'/><img src='http://placehold.it/300x200'/> |
    And I should see list of images to upload containing:
      | name       | action |
      | cameo_logo | change |

  Scenario: Previewing modified template
    When I click Edit "Google" template button
    And I modify template fields:
      | label | value                                                                |
      | width | 590                                                                  |
      | body  | <p>Google</p><p>{{name}}</p><img src='http://placehold.it/300x200'/> |
    And I press Preview template button
    Then I should be on "Google" template preview page
    And I should see modified "Google" template preview

  Scenario: Preview should not modify template
    When I click Edit "Google" template button
    And I modify template fields:
      | label | value                                                                |
      | width | 590                                                                  |
      | body  | <p>Google</p><p>{{name}}</p><img src='http://placehold.it/300x200'/> |
    And I press Preview template button
    And I press Edit button
    Then I should be on "Google" template edit page
    And I should see template fields filled with:
      | label  | value                                                 |
      | name   | Google                                                |
      | width  | 640                                                   |
      | height | 480                                                   |
      | body   | <p>Google</p><img src='http://placehold.it/300x200'/> |

  Scenario: Update template without signatures
    When I click Edit "Google" template button
    And I modify template fields:
      | label | value                                                                |
      | width | 590                                                                  |
      | body  | <p>Google</p><p>{{name}}</p><img src='http://placehold.it/300x200'/> |
    And I press Save template button
    Then I should be on email templates list page
    When I click Edit "Google" template button
    Then I should see template fields filled with:
      | label  | value                                                                |
      | name   | Google                                                               |
      | width  | 590                                                                  |
      | height | 480                                                                  |
      | body   | <p>Google</p><p>{{name}}</p><img src='http://placehold.it/300x200'/> |

  Scenario: Update template used in some signatures
    Given now is "2012-02-09 13:33:20"
    When I click Edit "RocketMind" template button
    And I modify template fields:
      | label | value                                                                |
      | width | 997                                                                  |
      | body  | <p>RM</p><div>{{name}}</div><img src='http://placehold.it/300x200'/> |
    And I press Save template button
    Then I should be on email templates list page
    When I click Edit "RocketMind" template button
    Then I should see template fields filled with:
      | label  | value                                                                |
      | name   | RocketMind                                                           |
      | width  | 997                                                                  |
      | height | 600                                                                  |
      | body   | <p>RM</p><div>{{name}}</div><img src='http://placehold.it/300x200'/> |
    And template "RocketMind" should have 0 signatures
    And template "RocketMind_20120209133320" should have 5 signatures

  Scenario: Modifying template images
    When I click Edit "Cameo" template button
    And I modify template fields:
      | label | value                                                                                                                  |
      | body  | <p>Cameo</p><img src='cameo_logo'/><img src='cameo_new'/><img src='cameo_fb'/><img src='http://placehold.it/300x200'/> |
    And I press Save template button
    Then I should be on "Cameo" template edit page
    And I should see list of images to upload containing:
      | name       | action |
      | cameo_logo | change |
      | cameo_new  | upload |
      | cameo_fb   | upload |

  @javascript
  Scenario: Uploading modified template assets
    When I click Edit "Cameo" template button
    And I modify template fields:
      | label | value                                                                                                                  |
      | body  | <p>Cameo</p><img src='cameo_logo'/><img src='cameo_new'/><img src='cameo_fb'/><img src='http://placehold.it/300x200'/> |
    And I press Save template button
    And I upload images:
      | filename     | asset name |
      | 01.png       | cameo_logo |
      | 02.png       | cameo_new  |
      | facebook.png | cameo_fb   |
    Then template "Cameo" should have assets:
      | name       |
      | cameo_logo |
      | cameo_new  |
      | cameo_fb   |

  @javascript
  Scenario: Replacing many times existing image with new ones
    When I click Edit "Cameo" template button
    And I upload images:
      | filename     | asset name |
      | 01.png       | cameo_logo |
      | 02.png       | cameo_logo |
      | facebook.png | cameo_logo |
    Then template "Cameo" should have assets:
      | name       |
      | cameo_logo |

  @javascript
  Scenario: Error while uploading images
    When TODO

  Scenario: Trying to preview template - missing images
    When I click Preview "Cameo" template button
    Then I should be on "Cameo" template edit page
    And I should see following template requirements errors:
      | requirements_error_code | params                            |
      | missing_assets          | {:missing_assets => 'cameo_logo'} |

  Scenario: Trying to show template - missing images
    When I click Show "Cameo" template button
    Then I should be on "Cameo" template edit page
    And I should see following template requirements errors:
      | requirements_error_code | params                            |
      | missing_assets          | {:missing_assets => 'cameo_logo'} |
