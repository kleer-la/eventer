class XeroWebHookJob < ActiveJob::Base
  
  queue_as :default

  def initialize(xero_client = nil)
    super
    @xero_client = xero_client || XeroClientService.create_xero
  end

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
        next if event['tenantId'] != @xero_client.tenant_id

        if invoice_update?(event)
          invoice_update event['resourceId'] #, api_run
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

  def invoice_update(invoice_id)
    invoice = @xero_client.get_invoice(invoice_id)
  end

  # def invoice_update(invoice_id, api_run)
  #   api_run.log_message("Processing invoice: #{invoice_id}")

  #   invoice = @xero_client.get_invoice(invoice_id)
  #   if invoice.line_items.count != 1
  #     api_run.log_message('Saliendo invoice.line_items.count != 1')
  #     return
  #   end

  #   if invoice.line_items[0].tracking.count != 1
  #     api_run.log_message('Saliendo invoice.line_items[0].tracking.count != 1')
  #     return
  #   end

  #   tracking = invoice.line_items[0].tracking[0]

  #   history_records = @xero_client.get_invoice_history(invoice_id)
  #   fee_transaction_entries = history_records.select { |hr| hr.changes == 'Transaction Fee' }
  #   if fee_transaction_entries.count != 1
  #     api_run.log_message('Saliendo fee_transaction_entries.count != 1')
  #     return
  #   end

  #   fee_transaction_id = nil
  #   fee_transaction_entries[0].details.match(/bankTransactionID=(.*)"/) do |m|
  #     fee_transaction_id = m.captures[0]
  #   end

  #   if fee_transaction_id.nil?
  #     api_run.log_message('Saliendo fee_transaction_id.nil?')
  #     return
  #   end

  #   api_run.log_message("Processing fee transaction: #{fee_transaction_id}")

  #   fee_transaction = @xero_client.get_bank_transaction(fee_transaction_id)

  #   if fee_transaction.is_reconciled
  #     api_run.log_message('Saliendo fee_transaction no puede modificarse porque está reconciliada')
  #     return
  #   end
  #   if fee_transaction.line_items.count != 1
  #     api_run.log_message('Saliendo fee_transaction.line_items.count != 1')
  #     return
  #   end
  #   if fee_transaction.line_items[0].tracking.count.positive?
  #     api_run.log_message('Saliendo fee_transaction.line_items[0].tracking.count > 0')
  #     return
  #   end

  #   fee_transaction.line_items[0].tracking << tracking

  #   @xero_client.update_bank_transaction(fee_transaction_id, fee_transaction)

  #   api_run.log_message('Transacción de fee actualizada')
  # end
end
