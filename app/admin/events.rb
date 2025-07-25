# frozen_string_literal: true

ActiveAdmin.register Event do
  menu parent: 'Courses Mgnt'

  permit_params :event_type_id, :date, :finish_date, :registration_ends,
                :capacity, :duration, :start_time, :end_time, :mode,
                :time_zone_name, :place, :address, :city, :country_id,
                :trainer_id, :trainer2_id, :trainer3_id, :visibility_type,
                :currency_iso_code, :list_price, :business_price,
                :enterprise_6plus_price, :enterprise_11plus_price,
                :eb_price, :couples_eb_price, :business_eb_price,
                :eb_end_date, :registration_link, :show_pricing,
                :should_ask_for_referer_code, :should_welcome_email,
                :monitor_email, :banner_text, :banner_type,
                :specific_subtitle, :specific_conditions,
                :cancellation_policy, :extra_script,
                :sepyme_enabled, :is_sold_out, :draft, :cancelled

  Event.attribute_names.each do |attribute|
    filter attribute.to_sym
  end

  scope :all, default: false
  scope 'Current', :visible, default: true

  action_item :view_old_version, only: :index do
    link_to 'Old version', events_path, class: 'button'
  end
  member_action :trainers, method: :get do
    @event_type = EventType.find_by(id: params[:event_type_id])
    trainers = @event_type ? @event_type.trainers : []
    render json: trainers.map { |t| { id: t.id, name: t.name } }
  end

  member_action :cancellation_policy, method: :get do
    @event_type = EventType.find_by(id: params[:event_type_id])
    policy = @event_type&.cancellation_policy
    render json: { policy: }
  end

  controller do
    def scoped_collection
      super.includes(:event_type, :country, :trainer)
    end

    def find_resource # avoid N+1 queries
      Event.includes(
        participants: { influence_zone: :country },
        event_type: {},
        country: {},
        trainer: {}
      ).find(params[:id])
    end
  end

  member_action :download_participants, method: :get do
    event = Event.find(params[:id])
    participants = event.participants.includes(:influence_zone, influence_zone: :country)

    send_data participants.to_comma,
              filename: "participants-#{event.date.strftime('%Y-%m-%d')}-#{event.event_type.name.parameterize}.csv",
              type: 'text/csv'
  end

  member_action :batch_upload, method: :post do
    event = Event.find(params[:id])

    Rails.logger.debug "Batch Upload Params: #{params.inspect}"

    # Access the nested parameters
    batch_upload_params = params[:batch_upload] || {}
    raw_participants = batch_upload_params[:participants_batch]
    status = batch_upload_params[:status]
    influence_zone = InfluenceZone.find(batch_upload_params[:influence_zone_id])

    success_count = 0
    error_count = 0
    error_lines = []

    raw_participants.split("\n").each_with_index do |line, index|
      next if line.blank?

      # Split by comma or tab
      fields = line.split(/[,\t]/).map(&:strip)

      if fields.length < 4
        error_lines << "Line #{index + 1}: Not enough fields"
        error_count += 1
        next
      end

      participant = event.participants.build(
        lname: fields[0],
        fname: fields[1],
        email: fields[2],
        phone: fields[3],
        status:,
        influence_zone:,
        notes: 'Batch load'
      )

      if participant.save
        success_count += 1
      else
        error_count += 1
        error_lines << "Line #{index + 1}: #{participant.errors.full_messages.join(', ')}"
      end
    end

    if error_count.zero?
      redirect_to admin_event_path(event), notice: "Successfully imported #{success_count} participants"
    else
      redirect_to admin_event_path(event),
                  notice: "Imported #{success_count} participants with #{error_count} errors",
                  alert: error_lines.join("\n")
    end
  rescue StandardError => e
    redirect_to admin_event_path(event), alert: "Error processing batch upload: #{e.message}"
  end

  index do
    column :date
    column 'Tipo evento', :event_type do |event|
      event.event_type&.name
    end
    column 'Detalles', :event_type do |event|
      content = []

      if event.country.present?
        content << content_tag(:i, '', class: "flag flag-#{event.country.iso_code.downcase}")
        content << event.city
      end

      time_and_place = [
        event.start_time.strftime('%H:%Mhs.'),
        event.place,
        (event.address unless event.address == 'Online')
      ].compact.join(', ')

      content << content_tag(:br) + time_and_place

      content.join(' ').html_safe
    end
    column 'Visibilidad', :event_type do |event|
      { 'pu' => 'Publico', 'pr' => 'Privado', 'co' => 'Comunidad' }[event.visibility_type]
    end
    column :draft
    column :cancelled
    column :is_sold_out
    actions defaults: false do |event|
      item link_to('Participantes', admin_event_path(event))
      text_node ' | '
      item link_to('Editar', edit_admin_event_path(event))
      text_node ' | '
      item link_to('Copiar', copy_event_path(event))
    end
  end

  show do
    tabs do
      tab 'Participants' do
        div class: 'header-with-actions' do
          div class: 'title-section' do
            h2 "#{event.date.to_formatted_s(:short)} - #{event.city}", style: 'margin: 0; display: inline-block;'
          end
          div class: 'action-section', style: 'display: inline-block;' do
            span style: 'margin: 0 5px;' do
              link_to 'Download CSV', download_participants_admin_event_path(event, format: 'csv'),
                      class: 'button-default'
            end
            span style: 'margin: 0 5px;' do
              link_to 'Generate Certificates',
                      "/events/#{event.id}/send_certificate",
                      # send_certificate_event_path(event),
                      class: 'button-default',
                      data: {
                        confirm: "¡Atención!

Esta operación enviará certificados de asistencia SOLO a las #{event.attended_quantity + event.certified_quantity} personas  que están 'Presente' o 'Certificados'.
Antes de seguir, asegúrate que el evento ya haya finalizado, que las personas que participaron estén marcadas como 'Presente' y que quienes estuvieron ausentes estén marcados como 'Postergado' o 'Cancelado'.
"
                      }
            end
            span style: 'margin: 0 5px;' do
              link_to 'Generate Certificates with HR Notification',
                      "#",
                      class: 'button-default',
                      id: 'hr-certificate-btn',
                      onclick: "showHRForm(#{event.id}); return false;"
            end
          end
        end

        panel 'Event Statistics', class: 'stats-panel' do
          div class: 'stat-columns' do
            div class: 'stat-item' do
              span "Completion: #{(event.completion * 100).round}%"
              br
              span "#{event.seat_available} seats remaining"
            end

            div class: 'stat-item' do
              span 'New'
              br
              span event.new_ones_quantity
            end

            div class: 'stat-item' do
              span 'Contacted'
              br
              span event.contacted_quantity
            end

            div class: 'stat-item' do
              span 'Confirmed'
              br
              span event.confirmed_quantity
            end

            div class: 'stat-item' do
              span 'Present'
              br
              span event.attended_quantity
            end
          end
        end

        render partial: '/admin/events/participants_panel', locals: { event: }
      end

      tab 'Event Details' do
        attributes_table do
          row :event_type
          row :date
          row :finish_date
          row :registration_ends
          row :capacity
          row :duration
          row :start_time
          row :end_time
          row :mode
          row :time_zone_name
          row :place
          row :address
          row :city
          row :country
          row :trainer
          row :trainer2
          row :trainer3
          row :visibility_type
          row :currency_iso_code
          row :list_price
          row :business_price
          row :enterprise_6plus_price
          row :enterprise_11plus_price
        end
      end
      tab 'Batch Upload' do
        panel 'Batch Upload Participants' do
          influence_zones = InfluenceZone.includes(:country)
                                         .order('countries.name, influence_zones.zone_name')
                                         .map { |z| [z.display_name, z.id] }

          active_admin_form_for :batch_upload, url: batch_upload_admin_event_path do |f|
            f.inputs do
              f.input :participants_batch, as: :text,
                                           label: 'Participants (one per line)',
                                           input_html: {
                                             rows: 10,
                                             placeholder: 'Smith, John, john.smith@example.com, +1234567890'
                                           }

              f.input :status, as: :select,
                               collection: Participant.status_collection_for_select,
                               label: 'Status'

              f.input :influence_zone_id, as: :select,
                                          collection: influence_zones,
                                          label: 'Influence Zone'
            end

            f.actions do
              f.action :submit, label: 'Upload Participants'
              f.action :cancel, label: 'Cancel'
            end
          end
        end
      end
    end
    
    # HR Certificate Notification Form
    div id: 'hr-form-overlay', style: 'display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000;' do
      div style: 'position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.3); width: 90%; max-width: 600px;' do
        h3 'Send Certificates with HR Notification'
        
        form method: 'post', id: 'hr-certificate-form', style: 'margin-top: 20px;' do
          input type: 'hidden', name: 'authenticity_token', value: form_authenticity_token
          
          div style: 'margin-bottom: 20px;' do
            label 'HR Email Addresses (separate with commas, semicolons, or new lines):', 
                  style: 'display: block; margin-bottom: 8px; font-weight: bold;'
            textarea name: 'hr_emails', 
                     placeholder: 'hr@company.com, manager@company.com',
                     style: 'width: 100%; height: 80px; padding: 8px; border: 1px solid #ddd; border-radius: 4px; resize: vertical; box-sizing: border-box;'
          end
          
          div style: 'margin-bottom: 20px;' do
            label 'HR Message (optional):',
                  style: 'display: block; margin-bottom: 8px; font-weight: bold;'
            textarea name: 'hr_message',
                     placeholder: 'Add a custom message from HR that will be included in the certificate email...',
                     style: 'width: 100%; height: 100px; padding: 8px; border: 1px solid #ddd; border-radius: 4px; resize: vertical; box-sizing: border-box;'
          end
          
          div style: 'margin-bottom: 20px; padding: 15px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px;' do
            strong 'Note: '
            span 'This will send individual certificate emails to each participant marked as "Present" or "Certified", with HR emails included as CC recipients.'
          end
          
          div style: 'text-align: right;' do
            button type: 'button', 
                   onclick: 'hideHRForm()',
                   style: 'margin-right: 10px; padding: 10px 20px; background: #6c757d; color: white; border: none; border-radius: 4px; cursor: pointer;' do
              'Cancel'
            end
            button type: 'submit',
                   onclick: "return confirm('Are you sure you want to send certificates with HR notification?')",
                   style: 'padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;' do
              'Send Certificates with HR CC'
            end
          end
        end
      end
    end

    # JavaScript for HR Certificate Form
    script type: 'text/javascript' do
      raw <<~JS
        function showHRForm(eventId) {
          document.getElementById('hr-form-overlay').style.display = 'block';
          document.getElementById('hr-certificate-form').action = '/events/' + eventId + '/send_certificate_with_hr';
        }
        
        function hideHRForm() {
          document.getElementById('hr-form-overlay').style.display = 'none';
        }
        
        // Close modal when clicking outside
        document.addEventListener('DOMContentLoaded', function() {
          document.getElementById('hr-form-overlay').addEventListener('click', function(e) {
            if (e.target === this) {
              hideHRForm();
            }
          });
        });
      JS
    end
  end

  form do |f|
    f.semantic_errors
    script do
      raw <<~JS
          $(document).ready(function() {
            function updateDates(selectedDate) {
              const $finishDate = $('#event_finish_date');
              const $registrationEnds = $('#event_registration_ends');
              const $ebEndDate = $('#event_eb_end_date');
              if (!$finishDate.val()) {
                $finishDate.val(selectedDate);
              }
              if (!$registrationEnds.val()) {
                $registrationEnds.val(selectedDate);
              }
              // Calculate early bird date (10 days before)
              try {
                const eventDate = new Date(selectedDate);
                const ebDate = new Date(eventDate);
                ebDate.setDate(eventDate.getDate() - 14);
                // Format date as YYYY-MM-DD
                const ebFormatted = ebDate.toISOString().split('T')[0];
                $ebEndDate.val(ebFormatted);
              } catch (e) {
                console.error('Error calculating dates:', e);
              }
            }

            // Initialize date handling
            function initializeDateHandling() {
              const $dateInput = $('#event_date');
              $dateInput.off('.eventHandlers');// Remove any existing handlers
              $dateInput.on('change.eventHandlers', function() {
                updateDates(this.value);// Add new handlers
              });

              // Monitor ActiveAdmin datepicker
              const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                  if (mutation.type === 'attributes' && mutation.attributeName === 'value') {
                    const newValue = $dateInput.val();
                    updateDates(newValue);
                  }
                });
              });
              observer.observe($dateInput[0], {
                attributes: true,
                attributeFilter: ['value']
              });
            }
            // Initialize after a delay to ensure ActiveAdmin is ready
            setTimeout(initializeDateHandling, 500);

          function handleOnlineMode() {
            const $modeSelect = $('#event_mode');
            const $timeZoneInput = $('#event_time_zone_name_input');
            const $cityInput = $('#event_city');
            const $addressInput = $('#event_address');
            const $countrySelect = $('#event_country_id');

            if ($modeSelect.val() === 'ol') {
              $cityInput.val('Online').prop('readonly', true);
              $addressInput.val('Online').prop('readonly', true);
              $countrySelect.val("1").trigger('change.select2');
              // Disable select2 but ensure the value persists
              $countrySelect.select2('enable', false);
              // Add a hidden input to ensure the value is submitted
              if ($('#online_country_hidden').length === 0) {
                $('<input type="hidden" id="online_country_hidden" name="event[country_id]" value="1">').insertAfter($countrySelect);
              }
              $timeZoneInput.show();
            } else {
              $cityInput.prop('readonly', false);
              $addressInput.prop('readonly', false);
              $countrySelect.select2('enable', true);
              // Remove the hidden input when not online
              $('#online_country_hidden').remove();
              $timeZoneInput.hide();
            }
          }

          function handleTimezoneChange() {
            const $timezoneSelect = $('#event_time_zone_name');
            const $placeInput = $('#event_place');
            const $modeSelect = $('#event_mode');

            $timezoneSelect.on('change', function() {
              if ($modeSelect.val() === 'ol') {
                // Get the selected timezone text
                const selectedTimezone = $(this).find('option:selected').text();
                // Update the place field with the timezone description
                $placeInput.val(selectedTimezone);
              }
            });
          }

          // Initial setup with delay for ActiveAdmin
          setTimeout(function() {
            const $modeSelect = $('#event_mode');
            // Bind using jQuery on() for better event delegation
            $modeSelect.on('change', function() {
              handleOnlineMode();
            });

            // Initial call
            handleTimezoneChange();
            handleOnlineMode();
          }, 500);
          });

        document.addEventListener('DOMContentLoaded', function() {
          function handleVisibilityChange() {
            const visibilityType = document.querySelector('input[name="event[visibility_type]"]:checked');
            const pricesSection = document.querySelector('fieldset.inputs:has(#event_list_price)');

            if (!visibilityType || !pricesSection) return;

            const priceFields = pricesSection.querySelectorAll('input[type="number"]');

            if (visibilityType.value === 'pr') {
              priceFields.forEach(field => {
                if (field.id !== 'event_list_price') {
                  field.disabled = true;
                  field.value = '';
                }
              });
              pricesSection.style.display = 'block';
            } else if (visibilityType.value === 'co') {
              pricesSection.style.display = 'none';
              const listPrice = document.getElementById('event_list_price');
              if (listPrice) listPrice.value = '0';
            } else {
              priceFields.forEach(field => field.disabled = false);
              pricesSection.style.display = 'block';
            }
          }

          function calculateDiscounts() {
            const listPrice = parseFloat(document.getElementById('event_list_price')?.value) || 0;
            const isPrivate = document.querySelector('input[value="pr"]')?.checked;

            if (!isPrivate) {
              const fields = {
                'event_eb_price': 0.95,
                'event_couples_eb_price': 0.90,
                'event_business_price': 0.88,
                'event_business_eb_price': 0.85,
                'event_enterprise_6plus_price': 0.83,
                'event_enterprise_11plus_price': 0.80
              };

              Object.entries(fields).forEach(([id, multiplier]) => {
                const element = document.getElementById(id);
                if (element) {
                  element.value = Math.ceil(listPrice * multiplier);
                }
              });
            }
          }
            // Set up all event listeners after a delay
          setTimeout(function() {

            // Setup visibility handling
            const visibilityRadios = document.querySelectorAll('input[name="event[visibility_type]"]');
            visibilityRadios.forEach(radio => {
              radio.addEventListener('change', handleVisibilityChange);
            });

            // Setup price handling
            const listPriceInput = document.getElementById('event_list_price');
            if (listPriceInput) {
              listPriceInput.addEventListener('change', calculateDiscounts);
              listPriceInput.addEventListener('input', calculateDiscounts);
            }

            // Initial setup
            handleVisibilityChange();
          }, 100);
        });
      JS
    end
    script do
      raw <<~JS
        $(document).ready(function() {
          const eventTypeSelect = $('#event_event_type_id');
          const trainerSelects = {
            trainer1: $('#event_trainer_id'),
            trainer2: $('#event_trainer2_id'),
            trainer3: $('#event_trainer3_id')
          };
          const cancellationPolicyField = $('#event_cancellation_policy');

          function updateTrainers(eventTypeId) {
            if (!eventTypeId) return;

            $.get('/admin/events/' + #{resource.id || 0} + '/trainers', { event_type_id: eventTypeId })
              .done(function(trainers) {
                // Update all trainer selects
                Object.values(trainerSelects).forEach($select => {
                  const currentValue = $select.val();
                  $select.empty();
                  $select.append('<option value="">Select trainer...</option>');

                  trainers.forEach(trainer => {
                    $select.append(
                      $('<option></option>')
                        .val(trainer.id)
                        .text(trainer.name)
                    );
                  });

                  // Restore selected value if it still exists in new options
                  if (currentValue && trainers.some(t => t.id.toString() === currentValue)) {
                    $select.val(currentValue);
                  }
                });

                validateTrainerSelections();
              });
          }

          function updateCancellationPolicy(eventTypeId) {
            if (!eventTypeId) return;

            const cancellationPolicyField = $('#event_cancellation_policy');
            if (!cancellationPolicyField.length) {
              console.log('Cancellation policy field not found');
              return;
            }

            if (cancellationPolicyField.val().trim() === '') {
              $.get('/admin/events/' + #{resource.id || 0} + '/cancellation_policy', { event_type_id: eventTypeId })
                .done(function(data) {
                  if (data.policy) {
                    cancellationPolicyField.val(data.policy);
                  } else {
                    console.log('No policy data received');
                  }
                })
                .fail(function(jqXHR, textStatus, errorThrown) {
                  console.error('Failed to fetch policy:', textStatus, errorThrown);
                });
            }
          }

          function validateTrainerSelections() {
            // Clear previous validations
            Object.values(trainerSelects).forEach($select => {
              $select.closest('.input').removeClass('error');
              $select.closest('.input').find('.inline-errors').remove();
            });

            const selectedTrainers = new Set();
            let hasError = false;

            Object.entries(trainerSelects).forEach(([key, $select]) => {
              const value = $select.val();
              if (!value) return;

              // Check for duplicates
              if (selectedTrainers.has(value)) {
                $select.closest('.input').addClass('error')
                      .append('<p class="inline-errors">This trainer is already selected</p>');
                hasError = true;
              }
              selectedTrainers.add(value);

              // Check for proper order (can't have trainer2 without trainer1, etc.)
              if (key === 'trainer2' && !trainerSelects.trainer1.val()) {
                $select.closest('.input').addClass('error')
                      .append('<p class="inline-errors">Cannot select second trainer without first trainer</p>');
                hasError = true;
              }
              if (key === 'trainer3' && !trainerSelects.trainer2.val()) {
                $select.closest('.input').addClass('error')
                      .append('<p class="inline-errors">Cannot select third trainer without second trainer</p>');
                hasError = true;
              }
            });

            return !hasError;
          }

          // Event handlers
          eventTypeSelect.on('change', function() {
            const eventTypeId = $(this).val();
            updateTrainers(eventTypeId);
            updateCancellationPolicy(eventTypeId);
          });

          Object.values(trainerSelects).forEach($select => {
            $select.on('change', validateTrainerSelections);
          });

          // Initialize if event type is already selected
          if (eventTypeSelect.val()) {
            updateTrainers(eventTypeSelect.val());
            updateCancellationPolicy(eventTypeSelect.val());
          }

          // Add form validation
          $('form').on('submit', function(e) {
            if (!validateTrainerSelections()) {
              e.preventDefault();
              alert('Please fix the trainer selection errors before submitting.');
            }
          });
        });
      JS
    end
    f.inputs 'Event Details' do
      f.input :event_type,
              collection: EventType.all,
              include_blank: 'Select one...'

      f.input :date, as: :datepicker,
                     input_html: {
                       autocomplete: 'off',
                       data: {
                         datepicker: true,
                         datepicker_format: 'Y-m-d',
                         onchange: 'handleDateChange()'
                       }
                     }
      f.input :finish_date, as: :datepicker,
                            input_html: {
                              autocomplete: 'off',
                              data: {
                                datepicker: true,
                                datepicker_format: 'Y-m-d'
                              }
                            }
      f.input :registration_ends, as: :datepicker,
                                  input_html: {
                                    autocomplete: 'off',
                                    data: {
                                      datepicker: true,
                                      datepicker_format: 'Y-m-d'
                                    }
                                  }
      f.input :capacity
      f.input :duration
      f.input :start_time, as: :time_picker
      f.input :end_time, as: :time_picker
      f.input :mode,
              as: :select,
              collection: [
                ['Classroom', 'cl'],
                ['Online', 'ol'],
                ['Blended Learning', 'bl']
              ],
              include_blank: 'Select one...'
      f.input :time_zone_name,
              as: :select,
              collection: ActiveSupport::TimeZone.all.map { |tz| [tz.to_s, tz.name] },
              include_blank: 'Select one...'
    end

    f.inputs 'Location' do
      f.input :place
      f.input :address
      f.input :city
      f.input :country
    end

    f.inputs 'Staff' do
      f.input :trainer
      f.input :trainer2
      f.input :trainer3
    end
    f.inputs 'Visibility & Pricing' do
      f.input :visibility_type,
              as: :radio,
              collection: [
                %w[Public pu],
                %w[Private pr],
                %w[Community co]
              ]

      f.input :currency_iso_code,
              as: :select,
              collection: Money::Currency.all.map { |c| ["#{c.iso_code} - #{c.name}", c.iso_code] },
              selected: 'USD'

      f.input :list_price
      f.input :business_price
      f.input :enterprise_6plus_price
      f.input :enterprise_11plus_price

      f.input :eb_price, label: 'Early Bird Price'
      f.input :couples_eb_price, label: 'Couples Early Bird Price'
      f.input :business_eb_price, label: 'Business Early Bird Price'
      f.input :eb_end_date, as: :datepicker, label: 'Early Bird End Date',
                            input_html: {
                              autocomplete: 'off',
                              data: {
                                datepicker: true,
                                datepicker_format: 'Y-m-d'
                              }
                            }
    end

    f.inputs 'Registration' do
      f.input :registration_link, as: :url
      f.input :show_pricing
      f.input :should_ask_for_referer_code
      f.input :should_welcome_email
      f.input :monitor_email
    end

    f.inputs 'Additional Information' do
      f.input :banner_text, as: :text
      f.input :banner_type,
              as: :select,
              collection: [
                ['Info (blue)', 'info'],
                ['Success (green)', 'success'],
                ['Warning (yellow)', 'warning'],
                ['Danger (red)', 'danger']
              ],
              include_blank: 'Select one...'

      f.input :specific_subtitle
      f.input :specific_conditions, as: :text
      f.input :cancellation_policy, as: :text
      f.input :extra_script, as: :text
    end

    f.inputs 'Status' do
      f.input :sepyme_enabled
      f.input :is_sold_out
      f.input :draft
      f.input :cancelled
    end

    f.actions
  end
end
