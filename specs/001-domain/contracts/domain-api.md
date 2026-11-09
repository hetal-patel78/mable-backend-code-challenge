# Contract: the domain's public members

The members `002-file-runner` (and this spec's own specs) may call, with their arguments, results and errors. Anything not listed here is private. Names follow [page 6](../../../docs/solution-design/06-components.md) and the [page 10 glossary](../../../docs/solution-design/10-traceability-glossary-assumptions.md#glossary); the members those pages leave open are decided in the [plan](../plan.md#decided-in-the-run). Every message is copied character for character from the [spec's message table](../spec.md#domain-error-messages).

Inputs are text already trimmed by the readers (`002`); the domain does not trim.

## Loading

Code files are under `lib/domain/` and load their own dependencies. A caller requires the file of each class it uses, with `lib/` on the load path, for example `require 'domain/transfer_service'` (plan D13).

| File | Defines |
|---|---|
| `domain/errors` | the seven errors |
| `domain/account_number` | `AccountNumber` |
| `domain/money` | `Money` |
| `domain/account` | `Account` |
| `domain/transfer` | `Transfer` |
| `domain/transfer_result` | `TransferResult` |
| `domain/account_repository` | `AccountRepository` |
| `domain/transfer_service` | `TransferService` |

## Members

| Call | Returns | Raises, with the exact message |
|---|---|---|
| `AccountNumber.new(text)` or `AccountNumber.new(text:)` | an `AccountNumber`, a `Data` record | `InvalidAccountNumber`: `account number "<text>" must be exactly 16 digits` |
| `account_number.text`, `account_number.to_s` | the full text | |
| `account_number == other` | true when the text is equal (`eql?` and `hash` too, from `Data`; plan.md D23) | |
| `Money.amount(text)` | a `Money` | `InvalidAmount`: `amount is empty`; `amount "<text>" has more than 2 decimal places`; `amount "<text>" is not a valid amount` |
| `Money.balance(text)` | a `Money` | `InvalidAmount`: `balance is empty`; `balance "<text>" has more than 2 decimal places`; `balance "<text>" is not a valid amount` |
| `money.to_s` | text with exactly 2 decimals, for example `7.50` | |
| `money.text` | the text as written, for example `007.50` | |
| `money + other`, `money - other` | a new `Money` | |
| `money <=> other`, `==`, `<`, `>` | by value | |
| `money.negative?`, `money.positive?` | Boolean | |
| `Account.check_opening_balance(balance)` | nil | `NegativeBalance`: `balance "<text>" must not be negative` |
| `Account.new(number, balance)` | an `Account` | `NegativeBalance` as above |
| `account.number`, `account.balance` | `AccountNumber`, `Money` | |
| `account.withdraw(money)` | | `ArgumentError`: `amount <amount> must be greater than 0.00` for an amount of $0 or less (a programming error; plan D24); `InsufficientFunds`: `account <number> cannot pay <amount> from a balance of <balance>` |
| `account.deposit(money)` | | never for an amount above $0; `ArgumentError` as for `withdraw` otherwise |
| `Transfer.new(from:, to:, amount:)` | a `Transfer` | `InvalidAmount`: `amount "<text>" must be greater than 0.00`; then `SameAccount`: `account <number> cannot transfer to itself` |
| `transfer.from`, `transfer.to`, `transfer.amount` | `AccountNumber`, `AccountNumber`, `Money` | |
| `TransferResult::REASON_CODES` | `[:malformed_row, :invalid_account_number, :invalid_amount, :same_account, :unknown_account, :insufficient_funds]` | |
| `TransferResult.applied(line_number:, fields:)` | a `TransferResult` | |
| `TransferResult.rejected(line_number:, fields:, reason:, header_hint: nil)` | a `TransferResult` | `ArgumentError` for a reason not in `REASON_CODES` |
| `result.line_number`, `result.fields`, `result.reason`, `result.header_hint`, `result.applied?`, `result.rejected?` | as given; `reason` and `header_hint` nil when not set | |
| `AccountRepository.new` | an empty repository | |
| `repository.add(account)` | | `DuplicateAccount`: `account <number> appears more than once` |
| `repository.include?(account_number)` | Boolean | |
| `repository.find(account_number)` | the held `Account` | `UnknownAccount`: `account <number> is not loaded` |
| `repository.all` | the accounts in load order | |
| `TransferService.new(repository)` | a service | |
| `service.apply(transfer)` | nil | `UnknownAccount` (from first, then to); `InsufficientFunds`; both balances unchanged |
| `DuplicateAccount.new(account_number).message` | `account <number> appears more than once` | (the error object, not raised; plan D21) |

In the messages, `<text>` is the value as given, `<number>` the full account number, and `<amount>` and `<balance>` are written with exactly 2 decimal places (`Money#to_s`).

## What the caller does with them (`002`)

- `ProcessDailyTransfer` builds `AccountNumber.new(from)`, `AccountNumber.new(to)`, `Money.amount(amount)` and `Transfer.new(...)` in that order, calls `TransferService#apply`, and maps each error to the reason code in DEC-19; it builds a `TransferResult` per row.
- `LoadBalances` builds `AccountNumber.new`, asks `include?` and, for a held number, takes the duplicate text from `DuplicateAccount.new(number).message`; it builds `Money.balance` and calls `Account.check_opening_balance`, then `Account.new` and `add`. It puts `Line N: ` before each message, and ` (first on line M)` after the duplicate text, without changing the domain text.
- Totals can be added up from `all` with `Money#+`; how is `002`'s choice.
