module Fluent
  class MailRelayOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('mailrelay', self)
    config_param :lrucache_size, :integer, :default => (1024*1024)
    config_param :mynetworks, :array, :default => ['127.0.0.1']

    require 'time'
    require 'lru_redux'
    require 'ipaddr'

    def initialize
      super
      @transactions = LruRedux::ThreadSafeCache.new(@lrucache_size)
    end

    def str2ipaddr(sipaddrs)
      ipaddrs = Array.new()
      sipaddrs.each do |sipaddr|
        ipaddr = IPAddr.new(sipaddr)
        ipaddrs.push(ipaddr)
      end
      ipaddrs
    end

    def configure(conf)
      super
      @mynetworks = str2ipaddr(@mynetworks)
    end

    def start
      super
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      begin
        # Fluentd doesn't guarantee message order
        # For tracking relay of mail, this plugin should buffer logs and sort it by date order.
        messages = sort_messages(chunk.to_enum(:msgpack_each))
        readys = []
        messages.each do |tag, time, record|
          ready, mail_id = push2relaylog(tag, time, record)
          # this plugin does not output relay log until the mail relayed to outer mynetworks.
          # Therefore, if a mail is deferred, the relay log will not be outputed until the mail is bounced or sent.
          if ready
            readys.push([mail_id, tag, time])
          end
        end
        readys.each { |ready|
          mail_id, tag, time = ready
          log = @transactions[mail_id]
          router.emit(tag, time, log.record)
          @transactions.delete(mail_id)
        }
      rescue
        $log.warn 'mailrelay: error write() ', :error=>$!.to_s
        $log.debug_backtrace
      end
    end

    private
    def sort_messages(messages)
      messages = sort_by_time(messages)
    end

    def sort_by_time(messages)
      messages.sort_by do |tag, time, record|
        record[:time]
      end
    end

    def push2relaylog(tag, time, record)
      from = get_fromaddr(record)
      to = get_toaddr(record)
      msgid = get_msgid(record)

      mail_id = from + to + msgid
      $log.warn 'mailrelay: ',  from, ', ', to, ',', msgid, ',', mail_id

      mta = get_mta(record)
      relay_to = get_relay_to(record)
      stat = get_stat(record)
      dsn = get_dsn(record)
      delay = get_delay(record)
      arrived_at_mta = time

      log = nil
      if @transactions.has_key?(mail_id)
        log = @transactions[mail_id]
      else
        log = MailRelayLog.new(from, to, msgid)
        @transactions[mail_id] = log
      end

      log.merge(mta, relay_to, stat, dsn, delay, arrived_at_mta)
      if not relay_to.nil? and not relay_to_mynetworks(relay_to['ip']) or
          stat == 'sent_local'
        return true, mail_id
      end
      return false, mail_id
    end

    def get_fromaddr(record)
      record['from']['from']
    end

    def get_toaddr(record)
      record['to']['to']
    end

    def get_msgid(record)
      record['from']['msgid']
    end

    def get_mta(record)
      record['mta']
    end

    def get_relay_to(record)
      record['to']['relay']
    end

    def get_stat(record)
      record['to']['canonical_status']
    end

    def get_dsn(record)
      record['to']['dsn']
    end

    def get_delay(record)
      record['to']['delay']
    end

    def relay_to_mynetworks(ip)
      @mynetworks.each {|mynetwork|
        if mynetwork.include?(ip)
          return true
        end
      }
      return false
    end
  end
end

class MailRelayLog
  def initialize(from, to, msgid)
    @relay = []
    @status = :init
    @from = from
    @to = to
    @msgid = msgid
    @delay_sum = 0
  end

  def record
    return {
      'from' => @from,
      'to' => @to,
      'msgid' => @msgid,
      'delay_sec_sum' => @delay_sum,
      'relay' => @relay.each {|relay|
        {
          'relay' => relay['relay'],
          'stat' => relay['stat'],
          'dsn' => relay['dsn'],
          'delay' => relay['delay'],
        }
      }
    }
  end

  def merge(mta, relay_to, stat, dsn, delay, arrived_at_mta)
    @relay.push({
                  'mta' => mta,
                  'relay_to' => relay_to,
                  'stat' => stat,
                  'dsn' => dsn,
                  'delay' => delay,
                  'arrived_at_mta' => arrived_at_mta
                })
    dtime = Time.parse(delay)
    if stat =='sent' or stat == 'bounced'
        @delay_sum += (dtime.hour * 60 * 60) + (dtime.min * 60) + (dtime.sec)
    end
  end
end
