require File.dirname(__FILE__) + '/../../test_helper'

class EchoTest < Test::Unit::TestCase
  def setup
    @gateway = EchoGateway.new(
                :login => 'LOGIN',
                :password => 'PASSWORD'
               )

    @credit_card = credit_card('4242424242424242')
    @options = {
      :billing_address1 => '10 Main Street',
      :zip => '01000',
      :phone => '555-555-5555',
      :ip => '192.168.0.0',
         }
    @amount = 100
  end
  
  def test_successful_request
    @gateway.expects(:ssl_post).returns(successful_purchase_response_with_avs_and_ccv)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '019186', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(unsuccessful_purchase_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  def test_amount_style
    assert_equal '10.34', @gateway.send(:amount, 1034)
    assert_raise(ArgumentError) do
      @gateway.send(:amount, '10.34')
    end
  end
  
  def test_supported_countries
    assert_equal ['US'], EchoGateway.supported_countries
  end

  def test_supported_card_types
    assert_equal [:visa, :master ], EchoGateway.supported_cardtypes
  end
  
  def test_avs_result
    @gateway.expects(:ssl_post).returns(successful_purchase_response_with_avs_and_ccv)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_equal 'Y', response.avs_result['code']
    assert_equal 'Y', response.avs_result['street_match']
    assert_equal 'Y', response.avs_result['postal_match']
  end
  
  def test_cvv_result
    @gateway.expects(:ssl_post).returns(successful_purchase_response_with_avs_and_ccv)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_equal 'M', response.cvv_result['code']
  end
  
  def successful_purchase_response
    x=<<EOF
    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
    <html><head><title>ECHOnline Response</title></head>
    <body bgcolor="#FFFFFF">
    <!-- <ECHOTYPE1>APPROVED EDS DEPOSITAUTH. NO.     003044AMT.            1.00REFERENCE#  22056967CPG100100701092490391350958</ECHOTYPE1> -->
    <ECHOTYPE2><P><font size=+1><b>Transaction approved</b></font><br><b>Processed by Electronic Clearing House</b><P><style><!-- a:hover{color:#0080FF} --></style><p><table border=1 cellspacing=0><tr><td><font size=+1><b>Authorization and Deposit with Address Verification</b></td></tr><tr><td><table border=0><tr><td valign=bottom><b>Date (Pacific Time)</b></td><td>09/06/2009</td></tr><tr><td valign=bottom><b>Reference Number</b></td><td valign=bottom>22056967</td></tr><tr><td valign=bottom><b>Authorization Code</b></td><td valign=bottom>003044</td></tr><tr><td valign=bottom><b>Security Result</b></td><td valign=bottom>P (The Security Code was not processed.)</td></tr><tr><td valign=bottom><b>Merchant</b></td><td valign=bottom>OUTER LIMITS MEDIA INC</td></tr><tr><td valign=bottom><b>ECHO Order Number&nbsp;&nbsp;&nbsp;</b></td><td valign=bottom>0005-02646-54870</td></tr><tr><td valign=bottom><b>Echo Token Value (ETV)&nbsp;&nbsp;&nbsp;</b></td><td valign=bottom>100100701092490391350958</td></tr><tr><td valign=bottom><b>Amount</b></td><td valign=bottom>$1.00</td></tr></table></td></tr></table><br><b>Please save or print this screen to retain a record of your transaction.</b><P></ECHOTYPE2>

    <!-- <ECHOTYPE3><status>G</status><auth_code>003044</auth_code><security_result>P</security_result><order_number>0005-02646-54870</order_number><echo_reference>22056967</echo_reference><merchant_name>OUTER LIMITS MEDIA INC</merchant_name><tran_amount>1.00</tran_amount><tran_date>09/06/2009</tran_date><ETV>100100701092490391350958</ETV><version>3.26.2019</version></ECHOTYPE3> -->
    </BODY></HTML>
EOF
  end
  
  def unsuccessful_purchase_response
    x=<<EOF
    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
    <html><head><title>ECHOnline Response</title></head>
    <body bgcolor="#FFFFFF">
    <!-- <ECHOTYPE1>INVALID CARD NO     1015</ECHOTYPE1> -->
    <ECHOTYPE2><P><font size=+1><b>Transaction declined</b></font><br><style><!-- a:hover{color:#0080FF} --></style><p><table border=0 cellpadding=0 cellspacing=0><tr><td><font size=+1><b>Authorization and Deposit with Address Verification&nbsp;&nbsp;</td></tr><tr><td><hr></td></tr><tr><td>The card number was invalid.&nbsp;&nbsp;</td></tr><tr><td><hr></td></tr></table><p><b>Processed by Electronic Clearing House</b><P></ECHOTYPE2>
    <!-- <ECHOTYPE3><status>D</status><auth_code>1015</auth_code><decline_code>1015</decline_code><order_number>0005-02646-54776</order_number><merchant_name>OUTER LIMITS MEDIA INC</merchant_name><tran_amount>1.00</tran_amount><tran_date>09/06/2009</tran_date><ETV>100100701092490391350388</ETV><version>3.26.2019</version></ECHOTYPE3> -->
    </BODY></HTML>
EOF
  end
  
  def successful_purchase_response_with_avs_and_ccv
  x=<<EOF
  <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
  <html><head><title>ECHOnline Response</title></head>
  <body bgcolor="#FFFFFF">
  <!-- <ECHOTYPE1>APPROVED EDS DEPOSITAUTH. NO.     019186AMT.            1.00REFERENCE#  22057754VYCMG100100403092490391368003</ECHOTYPE1> -->
  <ECHOTYPE2><P><font size=+1><b>Transaction approved</b></font><br><b>Processed by Electronic Clearing House</b><P><style><!-- a:hover{color:#0080FF} --></style><p><table border=1 cellspacing=0><tr><td><font size=+1><b>Authorization and Deposit with Address Verification</b></td></tr><tr><td><table border=0><tr><td valign=bottom><b>Date (Pacific Time)</b></td><td>09/06/2009</td></tr><tr><td valign=bottom><b>Reference Number</b></td><td valign=bottom>22057754</td></tr><tr><td valign=bottom><b>Authorization Code</b></td><td valign=bottom>019186</td></tr><tr><td valign=bottom><b>AVS Result</b></td><td valign=bottom>Y (Address and ZIP match)</td></tr><tr><td valign=bottom><b>Security Result</b></td><td valign=bottom>M (The Security Code matched.)</td></tr><tr><td valign=bottom><b>Merchant</b></td><td valign=bottom>OUTER LIMITS MEDIA INC</td></tr><tr><td valign=bottom><b>ECHO Order Number&nbsp;&nbsp;&nbsp;</b></td><td valign=bottom>0025-02646-56535</td></tr><tr><td valign=bottom><b>Echo Token Value (ETV)&nbsp;&nbsp;&nbsp;</b></td><td valign=bottom>100100403092490391368003</td></tr><tr><td valign=bottom><b>Amount</b></td><td valign=bottom>$1.00</td></tr></table></td></tr></table><br><b>Please save or print this screen to retain a record of your transaction.</b><P><hr size=3 color=#000080><center><font size=-2 face="Verdana,Arial,Helvetica"> <a href=/ECHONet/Menu.asp>ECHONet Menu</a>  <a href=mailto:webmaster@echo-inc.com>Feedback</a>  <a href=/Common/LogOut.asp>Logout</a> </font></center></ECHOTYPE2>

  <!-- <ECHOTYPE3><status>G</status><auth_code>019186</auth_code><avs_result>Y</avs_result><security_result>M</security_result><order_number>0025-02646-56535</order_number><echo_reference>22057754</echo_reference><merchant_name>OUTER LIMITS MEDIA INC</merchant_name><tran_amount>1.00</tran_amount><tran_date>09/06/2009</tran_date><ETV>100100403092490391368003</ETV><version>3.26.2021</version></ECHOTYPE3> -->
  </BODY></HTML>
EOF
  
  end
  
end
