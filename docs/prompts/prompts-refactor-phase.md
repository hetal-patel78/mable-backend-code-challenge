# Prompts: review and refactor phase

This file lists the prompts given to the AI assistant (Claude Code, model Claude Opus 5.5) during the review and refactor phase, where the developer gave an instruction or made a decision. It covers the developer's review of the solution after the implementation. Numbering continues from [`prompts-implementation-phase.md`](prompts-implementation-phase.md).

- Prompts are quoted **exactly as typed**, including typos. Where an instruction was given across a discussion rather than typed as one prompt, it is described instead of quoted.
- Prompts that only asked a question, or only asked for a commit, are not included.
- Files attached to a prompt are listed under it rather than quoted.

Back to [project instructions](../../CLAUDE.md).

---

## 1. README

<a id="p27"></a>**P27. Add prerequisites, troubleshooting and how the solution would evolve to the README**

> What I suggest adding a perquisite to the read me so reviewer know the issue if it happen and trouble shooting part as well on how to fix it
>
> I am also suggesting to add some details about
>
> […]
>
> This purely for you reference

Outcome: the [README](../../README.md) gained two sections: [Prerequisites](../../README.md#prerequisites) and [Troubleshooting](../../README.md#troubleshooting). [DEC-37](../design-analysis/design-decisions.md#dec-37) lists them. A section on how the solution would evolve was drafted, then left out ([P29](#p29)).

## 2. Screen report

<a id="p28"></a>**P28. Show each account's opening balance next to its closing balance**

> also  in  regards to in order to check I had to check the balance csv and I am wondering what are the efforts required to add fields Like From Account , Previous Balance, Remaining balance 
>
> This is purely for clarity?
>
> Just tell me the efforts don't start the implementation yet

Attached: the `Final balances` section of the sample report.

Outcome: the `Final balances` section of the screen report shows each account's opening and closing balance as a table ([DEC-26](../design-analysis/design-decisions.md#dec-26)). The output CSV is unchanged.

## 3. README, revised

<a id="p29"></a>**P29. Leave out how the solution would evolve**

> thinking on my ask ask I think we don't need to mentioned how it will evolve. I will keep it for my reference but don't need it to send to the reviewer

Outcome: the README has no section on how the solution would evolve.

## 4. ProcessDailyTransfer

<a id="p30"></a>**P30. Pass ProcessDailyTransfer's dependencies as a parameter object**

> I am reviewing the process daily transfer.rb
> and I cannot easily tell what was happening specially where are using parts array and the reading the dependencies from array. What was ur reasoning to use this approach and not passing the named dependencies itself same as we do in C#.net class constructor. Passing named constructor helps in readability

After the reason was explained (RuboCop's limit on parameters) and named keywords or a parameter object were offered:

> yes I was going to suggest a parameter object same as we do in C#

After the conflict with DEC-30 was raised:

> remove DTOs or mappers from DEC-30.

Outcome: `ProcessDailyTransfer` takes its dependencies as one `ProcessDailyTransfer::Parts`, a parameter object that names each of them, with the run time as a separate keyword. [DEC-30](../design-analysis/design-decisions.md#dec-30) no longer excludes DTOs or mappers.

<a id="p31"></a>**P31. Move log message formatting out of ProcessDailyTransfer**

> I am also seeing 
>
> ProcessDailyTransfer multiple tasks loading balance. It is running the transfer process  and also formatting text for logs. I suggest we move to formatting to method in new helper class and then call it this help ProcessDailyTransfer to focus on single reponsibility
>
> […]

Outcome: `LogMessages` builds the text of every log line of the day's run, masking included, except the all-rejected warning, whose text `DayResult` owns (shared with the report); `ProcessDailyTransfer` decides when to log and at which level.

## 5. Code review: loading, accounts and files

<a id="p32"></a>**P32. Parse each balances field once, read fields by name, and format problem lines in one place**

> Feedback 1
> any reason why we are parsing
> Account.new(number, balance) and Money.balance(text) multiple time in load-balances.rb. what is stopping you from parse once and use it multiple time?
>
> Feedback 2
> reading the row using indexes is hard
> row.fields[1]
> used name based reads
>
> Feedback 3
> I see we are constructing lines for problem at multiple place e.g.
> @problems << "Line #{e.line_number}: #{e.line_problem}"
> Line #{row.line_number}: #{problem}
> I suggest we can write one single function like atline or something similar so that line formatting is done at one place

Outcome: `LoadBalances` parses each row's account number and balance once and builds the account from those values; row fields are read by name; one method gives every "Line n: problem" text.

<a id="p33"></a>**P33. Guard Account against amounts of $0 or less**

> now reviewing account.rb
>
> if some other class call account.rb and pass amount less than 0 to deposit or wihdraw it will work e.g.
>
> if I call deposit(-50) and balanc = 10 then it will set the balance to -40.00 
>
> We should have guard to test for positive amount in account.rb as well and if not then raise and arguemenerror
>
> not a biggy but I also see you are doing balance - money 2 time. just do it onetime by storing in vairable
> @balance = balance - money and then reuse it

Outcome: `Account` raises `ArgumentError` for a deposit or withdrawal of $0 or less, a programming error that never decides a transfer's outcome ([DEC-18](../design-analysis/design-decisions.md#dec-18)); a withdrawal works out the new balance once.

<a id="p34"></a>**P34. Use Ruby `Data` records for values compared by their data**

> reviewing account_numbers.rb i see you have written a custom implementation to check if account number are same or not.
>
> my observation
>
> you added the implmentation for == so that it will compare using actual data and not the object

Attached: the `==` and `eql?` methods of `AccountNumber`.

> if so then why also need to call account.number.to_s in account_repository in every method?
>
> 2nd observation
> Do we not have any equivalent to C# record which compares using data so that we don't have to write the custom implementation

Later:

> also look for any other class that can be converted to Data

Outcome: `AccountNumber`, `Transfer` and `TransferResult` are `Data` records; `Money` keeps its own equality; the repository holds accounts by `AccountNumber` ([DEC-30](../design-analysis/design-decisions.md#dec-30)).

<a id="p35"></a>**P35. Move TransferResult to the application layer**

> reviewed transfer_result.rb
>
> it is storing the line number of the applied and rejected transfers .  I don't see any business rules in this class and so should not be the part of domain. It is purely for storing transfer result and I believe should move to the application folder

Outcome: `TransferResult` is in `lib/application/`, as the application's record of each row's outcome ([DEC-19](../design-analysis/design-decisions.md#dec-19)).

<a id="p36"></a>**P36. Remove requires that are not used**

> no reviewed tranfer-service.rb
> I don't believe we need
> require_relative 'account_repository'
> require_relative 'transfer'

Outcome: each file requires only what it names; `TransferService` requires nothing.

<a id="p37"></a>**P37. Explain and tidy the CSV reading**

> now I am looking at csv-rows.rb
>
> Feedback 1
> why we opening as utf-8 and the reading  csv.to_io.set_encoding(Encoding::BINARY) (raw bytes)?  explain the reason
>
> Feedback 2 - add some comment to explain what it is doing

Attached: the `lines_in` method of `CsvRows`.

> Feedback 3
> There are constants for regex 
>  BLANK = /\A[ \t\r\n]*\z/
>   PADDING = /\A[ \t]+|[ \t]+\z/
>   LINE_BREAK = /\r\n|\r|\n/
> but for header_like regex is used inline
>
> Feedback 4
> rescue exception only when we open the file.

Attached: the `each` method of `CsvRows`.

Outcome: `CsvRows` has comments on its encoding handling and line counting, a named constant for every pattern, and catches system errors only when opening the file and reading it, never in the code that handles each row.

## 6. Solution design

<a id="p38"></a>**P38. Remove repetition from the solution design and add an overview diagram**

> yes please I want one HighLevel diagram and so if anyone interested can look for the split
>
> also while u are doing it I see there was lot of repetition on SD pages - can check for duplicates and verify my observation was correct   we can remove the repetition and keep it one single page.

On the first draft of the overview diagram:

> overview diagram to have about 14 boxes that is lot

On the repeated sample balances table and the starting and opening wording:

> yes lets make it consistent

Then:

> so when u update the SD, desing decision, claudecode.md, readme-  make sure u check against the all the code changes which u will commit before starting the updates

Outcome: each topic in the solution design has one home page, the copies that disagreed are corrected, the documents match the code, and page 5 opens with an overview diagram.

## 7. Money

<a id="p39"></a>**P39. Explain Money's sign and hash handling, check its type and drop comparison**

> looked at money.rb some feedback
> Feedback1
> def negative?
>   @written.to_s.start_with?('-') || value.negative?
> end
>
> add a comment  on why you are doing this
>
>
> Feedback2
> same for 

Attached: the `hash` method of `Money`.

> add comment why calling .hash
> e.g.
> a one-line comment, such as # 0.00 and -0.00 are equal, so they must share a hash.
>
>
> Feedback3
>
> Money.new can accept anything e.g. float or string 
> add a comment that new expects a BigDecimal.
> or Check the type: raise ArgumentError unless value.is_a?(BigDecimal).
>
> Feedback 4 what is the use case of
>  Comparable

After the use of `Comparable` was explained:

> Feedback 4: remove it and implement all feedback 1 to 3
>
> […]

Then:

> also add the comment in other files as where where ever needed and is currently missing

Outcome: `Money`'s sign and hash handling are commented, `Money.new` accepts only a `BigDecimal`, `Money` no longer includes `Comparable`, and code that is not obvious from reading it is commented across `lib/`.
