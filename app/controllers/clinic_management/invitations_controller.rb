module ClinicManagement
  class InvitationsController < ApplicationController
    before_action :set_invitation, only: %i[ show edit update destroy ]
    include GeneralHelper

    # GET /invitations
    def index
      @invitations = Invitation.all.includes(:lead, :region, appointments: :service).order(created_at: :desc).page(params[:page]).per(30)
      if @invitations.present?
        @rows = process_invitations_data(@invitations)
      else
        @rows = ""
      end
    end
    
    

    # GET /invitations/1
    def show
    end

    # GET /invitations/new
    def new
      @services = Service.all    
      @regions = Region.all
      @invitation = Invitation.new
      @appointment = @invitation.appointments.build
      @lead = @invitation.build_lead
      @referrals = Referral.all    
    end

    # GET /invitations/1/edit
    def edit
    end

    def create
      begin
        ActiveRecord::Base.transaction do
          @lead = Lead.create!(invitation_params[:lead_attributes])
          @invitation = @lead.invitations.build(invitation_params.except(:lead_attributes, :appointments_attributes))
          @lead.update!(name: @invitation.patient_name) if @lead.name.blank?
          @appointment = @invitation.appointments.build(invitation_params[:appointments_attributes]["0"].merge({status: "agendado", lead: @lead}))
          @appointment.save!
        end
        render_turbo_stream
      rescue ActiveRecord::RecordInvalid => exception
        render_validation_errors(exception)
      end
    end
    
    def new_patient_fitted
      @service = Service.find(params[:service_id])
      # @services = Service.all    
      @invitation = Invitation.new
      @appointment = @invitation.appointments.build
      @lead = @invitation.build_lead
      @referrals = Referral.all    
    end

    def create_patient_fitted
      begin
        ActiveRecord::Base.transaction do
          @lead = Lead.create!(invitation_params[:lead_attributes])
          @invitation = @lead.invitations.new(invitation_params.except(:lead_attributes, :appointments_attributes))       
          @invitation.region = set_local_region
          @invitation.save
          @lead.update!(name: @invitation.patient_name) if @lead.name.blank?
          @appointment = @invitation.appointments.build(invitation_params[:appointments_attributes]["0"].merge({status: "agendado", lead: @lead}))
          @appointment.save!
        end
        redirect_to @appointment.service
      rescue ActiveRecord::RecordInvalid => exception
        render_validation_errors(exception)
      end
    end

    # PATCH/PUT /invitations/1
    def update
      if @invitation.update(invitation_params)
        redirect_to @invitation, notice: "Invitation was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /invitations/1
    def destroy
      @invitation.destroy
      redirect_to invitations_url, notice: "Invitation was successfully destroyed."
    end

    private

    def set_local_region
      region = Region.find_by(name: "Local")
      unless region.present?
        region = Region.create(name: "Local")
      end
      region
    end

    def render_turbo_stream
      invitation_list_locals = {invitation: @invitation, appointment: @appointment}
      before_attributes = {
        referral: @invitation.referral.id,
        region: @invitation.region.id,
        service: @appointment.service.id,
        date: @invitation.date
      }
      new_form_sets
      new_form_locals = { 
          invitation: @invitation, 
          referrals: Referral.all, 
          regions: Region.all
      }
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("invitations_list", partial: "invitation", locals: invitation_list_locals) +
                               turbo_stream.replace("new_invitation", partial: "form", locals: new_form_locals.merge(before_attributes) ) + 
                               turbo_stream.update("validation", "")
        end
      end
    end
    
    def render_validation_errors(exception)
      validation_content = exception.record.errors.full_messages.join(', ')
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("validation", validation_content)
        end
      end
    end

      def new_form_sets
        @services = Service.all    
        @regions = Region.all
        @invitation = Invitation.new
        @appointment = @invitation.appointments.build
        @lead = @invitation.build_lead
        @referrals = Referral.all
      end

      def process_invitations_data(invitations)
        invitations.map do |invite|
          last_appointment = invite.lead.appointments.last
          [
            {header: "Data", content: invite&.date&.strftime("%d/%m/%Y")},
            {header: "Para", content: helpers.link_to(invite_day(last_appointment), service_path(last_appointment.service), class: "text-blue-500 hover:text-blue-700", target: "_blank" )},
            {header: "Paciente", content: helpers.link_to(invite.patient_name, lead_path(invite.lead), class: "text-blue-500 hover:text-blue-700", target: "_blank")},
            {header: "Responsável", content: responsible_content(invite)},   
            {header: "Telefone", content: invite.lead.phone},
            {header: "Observação", content: invite.notes},
            {header: "Indicação", content: invite.referral.name},
            {header: "Quantidade de convites", content: invite.lead.appointments.count},
            {header: "Região", content: invite.region.name}
          ]
        end
      end

      def set_lead_name
        @services = Service.all    
        @regions = Region.all
        @invitation = Invitation.new
        @appointment = @invitation.appointments.build
        @lead = @invitation.build_lead
        @referrals = Referral.all
      end

      def responsible_content(invite)
        (invite.lead.name != invite.patient_name) ? invite.lead.name : ""
      end
      
      # Use callbacks to share common setup or constraints between actions.
      def set_invitation
        @invitation = Invitation.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def invitation_params
        params.require(:invitation).permit(
          :date,
          :notes,
          :region_id,
          :patient_name,
          :referral_id,
          appointments_attributes: [
            :id,
            :service_id
          ],
          lead_attributes: [
            :name,
            :phone,
            :address
          ]
        )      
      end      
  end
end
