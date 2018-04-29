# Rails Active Record Optimistic Locking With Hashes

[![Build Status](https://travis-ci.org/ndbabb/rails-optimistic-locking-with-hashes.svg?branch=master)](https://travis-ci.org/ndbabb/rails-optimistic-locking-with-hashes)

This repo provides an example of a Rails 5 app (API-only) that implements optimistic locking using a cryptographic hash of field data.

## Background

Optimistic locking deals with a scenario where multiple users are editing a record at the same time. When submitting changes to the database, there's a possibility another user or process will make changes to the record in the meantime, which could lead to some undesirable overwriting of data. 😓

Rails provides a way to implement optimistic locking with Active Record by adding a `lock_version` field:

> Active Record supports optimistic locking if the lock_version field is present. Each update to the record increments the lock_version column and the locking facilities ensure that records instantiated twice will let the last one saved raise a StaleObjectError if the first was also updated

Read more in the [Rails API docs][1].

## An Approach With Cryptographic Hashes

In this example, we're taking an alternative approach using cryptographic hashes instead Rail's `lock_version` counter. Each version of a record's data is computed as a [SHA256][4] hash (fingerprint). When a user or process submits changes to a record, a check is made against the latest data in the database.

The behavior is added to an Active Record class using a [concern][5] called [Lockable][2].

To implement on an Active Record class, we include our custom [Lockable][2] module:

```ruby
class Person < ApplicationRecord
  include Lockable
  
  # [...]
end
```

How it works:

```ruby
p1 = Person.find(1)
p2 = Person.find(1)

p1.first_name = "Caleb"
p1.save

p2.first_name = "should fail"
p2.save # Raises an ActiveRecord::StaleObjectError
```

By default, the SHA256 hash is computed with all fields except `created_at` and `updated_at`. To exclude more fields (e.g. counter caches or other fields with data not directly updated by users), override the method `fingerprint_excluded_fields` which returns an array of symbols, e.g.

```ruby
def fingerprint_excluded_fields
  [:items_count]
end
```

See the [Person][3] class for a working example.

## Using in an JSON API

For a typical frontend consuming the API, the `lock_fingerprint` attribute is passed along with a record, and then passed back during an update (PUT request). E.g. `GET /people/1` looks like:

```JSON
{
  "id": 1,
  "first_name": "Bob",
  "last_name": "Smith",
  "created_at": "2018-04-29T16:41:43.837Z",
  "updated_at": "2018-04-29T16:41:43.837Z",
  "items_count": 0,
  "lock_fingerprint": "ae36ad85b223c46ec9ab7ca2e904724ed04933770b1fc35bfb190756f2435851"
}
```

During the `PUT /people/1` request to update the record, the same `lock_fingerprint` field and value is passed back and the Lockable module checks it against the latest data in the DB. In this API example, a failed check results in the API responding with `422 Unprocessable Entity` HTTP response code. See the [PeopleController][6] class and [ApiExceptionHandler][7] module, and a test to demonstrate it in [People Request Spec][8].

## Advantages / Disadvantages

Some advantages of this approach over Rail's lock_version technique: 1) other processes (e.g. outside of Rails) can directly manipulate data and it works as expected, and 2) no additional DB field needed for `lock_version`, 3) we deal with actual data to determine conflicts that result in a StaleObject error, as opposed to `lock_version` which is a proxy/approximation. E.g. with the hash approach, two users who make identical edits will not lead to a StaleObject error.

Some disadvantages: 1) Overhead in computing the hash and additional queries on the DB, 2) the need to maintain list of field exclusions, 3) diverting from the standard Rails approach.

I would recommend going with the Rails `lock_fingerprint` approach unless one of these advantages jump out at you for your particular use-case. 

## Future Possibilities

1. Add fingerprint check on destroy as well? (This is the behavior of Rails `lock_version`)

2. Instead of raising `ActiveRecord::StaleObjectError`, could be an Active Record validation error.

3. Store `lock_fingerprint` attribute as a field in the DB. Some performance advantages here, RE: less (re)computing of the hash, less data transmitted when checking current DB record.

[1]: http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html
[2]: app/models/concerns/lockable.rb
[3]: app/models/person.rb
[4]: https://en.wikipedia.org/wiki/SHA-2
[5]: http://api.rubyonrails.org/v5.1/classes/ActiveSupport/Concern.html
[6]: app/controllers/people_controller.rb
[7]: app/controllers/concerns/api_exception_handler.rb
[8]: spec/requests/people_spec.rb
