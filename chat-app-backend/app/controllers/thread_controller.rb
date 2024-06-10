class ThreadController < ApplicationController
        def show
            @t_direct_messages = TDirectMessage.select("distinct t_direct_messages.id,m_users.name,t_direct_messages.directmsg,t_direct_messages.created_at")
                                              .joins("INNER JOIN t_direct_threads ON t_direct_threads.t_direct_message_id = t_direct_messages.id
                                                      INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id")
                                              .where("t_direct_threads.m_user_id=?", @current_user).order(created_at: :asc)
            @t_direct_threads = TDirectThread.select("t_direct_threads.id as id,m_users.name,t_direct_threads.directthreadmsg,t_direct_threads.t_direct_message_id,t_direct_threads.created_at")
                                    .joins("join m_users on t_direct_threads.m_user_id=m_users.id
                                            join t_direct_messages on t_direct_threads.t_direct_message_id=t_direct_messages.id")
                                    .where("t_direct_messages.send_user_id=? or t_direct_messages.receive_user_id=?",
                                        @current_user,@current_user).order(id: :asc)
            @t_group_messages = TGroupMessage.select("distinct m_users.name, t_group_messages.groupmsg, t_group_messages.id as id,t_group_threads.t_group_message_id,
                                                      t_group_messages.created_at as created_at,m_channels.channel_name")
                                            .joins("INNER JOIN m_channels ON m_channels.id=t_group_messages.m_channel_id
                                                    INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id
                                                    INNER JOIN t_group_threads ON t_group_threads.t_group_message_id = t_group_messages.id")
                                            .where("t_group_threads.m_user_id= ?",@current_user).order(created_at: :asc)
            #Select group thread messages from mysql database
            @t_group_threads = TGroupThread.select("m_users.name, m_channels.channel_name, t_group_threads.groupthreadmsg, t_group_threads.id, t_group_threads.t_group_message_id, t_group_threads.created_at")
                               .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
                                       INNER JOIN m_users ON t_group_threads.m_user_id = m_users.id 
                                       INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id").where("t_group_threads.m_user_id= ?",@current_user)
                               .order(created_at: :asc)
            @temp_direct_star_msgids = TDirectStarMsg.select("directmsgid").where("userid = ?", @current_user)
            @t_direct_star_msgids = Array.new
            @temp_direct_star_msgids.each { |r| @t_direct_star_msgids.push(r.directmsgid) }
            @temp_direct_star_thread_msgids = TDirectStarThread.select("directthreadid").where("userid = ?", @current_user)
            @t_direct_star_thread_msgids = Array.new
            @temp_direct_star_thread_msgids.each { |r| @t_direct_star_thread_msgids.push(r.directthreadid) }
            @temp_group_star_msgids = TGroupStarMsg.select("groupmsgid").where("userid = ?", @current_user)
            @t_group_star_msgids = Array.new
            @temp_group_star_msgids.each { |r| @t_group_star_msgids.push(r.groupmsgid) }
            @temp_group_star_thread_msgids = TGroupStarThread.select("groupthreadid").where("userid = ?", @current_user)
            @t_group_star_thread_msgids = Array.new
            @temp_group_star_thread_msgids.each { |r| @t_group_star_thread_msgids.push(r.groupthreadid) }
          #call from ApplicationController for retrieve home data
        #   retrievehome
        
        end
    end