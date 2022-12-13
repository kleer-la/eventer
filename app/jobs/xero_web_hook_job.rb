class XeroWebHookJob < ActiveJob::Base
  
  queue_as :default

  def initialize(xero_client = nil)
    super
    @xero_client = xero_client || XeroClientService.create_xero
  end
# ccb1c26d-0113-47e2-826e-a9b1429b1a78 unpaid
# 6f352e28-585f-4ccd-a952-560a8f0e5af0 paid // AmountPaid
# a61366ff-a7f3-4da2-9a4e-01bc9c54ef9e // status VOIDED
# 
# hook{"events":[{
#    "resourceUrl": "https://api.xero.com/api.xro/2.0/Invoices/ccb1c26d-0113-47e2-826e-a9b1429b1a78",
#      "resourceId": "ccb1c26d-0113-47e2-826e-a9b1429b1a78",
#      "tenantId": "6acd215c-fade-488f-81cb-d861052c46e8",
#      "tenantType": "ORGANISATION",
#      "eventCategory": "INVOICE",
#      "eventType": "UPDATE",
#      "eventDateUtc": "2022-12-07T17:32:56.478"
#    }],"firstEventSequence": 1,"lastEventSequence": 1, "entropy": "RJMDNODUDRNVADNQUWVC"}

def perform(data)
    # runner = XeroApiRunner.new('Automatización desde Xero')

    # ret_val = runner.execute do |api_run|
      data['events'].each do |event|
p ">>>>>>>>>>>>>>> #{event}"

        next if event['tenantId'] != @xero_client.tenant_id

        if invoice_update?(event)
          p "---------  #{event['resourceId']}"
          ParticipantsController.update_payment_status(event['resourceId'], @xero_client)
        else
          # api_run.log_message('Saliendo por tipo de evento no procesado')
        end
      end
    # end

    # raise 'Internal error processing webhook handler' unless ret_val
  end

  private

  def invoice_update?(event)
    event['eventCategory'] == 'INVOICE' && event['eventType'] == 'UPDATE'
  end

end
