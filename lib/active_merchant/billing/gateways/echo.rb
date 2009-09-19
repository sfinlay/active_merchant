      require 'rexml/document'
      # based on usa_epay.rb

            module ActiveMerchant #:nodoc:
              module Billing #:nodoc:

                class EchoGateway < Gateway
                  # ECHO doesn't have a testing gateway. You need a developer account or test with a live account.
                  URL = 'https://wwws.echo-inc.com/scripts/INR200.EXE' 

                  self.supported_countries = ['US']
                  self.supported_cardtypes = [:visa, :master]
                  self.homepage_url = 'http://www.echo-inc.com/'
                  self.display_name = 'Echo-Inc'
  
                  TRANSACTIONS = {
                    :authorization => 'AV',
                    :purchase => 'EV',
                    :capture => 'DS',
                    :credit => 'CR'
                  }

                  def initialize(options = {})
                    requires!(options, :login)
                    @options = options
                    super
                  end  

                  def authorize(money, credit_card, options = {})
                    post = {}
                    add_amount(post, money)
                    add_credit_card(post, credit_card)        
                    add_customer_details(post, credit_card, options)        
                    commit(:authorization, post)
                  end

                  def purchase(money, credit_card, options = {})
                    post = {}
                    add_amount(post, money)
                    add_credit_card(post, credit_card)        
                    add_customer_details(post, credit_card, options)   
                    commit(:purchase, post)
                  end                       

                  def capture(money, credit_card, authorization, options = {})
                    post = {
                      :authorization => authorization
                    }
                    add_credit_card(post, credit_card)  
                    add_amount(post, money)
                    commit(:capture, post)
                  end
                  
                  def credit(money, credit_card, options = {})
                    post = {}
                    add_credit_card(post, credit_card)
                    add_amount(post, money)  
                    add_customer_details(post, credit_card, options) 
                    add_transaction(post, credit_card, options)
                    commit(:credit, post)
                  end

                  private                       

                  def add_amount(post, money)
                    post[:grand_total] = amount(money)
                  end

                  def add_customer_details(post, credit_card, options)
                    post[:billing_address1] = options[:address]
                    post[:billing_zip] = options[:zip]
                    post[:billing_phone] = options[:phone]
                    post[:billing_ip_address] = options[:ip]
                  end

                  def add_credit_card(post, credit_card)      
                    post[:cc_number]  = credit_card.number
                    post[:cnp_security] = credit_card.verification_value if credit_card.verification_value?
                    post[:ccexp_month]  = format(credit_card.month, :two_digits)
                    post[:ccexp_year] = format(credit_card.year, :two_digits)
                  end
                  
                  def add_transaction(post, credit_card, options)
                    post[:order_number] = options[:order_number]
                    post[:original_amount] = options[:original_amount]
                  end

                  def parse(body)
                    fields = {}
                    body = /.*<ECHOTYPE3>(.*)<\/ECHOTYPE3>.*/.match(body)
                    body = body[0].gsub!("<!-- ",'').gsub!(" -->",'').gsub!("><", ">\n<")
                    body = REXML::Document.new(body)
                    body.root.elements.each do |node|
                      fields[node.name] = node.text
                    end unless body.root.nil?
                    {
                      :status => fields['status'],
                      :auth_code => fields['auth_code'],
                      :ref_num => fields['echo_reference'],
                      :order_num => fields['order_number'],
                      :avs_result => fields['avs_result'],
                      :cvv_result => fields['security_result'],
                      :tran_amount => fields['tran_amount'],
                      :tran_date => fields['tran_date'],
                      :ETV => fields['ETV'],
                    }.delete_if{|k, v| v.nil?}    
                  end

                  def commit(action, parameters)
                    response = parse( ssl_post(URL, post_data(action, parameters)) )
                    Response.new(response[:status] == 'G', message_from(response), response, 
                      :test => @options[:test] || test?,
                      :authorization => response[:auth_code],
                      :cvv_result => response[:cvv_result],
                      :avs_result => { 
                        :code => response[:avs_result]
                      }
                    )        
                  end

                  def message_from(response)
                    if response[:status] == "G"
                      return 'Success'
                    else
                      return 'Unspecified error' if response[:error].blank?
                      return response[:error]
                    end
                  end

                  def post_data(action, parameters = {})
                    parameters[:transaction_type]  = TRANSACTIONS[action]
                    parameters[:merchant_echo_id] = @options[:login]
                    parameters[:merchant_pin] = @options[:password]
                    parameters[:merchant_email] = @options[:merchant_mail]
                    parameters[:debug] = "F"
                    parameters[:order_type] = "S"
                    parameters[:counter] = rand(100000)
                    parameters.collect { |key, value| "#{key}=#{value.to_s}" }.join("&")
                  end
                end
              end
            end
