Feature: Wire Protocol
  In order to touch iOS and Mac applications in intimate places
  As an Apple developer
  I want to utilise the low-level Cucumber wire protocol to run steps within my application

  Scenario: Quoted arguments
    When my scenario includes some "quoted argument"
    Then the "quoted argument" string appears as an argument to the step definition

