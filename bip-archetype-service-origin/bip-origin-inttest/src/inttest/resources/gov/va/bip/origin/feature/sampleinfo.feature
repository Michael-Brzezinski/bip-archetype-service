Feature: PID based SampleInfo derived from the partner service.

  @sampleinfo @happypath
  Scenario Outline: PID based SampleInfo derived from the partner service for valid PID.
    Given the claimant is a "<Veteran>"
    And invoke token API by passing header from "<tokenrequestfile>" and sets the authorization in the header
    When client request SampleInfo "<ServiceURL>" with PID data "<RequestFile>"
    Then the service returns status code = 200
    And the service returns ParticipantID PID based on participantId <participantID>

    @DEV
    Examples: 
      | Veteran           | tokenrequestfile               | ServiceURL          | RequestFile               | participantID |
      | dev-janedoe       | dev/janedoetoken.request       | /api/v1/origin/pid | dev/janedoe.request       |       6666345 |
      | dev-russellwatson | dev/russellwatsontoken.request | /api/v1/origin/pid | dev/russellwatson.request |      13364995 |

    @VA
    Examples: 
      | Veteran          | tokenrequestfile              | ServiceURL          | RequestFile              | participantID |
      | va-janedoe       | va/janedoetoken.request       | /api/v1/origin/pid | va/janedoe.request       |       6666345 |
      | va-russellwatson | va/russellwatsontoken.request | /api/v1/origin/pid | va/russellwatson.request |      13364995 |

  @sampleinfo
  Scenario Outline: PID based SampleInfo from the partner service for valid PID.
    Given the claimant is a "<Veteran>"
    When client request SampleInfo "<ServiceURL>" with PID data "<RequestFile>"
    Then the service returns status code = 401
    And the service returns content type "<Type>"

    @DEV
    Examples: 
      | Veteran     | tokenrequestfile         | ServiceURL          | RequestFile         | participantID | Type                     |
      | dev-janedoe | dev/janedoetoken.request | /api/v1/origin/pid | dev/janedoe.request |       6666345 | application/problem+json |

    @VA
    Examples: 
      | Veteran    | tokenrequestfile        | ServiceURL          | RequestFile        | participantID | Type                     |
      | va-janedoe | va/janedoetoken.request | /api/v1/origin/pid | va/janedoe.request |       6666345 | application/problem+json |

  @sampleinfo
  Scenario Outline: PID based SampleInfo derived from the partner service for incorrect PID.
    Given the claimant is a "<Veteran>"
    And invoke token API by passing header from "<tokenrequestfile>" and sets the authorization in the header
    When client request SampleInfo "<ServiceURL>" with PID data "<RequestFile>"
    Then the service returns status code = 400
    And the service returns message "<Text>"
    And the service returns content type "<Type>"

    @DEV
    Examples: 
      | Veteran           | tokenrequestfile               | ServiceURL          | RequestFile         | Text                                           | Type                     |
      | dev-janedoe       | dev/janedoetoken.request       | /api/v1/origin/pid | dev/invalid.request | Participant ID must be greater than zero.       | application/problem+json |
      | dev-russellwatson | dev/russellwatsontoken.request | /api/v1/origin/pid | dev/null.request    | SampleInfoRequest.participantID cannot be null. | application/problem+json |

    @VA
    Examples: 
      | Veteran          | tokenrequestfile              | ServiceURL          | RequestFile        | Text                                           | Type                     |
      | va-janedoe       | va/janedoetoken.request       | /api/v1/origin/pid | va/invalid.request | Participant ID must be greater than zero.       | application/problem+json |
      | va-russellwatson | va/russellwatsontoken.request | /api/v1/origin/pid | va/null.request    | SampleInfoRequest.participantID cannot be null. | application/problem+json |
