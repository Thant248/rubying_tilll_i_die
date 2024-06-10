require 'uri'
require 'base64'
require 'digest'
require 'aws-sdk-s3'
require 'mime/types'

  class DirectMessageController < ApplicationController
    def index
      @t_direct_message = TDirectMessage.all

      render json: @t_direct_message
    end
    def show
      # Check if the receive user ID is provided
      if params[:s_user_id].nil?
        render json: { error: 'Receive user not exists!' }, status: :bad_request
        return
      end
  
      # Initialize file_url variable
      file_url = nil
  
      # Check if image parameter is present
      if params[:image].present?
        image_mime = params[:image][:mime]
        image_data = decode(params[:image][:file])
  
        # Ensure the mime type is valid
        if MIME::Types[image_mime].empty?
          render json: { error: 'Unsupported Content-Type' }, status: :unsupported_media_type
          return
        end
  
        file_extension = extension(image_mime)
        file_url = put_s3(image_data, file_extension, image_mime)
      end
  
      # Create a new direct message
      @t_direct_message = TDirectMessage.new(
        directmsg: params[:message],
        file: file_url,
        send_user_id: params[:user_id],
        receive_user_id: params[:s_user_id],
        read_status: 0
      )
  
      if @t_direct_message.save
        # Update remember_digest for the receiving user
        MUser.where(id: params[:s_user_id]).update_all(remember_digest: "1")
        render json: @t_direct_message, status: :created
      else
        render json: @t_direct_message.errors, status: :unprocessable_entity
      end
    end

        def showthread
          #check unlogin user
          # checkuser
          if params[:s_direct_message_id].nil?
            unless params[:s_user_id].nil?
              @user = MUser.find_by(id: params[:s_user_id])
              render json: @user
            end
          elsif params[:s_user_id].nil?
            render json: { error: 'Receive user not existed!'}
          else
            @t_direct_message = TDirectMessage.find_by(id: params[:s_direct_message_id])
            if @t_direct_message.nil?
              unless params[:s_user_id].nil?
                @user = MUser.find_by(id: params[:s_user_id])
                render json: @t_direct_message
              else
               
              end
            else
              @t_direct_thread = TDirectThread.new
              @t_direct_thread.directthreadmsg = params[:message]
              @t_direct_thread.t_direct_message_id = params[:s_direct_message_id]
              @t_direct_thread.m_user_id = params[:user_id]
              @t_direct_thread.read_status = 0
              @t_direct_thread.save
              MUser.where(id: params[:s_user_id]).update_all(remember_digest: "1")
              
            end
          end
        end
        def deletemsg
         
          
          directthreads = TDirectThread.where(t_direct_message_id: params[:id])
          directthreads.each do |directthread|
            TDirectStarThread.where(directthreadid: directthread.id).destroy_all
            directthread.destroy
          end
        
          TDirectStarMsg.where(directmsgid: params[:id]).destroy_all
          TDirectMessage.find_by(id: params[:id]).destroy
          render json: { success:'Successfully Delete Messages'}
        end
        
      
        def deletethread
          #check unlogin user
          # checkuser
      
          if params[:s_direct_message_id].nil?
            unless params[:s_user_id].nil?
              @user = MUser.find_by(id: params[:s_user_id])
              render json: { error:'Direct Message Not found'}
            end
          elsif params[:s_user_id].nil?
            render json: { error:'User not found'}
          else
            TDirectStarThread.where(directthreadid: params[:id]).destroy_all
            TDirectThread.find_by(id: params[:id]).destroy
      
            @t_direct_message = TDirectMessage.find_by(id: session[:s_direct_message_id])
            render json: { success:'Successfully Delete Messages'}
          end
        end

        def  showMessage 
          @second_user = params[:second_user] 

          retrieve_direct_message(@second_user)
        end


        private

  def decode(data)
    Base64.decode64(data)
  end

  def extension(mime_type)
    mime = MIME::Types[mime_type].first
    raise "Unsupported Content-Type" unless mime
    mime.extensions.first ? ".#{mime.extensions.first}" : raise("Unknown extension for MIME type")
  end

  def put_s3(data, extension, mime_type)
    file_name = Digest::SHA1.hexdigest(data) + extension
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket("rails-blog-minio")
    obj = bucket.object("files/#{file_name}")

    obj.put(
      acl: "public-read",
      body: data,
      content_type: mime_type,
      content_disposition: "inline"
    )

    obj.public_url
  end

  #       private

  # def decode(uri)
  #   opaque = uri.opaque
  #   data = opaque[opaque.index(",") + 1, opaque.size]
  #   Base64.decode64(data)
  # end

  # def extension(uri)
  #   opaque = uri.opaque
  #   mime_type = opaque[0, opaque.index(";")]
  #   case mime_type
  #   when "image/png"
  #     ".png"
  #   when "image/jpeg"
  #     ".jpg"
  #   when "application/msword"
  #     ".doc"
  #   when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  #     ".docx"
  #   when "application/vnd.ms-excel"
  #     ".xls"
  #   when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  #     ".xlsx"
  #   when "text/plain"
  #     ".txt"
  #   when "text/csv"
  #     ".csv"
  #   when "application/pdf"
  #      ".pdf"
  #   else
  #     raise "Unsupported Content-Type"
  #   end
  # end
  

  # def put_s3(data, extension)
  #   file_name = Digest::SHA1.hexdigest(data) + extension
  #   s3 = Aws::S3::Resource.new
  #   bucket = s3.bucket("rails-blog-minio")
  #   obj = bucket.object("avatars/#{file_name}")
    
  #   # Determine the content type based on the file extension
  #   content_type = case extension
  #   when "image/png"
  #     ".png"
  #   when "image/jpeg"
  #     ".jpg"
  #   when "application/msword"
  #     ".doc"
  #   when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  #     ".docx"
  #   when "application/vnd.ms-excel"
  #     ".xls"
  #   when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  #     ".xlsx"
  #   when "text/plain"
  #     ".txt"
  #   when "text/csv"
  #     ".csv"
  #   when "application/pdf"
  #      ".pdf"
  #   else
  #     raise "Unsupported Content-Type"
  #   end
  
  #   # Put the object with the correct content type and disposition
  #   obj.put(
  #     acl: "public-read",
  #     body: data,
  #     content_type: content_type,
  #     content_disposition: "inline"
  #   )
  
  #   obj.public_url
  # end
  end      



