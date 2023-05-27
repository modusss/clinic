module ClinicManagement
  class InvitationsController < ApplicationController
    before_action :set_invitation, only: %i[ show edit update destroy ]
    include GeneralHelper

    # GET /invitations
    def index
      @rows = process_invitations_data(Invitation.all.includes(:lead, :region, appointments: :service).order(date: :desc))
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
    end
    
    

    # GET /invitations/1/edit
    def edit
    end


    def create
      begin
        ActiveRecord::Base.transaction do
          @lead = Lead.create!(invitation_params[:lead_attributes])
          @invitation = Invitation.new(invitation_params.except(:lead_attributes, :appointments_attributes))
          @invitation.lead = @lead
          @invitation.referral = Referral.last
          @invitation.save!
          @lead.name = @invitation.patient_name if @lead.name.blank?
          @lead.save               
          @appointment = @invitation.appointments.build(invitation_params[:appointments_attributes]["0"])
          @appointment.status = "agendado"
          @appointment.lead = @lead
          @appointment.save!
        end
    
        redirect_to @invitation, notice: 'Invitation was successfully created.'
      rescue ActiveRecord::RecordInvalid
        render :new
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

      def process_invitations_data(invitations)
        invitations.map do |invite|
          last_appointment = invite.lead.appointments.last
          [
            {header: "Data", content: invite.date.strftime("%d/%m/%Y")},
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
