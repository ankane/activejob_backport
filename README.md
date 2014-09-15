# Active Job

Active Job backported to Rails 4.0 and 4.1

```ruby
gem 'activejob_backport'
```

And create `config/initializers/active_job.rb` with:

```ruby
ActiveJob::Base.queue_adapter = :inline # default queue adapter
# Adapters currently supported: :backburner, :delayed_job, :qu, :que, :queue_classic,
#                               :resque, :sidekiq, :sneakers, :sucker_punch
```

See [how to use Active Job](http://edgeguides.rubyonrails.org/active_job_basics.html) and the [official repo](https://github.com/rails/rails/tree/master/activejob)
