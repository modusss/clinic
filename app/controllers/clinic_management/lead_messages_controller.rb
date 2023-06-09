module ClinicManagement
  class LeadMessagesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_message, only: [:show, :edit, :update, :destroy]
    include GeneralHelper

    def index
      @messages = LeadMessage.all
=begin
      @rows = LeadMessage.all.map.with_index(1) do |mes, index|
        [
          { header: "#", content: index },
          { header: "Nome", content: mes.name },
          { header: "Convites", content: mes.text }
        ] 
      end
=end
    end
  
    def new
      @message = LeadMessage.new
    end
  
    def create
      @message = LeadMessage.new(message_params)
      if @message.save
        redirect_to lead_messages_path, notice: 'Mensagem customizada criada com sucesso.'
      else
        render :new
      end
    end
  
    def show
    end
  
    def edit
    end
  
    def update
      if @message.update(message_params)
        redirect_to lead_messages_path
      else
        render :edit
      end
    end
  
    def destroy
      @message.destroy
      redirect_to lead_messages_path, notice: 'Mensagem customizada excluída com sucesso.'
    end

    def build_message
      begin
        message = LeadMessage.find_by(id: params[:custom_message_id])
        appointment = Appointment.find_by(id: params[:appointment_id])
        add_message_sent(appointment, message.name)
        lead = Lead.find_by(id: params[:lead_id])
        message = get_message(message, lead, appointment)
        render turbo_stream: [
          turbo_stream.append(
            "whatsapp-link-" + lead.id.to_s, 
            partial: "clinic_management/lead_messages/whatsapp_link", 
            locals: { phone_number: lead.phone, message: message }
          ),
          turbo_stream.update(
            "messages-sent-" + appointment.id.to_s, 
            appointment.messages_sent.join(', ')
          )
        ]        
      rescue
      end
    end
  
    private

    # register that this message was sent to this appointment
    def add_message_sent(appointment, name)
      unless appointment.messages_sent.include? name
        appointment.messages_sent << name
        appointment.save
      end
    end

    def get_message(message, lead, appointment)
      result = message.text
      .gsub("{PRIMEIRO_NOME_PACIENTE}", lead.name.split(" ").first)
      .gsub("{NOME_COMPLETO_PACIENTE}", lead.name)
      .gsub("\n", "%0A")
      .gsub("\r\n", "%0A")
      if appointment.present?
        service = appointment.service
        result = result
        .gsub("{DIA_SEMANA_ATENDIMENTO}", helpers.format_day_of_week(service.date))
        .gsub("{MES_DO_ATENDIMENTO}", format_month(service.date))
        .gsub("{DIA_ATENDIMENTO_NUMERO}", service.date.strftime("%d"))
        .gsub("{HORARIO_DE_INICIO}", service.start_time.strftime("%H:%M"))
        .gsub("{HORARIO_DE_TERMINO}", service.end_time.strftime("%H:%M"))
        .gsub("{DATA_DO_ATENDIMENTO}", service.date.strftime("%d/%m/%Y"))
      end
      result
    end
  
    def set_message
      @message = LeadMessage.find(params[:id])
    end
  
    def message_params
      params.require(:lead_message).permit(:name, :text)
    end
  end
end
