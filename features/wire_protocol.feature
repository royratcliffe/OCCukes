Feature: Wire Protocol
  In order to touch iOS and Mac applications in intimate places
  As an Apple developer
  I want to utilise the low-level Cucumber wire protocol to run steps within my application

  Scenario: Quoted arguments
    When my scenario includes some "quoted argument"
    Then the "quoted argument" string appears as an argument to the step definition

  Scenario: Tables
    Given a table:
      | row 1, column 1 | row 1, column 2 |
      | row 2, column 1 | row 2, column 2 |
    Then row 1, column 1 equals "row 1, column 1"
    And row 1, column 2 equals "row 1, column 2"
    And row 2, column 1 equals "row 2, column 1"
    And row 2, column 2 equals "row 2, column 2"

  Scenario: Multiline strings
    Given a multiline string containing
      """
      This is a
      string with multiple
      lines of text
      """
    Then there are 3 lines of text
