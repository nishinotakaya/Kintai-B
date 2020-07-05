class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
  end

  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.attributes = item
        attendance.save!(context: :attendance_update)
      end
   end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  # 残業申請のモーダル！
  def edit_overwork_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @superior = User.where(superior: true).where.not(id: @user.id) #最初のwhereは自分、where.notを付け加えることによって自分以外の上長! 
  end
  
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id]) #attendanceを更新！
    params[:attendance][:overtime_status] = "申請中" #[:attendance]の[overtime_status]が申請中だった場合
    if  @attendance.update_attributes(overwork_params) #←ストロングパラメータの名前
      flash[:success] = "残業申請を更新しました"
      redirect_to user_url(@user) #処理で飛ばす先.com/rails/info/routesとホームページの方に書くとroute見れる　 
    else
      flash[:danger] = "残業申請を更新できませんでした。"
      redirect_to user_url(@user) #←user_urlの中に(@user)を入れることにより@userがuser_urlに飛ばされる！
    end
  end
  
  # 残業申請承認モーダル！
  def edit_superior_announcement 
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(overtime_status: "申請中", instructor_confirmation: @user.name)
    #@users = User.where(attendances:{overtime_status: "申請中"}).where.not(id: @user.id) #userひもづいてるattendanceモデルの中のovertime_statusの中の申請中のでーたを持ってるuserたちを持ってっ来る！
    @users = User.joins(:attendances).group("users.id").where(attendances:{overtime_status: "申請中"}) #joinsでattendancesのURLを持っているuserを集めてる！
  end
  
  def update_superior_announcement
    ActiveRecord::Base.transaction do
      @overtime_status = Attendance.where(overtime_status: "申請中").count
      @overtime_status1 = Attendance.where(overtime_status: "なし").count
      @overtime_status2 = Attendance.where(overtime_status: "承認").count
      @overtime_status3 = Attendance.where(overtime_status: "否認").count
      @user = User.find(params[:user_id])
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)  
        attendance.update_attributes!(item)
      end
    end  
    flash[:success] = "残業申請を#{@overtime_status}件、なしを#{@overtime_status1}件、承認を#{@overtime_status2}件、否認を#{@overtime_status3}件にしました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user)
  end
  
  
  def new_show #勤怠申請モーダルの確認ボタン
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @first_day = @attendance.worked_on.beginning_of_month #worked_on.日付、beginning_of_month月初日を計算してくれる。
    @last_day = @first_day.end_of_month #end_of_month月末日を計算してくれる。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on) #order日付順に並び変える,..は～から～まで
    @worked_sum = @attendances.where.not(started_at: nil).count
  end  
  
  
    
  
   private
   
    def overwork_params #ストロングパラメーター
       params.require(:attendance).permit(:plan_finished_at, :tomorrow, :business_processing_contents, :instructor_confirmation, :overtime_status) #この中のものを更新する！_edit_overwork_request.html.erbから更新」
    end
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:change, :overtime_status])[:attendances] #この中の物は複数ある時に更新する [:attendance]はviewファイルで指定したところ
    end
    #require(:user)は中の(attendances: [:started_at, :finished_at, :note])[:attendances]のこと
    #require(:user)ない場合はパラメーターの中のものを探すだから第一改装しか見ない！updateできない
    
    
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end